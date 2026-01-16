import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:image_picker/image_picker.dart';
import '../core/services/auth_service.dart';
import 'file_service.dart';
import 'file_model.dart';

class FileController extends ChangeNotifier {
  final FileService _fileService = FileService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  List<SharedFile> _files = [];
  FileType? _filterType;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  Map<String, dynamic> _fileStats = {};

  List<SharedFile> get files => _files;
  FileType? get filterType => _filterType;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get fileStats => _fileStats;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }

  void _setUploadProgress(double progress) {
    _uploadProgress = progress;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Initialize files for a circle
  void initializeFiles(String circleId) {
    _fileService.getCircleFiles(circleId, filterType: _filterType).listen(
      (files) {
        _files = files;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load files: $error');
      },
    );

    // Load file statistics
    _loadFileStats(circleId);
  }

  // Load file statistics
  Future<void> _loadFileStats(String circleId) async {
    try {
      _fileStats = await _fileService.getFileStats(circleId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load file stats: $e');
    }
  }

  // Pick and upload image from camera
  Future<bool> uploadImageFromCamera(String circleId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        return await _uploadFile(circleId, File(image.path));
      }
      return false;
    } catch (e) {
      _setError('Failed to capture image: $e');
      return false;
    }
  }

  // Pick and upload image from gallery
  Future<bool> uploadImageFromGallery(String circleId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        return await _uploadFile(circleId, File(image.path));
      }
      return false;
    } catch (e) {
      _setError('Failed to pick image: $e');
      return false;
    }
  }

  // Pick and upload multiple images
  Future<bool> uploadMultipleImages(String circleId) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        bool allSuccess = true;
        for (final image in images) {
          final success = await _uploadFile(circleId, File(image.path));
          if (!success) allSuccess = false;
        }
        return allSuccess;
      }
      return false;
    } catch (e) {
      _setError('Failed to pick images: $e');
      return false;
    }
  }

  // Pick and upload file
  Future<bool> uploadFile(String circleId) async {
    try {
      final fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return await _uploadFile(circleId, File(result.files.single.path!));
      }
      return false;
    } catch (e) {
      _setError('Failed to pick file: $e');
      return false;
    }
  }

  // Pick and upload multiple files
  Future<bool> uploadMultipleFiles(String circleId) async {
    try {
      final fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.any,
        allowMultiple: true,
      );

      if (result != null) {
        bool allSuccess = true;
        for (final file in result.files) {
          if (file.path != null) {
            final success = await _uploadFile(circleId, File(file.path!));
            if (!success) allSuccess = false;
          }
        }
        return allSuccess;
      }
      return false;
    } catch (e) {
      _setError('Failed to pick files: $e');
      return false;
    }
  }

  // Internal upload method
  Future<bool> _uploadFile(String circleId, File file) async {
    _setUploading(true);
    _setUploadProgress(0.0);
    _setError(null);

    try {
      await _fileService.uploadFile(
        circleId: circleId,
        file: file,
        onProgress: (progress) {
          _setUploadProgress(progress);
        },
      );
      
      _setUploading(false);
      _setUploadProgress(0.0);
      return true;
    } catch (e) {
      _setError('Failed to upload file: $e');
      _setUploading(false);
      _setUploadProgress(0.0);
      return false;
    }
  }

  // Update file metadata
  Future<bool> updateFile({
    required String circleId,
    required String fileId,
    String? name,
    String? description,
    List<String>? tags,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _fileService.updateFile(
        circleId: circleId,
        fileId: fileId,
        name: name,
        description: description,
        tags: tags,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update file: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete a file
  Future<bool> deleteFile(String circleId, String fileId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;

    try {
      await _fileService.deleteFile(circleId, fileId, user.uid);
      return true;
    } catch (e) {
      _setError('Failed to delete file: $e');
      return false;
    }
  }

  // Set filter type
  void setFilterType(FileType? type, String circleId) {
    if (_filterType != type) {
      _filterType = type;
      initializeFiles(circleId); // Reload with new filter
    }
  }

  // Get filtered files
  List<SharedFile> getFilteredFiles() {
    if (_filterType == null) return _files;
    return _files.where((file) => file.type == _filterType).toList();
  }

  // Get download URL
  String getDownloadUrl(SharedFile file) {
    return _fileService.getDownloadUrl(file);
  }

  void clearError() {
    _setError(null);
  }
}