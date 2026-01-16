import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../core/services/auth_service.dart';
import '../notifications/notification_service.dart';
import '../circles/circle_service.dart';
import 'file_model.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  static FileService get instance => _instance;
  FileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Upload a file
  Future<SharedFile> uploadFile({
    required String circleId,
    required File file,
    String? description,
    List<String> tags = const [],
    Function(double)? onProgress,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get user data for uploader info
    final userDoc = await AuthService.instance.getUserDocument(user.uid);
    final userData = userDoc.data() as Map<String, dynamic>?;

    final fileName = path.basename(file.path);
    final fileExtension = path.extension(fileName).replaceFirst('.', '');
    final fileId = _uuid.v4();
    final storagePath = 'circles/$circleId/files/$fileId.$fileExtension';

    // Create storage reference
    final storageRef = _storage.ref().child(storagePath);

    // Upload file with progress tracking
    final uploadTask = storageRef.putFile(file);

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // Get file stats
    final fileStats = await file.stat();
    final fileType = SharedFile.getFileTypeFromExtension(fileExtension);

    // Create file document
    final sharedFile = SharedFile(
      id: fileId,
      circleId: circleId,
      name: fileName,
      originalName: fileName,
      downloadUrl: downloadUrl,
      storagePath: storagePath,
      type: fileType,
      size: fileStats.size,
      uploadedBy: user.uid,
      uploadedByName: userData?['displayName'] ?? 'Unknown',
      uploadedByPhotoUrl: userData?['photoURL'],
      uploadedAt: DateTime.now(),
      description: description,
      tags: tags,
    );

    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('files')
        .doc(fileId)
        .set(sharedFile.toFirestore());

    // Send notification to other circle members
    try {
      final circle = await CircleService.instance.getCircleById(circleId);
      if (circle != null) {
        await NotificationService.instance.notifyFileUploaded(
          circleId: circleId,
          circleName: circle.name,
          memberIds: circle.members,
          uploaderName: userData?['displayName'] ?? 'Unknown',
          fileName: fileName,
          fileId: fileId,
        );
      }
    } catch (e) {
      debugPrint('Failed to send file upload notification: $e');
    }

    return sharedFile;
  }

  // Get files for a circle (real-time stream)
  Stream<List<SharedFile>> getCircleFiles(
    String circleId, {
    FileType? filterType,
  }) {
    Query query = _firestore
        .collection('circles')
        .doc(circleId)
        .collection('files')
        .orderBy('uploadedAt', descending: true);

    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType.name);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => SharedFile.fromFirestore(doc)).toList(),
    );
  }

  // Get single file
  Future<SharedFile?> getFile(String circleId, String fileId) async {
    final doc =
        await _firestore
            .collection('circles')
            .doc(circleId)
            .collection('files')
            .doc(fileId)
            .get();

    if (!doc.exists) return null;
    return SharedFile.fromFirestore(doc);
  }

  // Update file metadata
  Future<SharedFile> updateFile({
    required String circleId,
    required String fileId,
    String? name,
    String? description,
    List<String>? tags,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (tags != null) updates['tags'] = tags;

    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('files')
        .doc(fileId)
        .update(updates);

    final updatedFile = await getFile(circleId, fileId);
    if (updatedFile == null) throw Exception('File not found after update');

    return updatedFile;
  }

  // Delete file
  Future<void> deleteFile(String circleId, String fileId, String userId) async {
    final file = await getFile(circleId, fileId);
    if (file == null) return;

    // Only uploader can delete file
    if (file.uploadedBy != userId) {
      throw Exception('Only the file uploader can delete this file');
    }

    // Delete from storage
    try {
      await _storage.ref().child(file.storagePath).delete();
    } catch (e) {
      // File might not exist in storage, continue with Firestore deletion
      debugPrint('Failed to delete file from storage: $e');
    }

    // Delete from Firestore
    await _firestore
        .collection('circles')
        .doc(circleId)
        .collection('files')
        .doc(fileId)
        .delete();
  }

  // Get file statistics for a circle
  Future<Map<String, dynamic>> getFileStats(String circleId) async {
    final snapshot =
        await _firestore
            .collection('circles')
            .doc(circleId)
            .collection('files')
            .get();

    final files =
        snapshot.docs.map((doc) => SharedFile.fromFirestore(doc)).toList();

    int totalSize = 0;
    Map<FileType, int> typeCount = {};

    for (final file in files) {
      totalSize += file.size;
      typeCount[file.type] = (typeCount[file.type] ?? 0) + 1;
    }

    return {
      'totalFiles': files.length,
      'totalSize': totalSize,
      'images': typeCount[FileType.image] ?? 0,
      'videos': typeCount[FileType.video] ?? 0,
      'documents': typeCount[FileType.document] ?? 0,
      'audio': typeCount[FileType.audio] ?? 0,
      'other': typeCount[FileType.other] ?? 0,
    };
  }

  // Search files
  Stream<List<SharedFile>> searchFiles(String circleId, String query) {
    return _firestore
        .collection('circles')
        .doc(circleId)
        .collection('files')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => SharedFile.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get files by type
  Stream<List<SharedFile>> getFilesByType(String circleId, FileType type) {
    return _firestore
        .collection('circles')
        .doc(circleId)
        .collection('files')
        .where('type', isEqualTo: type.name)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => SharedFile.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get recent files
  Stream<List<SharedFile>> getRecentFiles(String circleId, {int limit = 10}) {
    return _firestore
        .collection('circles')
        .doc(circleId)
        .collection('files')
        .orderBy('uploadedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => SharedFile.fromFirestore(doc))
                  .toList(),
        );
  }

  // Download file (returns the download URL for external handling)
  String getDownloadUrl(SharedFile file) {
    return file.downloadUrl;
  }
}
