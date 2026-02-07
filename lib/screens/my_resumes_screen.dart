import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../providers/resume_provider.dart';
import '../providers/auth_provider.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import 'resume_builder_screen.dart';
import 'resume_preview_screen.dart';

import 'uploaded_resume_preview_screen.dart';

class MyResumesScreen extends StatefulWidget {
  const MyResumesScreen({super.key});

  @override
  State<MyResumesScreen> createState() => _MyResumesScreenState();
}

class _MyResumesScreenState extends State<MyResumesScreen> {
  List<Map<String, dynamic>> _uploadedResumes = [];
  bool _isLoadingUploaded = true;

  @override
  void initState() {
    super.initState();
    _loadUploadedResumes();
  }

  Future<void> _loadUploadedResumes() async {
    final userId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.id;
    if (userId != null) {
      final resumes = await StorageService().getUserResumesFromRTDB(userId);
      if (mounted) {
        setState(() {
          _uploadedResumes = resumes;
          _isLoadingUploaded = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingUploaded = false);
    }
  }

  Future<void> _downloadUploadedResume(String rtdbPath, String fileName) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Downloading resume...')));

      final result = await StorageService().downloadResumeFromRTDB(rtdbPath);

      if (result == null) {
        throw Exception('Download failed');
      }

      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web download for RTDB not implemented'),
          ),
        );
        return;
      }

      final bytes = result['bytes'] as Uint8List;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumeProvider = Provider.of<ResumeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.id ?? '';
    final createdResumes = resumeProvider.getResumesByUser(userId);

    final bool isEmpty =
        createdResumes.isEmpty &&
        _uploadedResumes.isEmpty &&
        !_isLoadingUploaded;

    return Scaffold(
      appBar: AppBar(title: const Text('My Resumes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ResumeBuilderScreen(),
            ),
          );
        },
        tooltip: 'Create New Resume',
        child: const Icon(Icons.add),
      ),
      body: isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No resumes yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first resume by tapping the + button!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (createdResumes.isNotEmpty) ...[
                    Text(
                      'Created Resumes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...createdResumes.map(
                      (resume) =>
                          _buildCreatedResumeCard(resume, resumeProvider),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_uploadedResumes.isNotEmpty || _isLoadingUploaded) ...[
                    Text(
                      'Uploaded Resumes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingUploaded)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      ..._uploadedResumes.map(
                        (resume) => _buildUploadedResumeCard(resume),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCreatedResumeCard(resume, resumeProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.description, color: Colors.white),
        ),
        title: Text(
          resume.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Template: ${resume.templateId}'),
            Text(
              'Created: ${_formatDate(resume.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.preview, size: 20),
                  SizedBox(width: 8),
                  Text('Preview'),
                ],
              ),
              onTap: () {
                Future.delayed(const Duration(milliseconds: 100), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResumePreviewScreen(resume: resume),
                    ),
                  );
                });
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.picture_as_pdf, size: 20),
                  SizedBox(width: 8),
                  Text('Download PDF'),
                ],
              ),
              onTap: () {
                Future.delayed(const Duration(milliseconds: 100), () async {
                  final pdfService = PDFService();
                  final fileName = '${resume.name}.pdf';
                  await pdfService.downloadResumePDF(
                    resume,
                    fileName,
                    templateId: resume.templateId,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF download started!')),
                    );
                  }
                });
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () {
                Future.delayed(const Duration(milliseconds: 100), () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Resume'),
                      content: Text(
                        'Are you sure you want to delete "${resume.name}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            resumeProvider.deleteResume(resume.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Resume deleted')),
                            );
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                });
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResumePreviewScreen(resume: resume),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadedResumeCard(Map<String, dynamic> resume) {
    final fileName = resume['fileName'] ?? 'Unknown Resume';
    final uploadedAt = DateTime.tryParse(resume['uploadedAt'] ?? '');
    final dateStr = uploadedAt != null
        ? _formatDate(uploadedAt)
        : 'Unknown date';
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
    final rtdbPath = 'rtdb://resumes/$userId/${resume['id']}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: const Icon(Icons.attach_file, color: Colors.white),
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Uploaded: $dateStr'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: 'Preview',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UploadedResumePreviewScreen(
                      rtdbPath: rtdbPath,
                      fileName: fileName,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download',
              onPressed: () => _downloadUploadedResume(rtdbPath, fileName),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UploadedResumePreviewScreen(
                rtdbPath: rtdbPath,
                fileName: fileName,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
