import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../models/job_model.dart';
import '../../models/application_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isApplying = false;
  final _storageService = StorageService();

  PlatformFile? _pickedFile;

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.single;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking resume: $e')));
    }
  }

  Future<void> _applyForJob() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a resume first')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final applicationProvider = Provider.of<ApplicationProvider>(
      context,
      listen: false,
    );

    setState(() => _isApplying = true);

    try {
      final file = _pickedFile!;
      String? resumeUrl;
      String resumeText = file.name;

      // Upload file to Firebase Storage
      final userId = authProvider.currentUser?.id ?? 'unknown';
      final fileName =
          'resume_${DateTime.now().millisecondsSinceEpoch}.${file.extension ?? 'pdf'}';

      if (kIsWeb) {
        // For web, upload from bytes
        if (file.bytes != null) {
          resumeUrl = await _storageService.uploadResumeFromBytes(
            userId: userId,
            bytes: file.bytes!,
            fileName: fileName,
          );
        }
      } else {
        // For mobile/desktop, upload from file path
        if (file.path != null) {
          resumeUrl = await _storageService.uploadResumeFromPath(
            userId: userId,
            filePath: file.path!,
            fileName: fileName,
          );
        }
      }

      final application = Application(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        jobId: widget.job.id,
        candidateId: authProvider.currentUser?.id ?? '',
        candidateName: authProvider.currentUser?.name ?? 'Candidate',
        candidateEmail: authProvider.currentUser?.email ?? '',
        resumePath: resumeUrl ?? file.path ?? '',
        resumeText: resumeText,
        status: ApplicationStatus.applied,
      );

      await applicationProvider.createApplication(application);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error applying: $e')));
    }

    setState(() => _isApplying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.job.title,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.job.domain} • ${widget.job.location}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (widget.job.salaryRange != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.job.salaryRange!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Description',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(widget.job.description),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requirements',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text('Experience: ${widget.job.experienceLevel} years'),
                    const SizedBox(height: 12),
                    Text(
                      'Required Skills:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.job.requiredSkills.map((skill) {
                        return Chip(label: Text(skill));
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text('Posted by: ${widget.job.hrName}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_pickedFile == null)
                OutlinedButton.icon(
                  onPressed: _pickResume,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Resume (PDF/DOC)'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                )
              else
                Card(
                  color: Colors.green.withOpacity(0.1),
                  child: ListTile(
                    leading: const Icon(Icons.description, color: Colors.green),
                    title: Text(
                      _pickedFile!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _pickedFile = null;
                        });
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isApplying || _pickedFile == null
                    ? null
                    : _applyForJob,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isApplying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
