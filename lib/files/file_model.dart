import 'package:cloud_firestore/cloud_firestore.dart';

enum FileType {
  image,
  video,
  document,
  audio,
  other,
}

class SharedFile {
  final String id;
  final String circleId;
  final String name;
  final String originalName;
  final String downloadUrl;
  final String storagePath;
  final FileType type;
  final int size; // in bytes
  final String uploadedBy;
  final String uploadedByName;
  final String? uploadedByPhotoUrl;
  final DateTime uploadedAt;
  final String? description;
  final List<String> tags;

  SharedFile({
    required this.id,
    required this.circleId,
    required this.name,
    required this.originalName,
    required this.downloadUrl,
    required this.storagePath,
    required this.type,
    required this.size,
    required this.uploadedBy,
    required this.uploadedByName,
    this.uploadedByPhotoUrl,
    required this.uploadedAt,
    this.description,
    this.tags = const [],
  });

  factory SharedFile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharedFile(
      id: doc.id,
      circleId: data['circleId'] ?? '',
      name: data['name'] ?? '',
      originalName: data['originalName'] ?? '',
      downloadUrl: data['downloadUrl'] ?? '',
      storagePath: data['storagePath'] ?? '',
      type: FileType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => FileType.other,
      ),
      size: data['size'] ?? 0,
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedByName: data['uploadedByName'] ?? 'Unknown',
      uploadedByPhotoUrl: data['uploadedByPhotoUrl'],
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'circleId': circleId,
      'name': name,
      'originalName': originalName,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'type': type.name,
      'size': size,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'uploadedByPhotoUrl': uploadedByPhotoUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'description': description,
      'tags': tags,
    };
  }

  SharedFile copyWith({
    String? id,
    String? circleId,
    String? name,
    String? originalName,
    String? downloadUrl,
    String? storagePath,
    FileType? type,
    int? size,
    String? uploadedBy,
    String? uploadedByName,
    String? uploadedByPhotoUrl,
    DateTime? uploadedAt,
    String? description,
    List<String>? tags,
  }) {
    return SharedFile(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      name: name ?? this.name,
      originalName: originalName ?? this.originalName,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      storagePath: storagePath ?? this.storagePath,
      type: type ?? this.type,
      size: size ?? this.size,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      uploadedByPhotoUrl: uploadedByPhotoUrl ?? this.uploadedByPhotoUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      description: description ?? this.description,
      tags: tags ?? this.tags,
    );
  }

  String get formattedSize {
    if (size < 1024) {
      return '${size}B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)}KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  String get fileExtension {
    final parts = originalName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  bool get isImage => type == FileType.image;
  bool get isVideo => type == FileType.video;
  bool get isDocument => type == FileType.document;
  bool get isAudio => type == FileType.audio;

  static FileType getFileTypeFromExtension(String extension) {
    final ext = extension.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      return FileType.image;
    } else if (['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'].contains(ext)) {
      return FileType.video;
    } else if (['pdf', 'doc', 'docx', 'txt', 'rtf', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext)) {
      return FileType.document;
    } else if (['mp3', 'wav', 'aac', 'flac', 'ogg'].contains(ext)) {
      return FileType.audio;
    } else {
      return FileType.other;
    }
  }
}