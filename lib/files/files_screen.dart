import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../circles/circle_controller.dart';
import 'file_controller.dart';
import 'file_model.dart';
import 'file_detail_screen.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final circleController = context.read<CircleController>();
      final fileController = context.read<FileController>();

      if (circleController.selectedCircle != null) {
        fileController.initializeFiles(circleController.selectedCircle!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CircleController, FileController>(
      builder: (context, circleController, fileController, child) {
        final selectedCircle = circleController.selectedCircle;

        if (selectedCircle == null) {
          return const Center(child: Text('No circle selected'));
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              // File stats
              if (fileController.fileStats.isNotEmpty)
                _buildFileStats(fileController.fileStats),

              // Upload progress
              if (fileController.isUploading)
                _buildUploadProgress(fileController.uploadProgress),

              // Error message
              if (fileController.errorMessage != null)
                _buildErrorMessage(fileController.errorMessage!),

              // Tab bar
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Images'),
                  Tab(text: 'Videos'),
                  Tab(text: 'Documents'),
                  Tab(text: 'Audio'),
                  Tab(text: 'Other'),
                ],
                onTap: (index) {
                  FileType? filterType;
                  switch (index) {
                    case 1:
                      filterType = FileType.image;
                      break;
                    case 2:
                      filterType = FileType.video;
                      break;
                    case 3:
                      filterType = FileType.document;
                      break;
                    case 4:
                      filterType = FileType.audio;
                      break;
                    case 5:
                      filterType = FileType.other;
                      break;
                  }
                  fileController.setFilterType(filterType, selectedCircle.id);
                },
              ),

              // File grid
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFileGrid(fileController.files),
                    _buildFileGrid(
                      fileController.files
                          .where((f) => f.type == FileType.image)
                          .toList(),
                    ),
                    _buildFileGrid(
                      fileController.files
                          .where((f) => f.type == FileType.video)
                          .toList(),
                    ),
                    _buildFileGrid(
                      fileController.files
                          .where((f) => f.type == FileType.document)
                          .toList(),
                    ),
                    _buildFileGrid(
                      fileController.files
                          .where((f) => f.type == FileType.audio)
                          .toList(),
                    ),
                    _buildFileGrid(
                      fileController.files
                          .where((f) => f.type == FileType.other)
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => _showUploadOptions(context, selectedCircle.id),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileStats(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              stats['totalFiles'] ?? 0,
              Colors.blue,
              Icons.folder_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Images',
              stats['images'] ?? 0,
              Colors.green,
              Icons.image_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Docs',
              stats['documents'] ?? 0,
              Colors.orange,
              Icons.description_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Size',
              _formatFileSize(stats['totalSize'] ?? 0),
              Colors.purple,
              Icons.storage_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    dynamic value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildUploadProgress(double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload, size: 20),
              const SizedBox(width: 8),
              Text('Uploading... ${(progress * 100).toInt()}%'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload Failed',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(error, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<FileController>().clearError();
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileGrid(List<SharedFile> files) {
    if (files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No files yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload your first file to get started!',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return FileCard(
          file: file,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => FileDetailScreen(
                      file: file,
                      circleId:
                          context.read<CircleController>().selectedCircle!.id,
                    ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUploadOptions(BuildContext context, String circleId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Upload Files',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.blue),
                  ),
                  title: const Text('Take Photo'),
                  subtitle: const Text('Capture with camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await context
                        .read<FileController>()
                        .uploadImageFromCamera(circleId);
                    if (context.mounted) {
                      _showUploadResult(context, success, 'Photo');
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.green),
                  ),
                  title: const Text('Choose Photos'),
                  subtitle: const Text('Select from gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await context
                        .read<FileController>()
                        .uploadMultipleImages(circleId);
                    if (context.mounted) {
                      _showUploadResult(context, success, 'Photos');
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.attach_file, color: Colors.orange),
                  ),
                  title: const Text('Upload Document'),
                  subtitle: const Text('PDF, Word, Excel, etc.'),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await context
                        .read<FileController>()
                        .uploadFile(circleId);
                    if (context.mounted) {
                      _showUploadResult(context, success, 'Document');
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder, color: Colors.purple),
                  ),
                  title: const Text('Multiple Files'),
                  subtitle: const Text('Select multiple files'),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await context
                        .read<FileController>()
                        .uploadMultipleFiles(circleId);
                    if (context.mounted) {
                      _showUploadResult(context, success, 'Files');
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _showUploadResult(BuildContext context, bool success, String fileType) {
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$fileType uploaded successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Error is already shown in the UI via the error message widget
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to upload $fileType. Check the error message above.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }
}

class FileCard extends StatelessWidget {
  final SharedFile file;
  final VoidCallback onTap;

  const FileCard({super.key, required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File preview
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: Colors.grey[100],
                child:
                    file.isImage
                        ? Image.network(
                          file.downloadUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFileIcon();
                          },
                        )
                        : _buildFileIcon(),
              ),
            ),

            // File info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      file.formattedSize,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file.uploadedByName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    IconData icon;
    Color color;

    switch (file.type) {
      case FileType.image:
        icon = Icons.image;
        color = Colors.green;
        break;
      case FileType.video:
        icon = Icons.video_file;
        color = Colors.red;
        break;
      case FileType.document:
        icon = Icons.description;
        color = Colors.blue;
        break;
      case FileType.audio:
        icon = Icons.audio_file;
        color = Colors.purple;
        break;
      case FileType.other:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
        break;
    }

    return Center(child: Icon(icon, size: 48, color: color));
  }
}
