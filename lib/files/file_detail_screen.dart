import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/auth_service.dart';
import 'file_controller.dart';
import 'file_model.dart';

class FileDetailScreen extends StatelessWidget {
  final SharedFile file;
  final String circleId;

  const FileDetailScreen({
    super.key,
    required this.file,
    required this.circleId,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final isUploader = currentUser?.uid == file.uploadedBy;

    return Scaffold(
      appBar: AppBar(
        title: Text(file.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadFile(context),
          ),
          if (isUploader)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rename') {
                  _showRenameDialog(context);
                } else if (value == 'delete') {
                  _confirmDeleteFile(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Text('Rename'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File preview
            _buildFilePreview(context),
            const SizedBox(height: 24),

            // File details
            _buildFileDetails(context),
            const SizedBox(height: 24),

            // Actions
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: file.isImage
            ? Image.network(
                file.downloadUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFileIcon();
                },
              )
            : _buildFileIcon(),
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            file.fileExtension.toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileDetails(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildDetailRow('Name', file.name),
            _buildDetailRow('Size', file.formattedSize),
            _buildDetailRow('Type', file.type.name.toUpperCase()),
            _buildDetailRow('Uploaded by', file.uploadedByName),
            _buildDetailRow('Uploaded on', _formatDateTime(file.uploadedAt)),
            
            if (file.description != null && file.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(file.description!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _downloadFile(context),
          icon: const Icon(Icons.download),
          label: const Text('Download'),
        ),
        const SizedBox(height: 8),
        if (file.isImage || file.isVideo)
          OutlinedButton.icon(
            onPressed: () => _openInBrowser(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in Browser'),
          ),
      ],
    );
  }

  Future<void> _downloadFile(BuildContext context) async {
    try {
      final url = Uri.parse(file.downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download file')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading file: $e')),
        );
      }
    }
  }

  Future<void> _openInBrowser(BuildContext context) async {
    try {
      final url = Uri.parse(file.downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.inAppWebView);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: file.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final fileController = context.read<FileController>();
              final success = await fileController.updateFile(
                circleId: circleId,
                fileId: file.id,
                name: controller.text.trim(),
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File renamed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final fileController = context.read<FileController>();
              final success = await fileController.deleteFile(circleId, file.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File deleted'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}