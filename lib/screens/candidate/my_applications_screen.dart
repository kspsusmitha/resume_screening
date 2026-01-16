import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final applicationProvider = Provider.of<ApplicationProvider>(context);
    final jobProvider = Provider.of<JobProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final myApplications = applicationProvider
        .getApplicationsByCandidate(authProvider.currentUser?.id ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
      ),
      body: myApplications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No applications yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start applying to jobs!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myApplications.length,
              itemBuilder: (context, index) {
                final application = myApplications[index];
                final job = jobProvider.getJobById(application.jobId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(job?.title ?? 'Unknown Job'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${application.status.toString().split('.').last}'),
                        if (application.matchPercentage != null)
                          Text(
                            'Match: ${application.matchPercentage!.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: application.matchPercentage! >= 70
                                  ? AppTheme.accentColor
                                  : AppTheme.warningColor,
                            ),
                          ),
                      ],
                    ),
                    trailing: _StatusIcon(application.status),
                  ),
                );
              },
            ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final ApplicationStatus status;

  const _StatusIcon(this.status);

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.info;
    Color color = Colors.grey;

    switch (status) {
      case ApplicationStatus.applied:
        icon = Icons.pending;
        color = Colors.blue;
        break;
      case ApplicationStatus.shortlisted:
        icon = Icons.check_circle;
        color = AppTheme.accentColor;
        break;
      case ApplicationStatus.interviewScheduled:
        icon = Icons.event;
        color = AppTheme.primaryColor;
        break;
      case ApplicationStatus.rejected:
        icon = Icons.cancel;
        color = AppTheme.errorColor;
        break;
      case ApplicationStatus.accepted:
        icon = Icons.verified;
        color = AppTheme.accentColor;
        break;
    }

    return Icon(icon, color: color);
  }
}

