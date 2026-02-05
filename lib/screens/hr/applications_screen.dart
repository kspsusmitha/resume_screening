import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'application_detail_screen.dart';

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final applicationProvider = Provider.of<ApplicationProvider>(context);
    final jobProvider = Provider.of<JobProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final hrJobs = jobProvider.getJobsByHr(authProvider.currentUser?.id ?? '');
    final applications = applicationProvider.applications
        .where((a) => hrJobs.any((j) => j.id == a.jobId))
        .toList();

    return Scaffold(
      // Removed AppBar as this screen is embedded in AdminDashboardScreen's IndexedStack
      body: applications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No applications yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final application = applications[index];
                final job = jobProvider.getJobById(application.jobId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(application.candidateName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(application.candidateEmail),
                        if (job != null) Text('Applied for: ${job.title}'),
                        if (application.matchPercentage != null)
                          Text(
                            'Match: ${application.matchPercentage!.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: application.matchPercentage! >= 70
                                  ? AppTheme.accentColor
                                  : AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StatusChip(status: application.status),
                        if (application.category != null) ...[
                          const SizedBox(height: 4),
                          _CategoryChip(category: application.category!),
                        ],
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ApplicationDetailScreen(application: application),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ApplicationStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ApplicationStatus.applied:
        color = Colors.blue;
        break;
      case ApplicationStatus.shortlisted:
        color = AppTheme.accentColor;
        break;
      case ApplicationStatus.interviewScheduled:
        color = AppTheme.primaryColor;
        break;
      case ApplicationStatus.rejected:
        color = AppTheme.errorColor;
        break;
      case ApplicationStatus.accepted:
        color = AppTheme.accentColor;
        break;
    }

    return Chip(
      label: Text(
        status.toString().split('.').last.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CandidateCategory category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        category.toString().split('.').last,
        style: const TextStyle(fontSize: 10),
      ),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
