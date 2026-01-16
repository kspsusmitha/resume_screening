import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/job_provider.dart';
import '../../models/application_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class ApplicationDetailScreen extends StatelessWidget {
  final Application application;

  const ApplicationDetailScreen({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final applicationProvider = Provider.of<ApplicationProvider>(context);
    final jobProvider = Provider.of<JobProvider>(context);
    final job = jobProvider.getJobById(application.jobId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.candidateName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(application.candidateEmail),
                    if (job != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Applied for:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(job.title),
                      Text('${job.domain} • ${job.location}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (application.matchPercentage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match Score',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: application.matchPercentage! / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          application.matchPercentage! >= 70
                              ? AppTheme.accentColor
                              : AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${application.matchPercentage!.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
            if (application.missingSkills != null &&
                application.missingSkills!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Missing Skills',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: application.missingSkills!.map((skill) {
                          return Chip(
                            label: Text(skill),
                            backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ApplicationStatus.values.map((status) {
                        final isSelected = application.status == status;
                        return FilterChip(
                          label: Text(status.toString().split('.').last),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              applicationProvider.updateApplicationStatus(
                                application.id,
                                status,
                              );
                            }
                          },
                        );
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CandidateCategory.values.map((category) {
                        final isSelected = application.category == category;
                        return FilterChip(
                          label: Text(category.toString().split('.').last),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              applicationProvider.updateApplicationCategory(
                                application.id,
                                category,
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            if (application.resumeText != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(application.resumeText!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

