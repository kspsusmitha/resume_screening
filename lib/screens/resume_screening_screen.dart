import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/job_provider.dart';
import '../services/ai_service.dart';
import '../models/resume_screening_result.dart';
import '../models/job_model.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_indicator.dart';

class ResumeScreeningScreen extends StatefulWidget {
  const ResumeScreeningScreen({super.key});

  @override
  State<ResumeScreeningScreen> createState() => _ResumeScreeningScreenState();
}

class _ResumeScreeningScreenState extends State<ResumeScreeningScreen> {
  final _aiService = AIService();
  Job? _selectedJob;
  String? _resumeText;
  ResumeScreeningResult? _result;
  bool _isLoading = false;

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _resumeText = result.files.single.name; // In real app, read file content
      });
    }
  }

  Future<void> _screenResume() async {
    if (_selectedJob == null || _resumeText == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job and upload resume')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final result = await _aiService.screenResume(
        resumeText: _resumeText!,
        jobDescription: _selectedJob!.description,
        requiredSkills: _selectedJob!.requiredSkills,
      );

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);
    final jobs = jobProvider.activeJobs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Resume Screening'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Job',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Job>(
                      value: _selectedJob,
                      decoration: const InputDecoration(
                        hintText: 'Choose a job posting',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      items: jobs.map((job) {
                        return DropdownMenuItem(
                          value: job,
                          child: Text(job.title),
                        );
                      }).toList(),
                      onChanged: (job) {
                        setState(() {
                          _selectedJob = job;
                          _result = null;
                        });
                      },
                    ),
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
                      'Upload Resume',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickResume,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_resumeText ?? 'Select Resume File'),
                    ),
                    if (_resumeText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'File: $_resumeText',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading || _selectedJob == null || _resumeText == null
                  ? null
                  : _screenResume,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Screen Resume'),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const LoadingIndicator(message: 'Analyzing resume...'),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Screening Results',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Match Percentage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _result!.matchPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _result!.matchPercentage >= 70
                    ? AppTheme.accentColor
                    : _result!.matchPercentage >= 50
                        ? AppTheme.warningColor
                        : AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_result!.matchPercentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: _result!.matchPercentage >= 70
                        ? AppTheme.accentColor
                        : _result!.matchPercentage >= 50
                            ? AppTheme.warningColor
                            : AppTheme.errorColor,
                  ),
            ),
            const SizedBox(height: 24),
            if (_result!.matchedSkills.isNotEmpty) ...[
              Text(
                'Matched Skills',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _result!.matchedSkills.map((skill) {
                  return Chip(
                    label: Text(skill),
                    backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            if (_result!.missingSkills.isNotEmpty) ...[
              Text(
                'Missing Skills',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _result!.missingSkills.map((skill) {
                  return Chip(
                    label: Text(skill),
                    backgroundColor: AppTheme.errorColor.withOpacity(0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Analysis',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(_result!.analysis),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _result!.recommendation == 'SHORTLIST'
                    ? AppTheme.accentColor.withOpacity(0.1)
                    : _result!.recommendation == 'REJECT'
                        ? AppTheme.errorColor.withOpacity(0.1)
                        : AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _result!.recommendation == 'SHORTLIST'
                        ? Icons.check_circle
                        : _result!.recommendation == 'REJECT'
                            ? Icons.cancel
                            : Icons.info,
                    color: _result!.recommendation == 'SHORTLIST'
                        ? AppTheme.accentColor
                        : _result!.recommendation == 'REJECT'
                            ? AppTheme.errorColor
                            : AppTheme.warningColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Recommendation: ${_result!.recommendation}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _result!.recommendation == 'SHORTLIST'
                                ? AppTheme.accentColor
                                : _result!.recommendation == 'REJECT'
                                    ? AppTheme.errorColor
                                    : AppTheme.warningColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

