import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/application_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/application_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final applicationProvider = Provider.of<ApplicationProvider>(context);
    final jobProvider = Provider.of<JobProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final myApplications = applicationProvider.getApplicationsByCandidate(
      authProvider.currentUser?.id ?? '',
    );

    return myApplications.isEmpty
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
                child: ExpansionTile(
                  leading: _StatusIcon(application.status),
                  title: Text(
                    job?.title ?? 'Unknown Job',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${application.status.toString().split('.').last.toUpperCase()}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(application.status),
                        ),
                      ),
                      if (application.matchPercentage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Match: ${application.matchPercentage!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: application.matchPercentage! >= 70
                                ? AppTheme.accentColor
                                : AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  children: [
                    if (application.status ==
                            ApplicationStatus.interviewScheduled &&
                        application.interviewDate != null)
                      _InterviewDetailsCard(application: application)
                    else
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Applied on ${DateFormat('MMM dd, yyyy').format(application.appliedDate)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                  ],
                ),
              );
            },
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

Color _getStatusColor(ApplicationStatus status) {
  switch (status) {
    case ApplicationStatus.applied:
      return Colors.blue;
    case ApplicationStatus.shortlisted:
      return AppTheme.accentColor;
    case ApplicationStatus.interviewScheduled:
      return AppTheme.primaryColor;
    case ApplicationStatus.rejected:
      return AppTheme.errorColor;
    case ApplicationStatus.accepted:
      return Colors.green;
  }
}

class _InterviewDetailsCard extends StatelessWidget {
  final Application application;

  const _InterviewDetailsCard({required this.application});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Interview Scheduled',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InterviewInfoRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: DateFormat(
              'EEEE, MMMM dd, yyyy',
            ).format(application.interviewDate!),
          ),
          if (application.interviewTime != null) ...[
            const SizedBox(height: 12),
            _InterviewInfoRow(
              icon: Icons.access_time,
              label: 'Time',
              value: application.interviewTime!,
            ),
          ],
          if (application.interviewerName != null) ...[
            const SizedBox(height: 12),
            _InterviewInfoRow(
              icon: Icons.person,
              label: 'Interviewer',
              value: application.interviewerName!,
            ),
          ],
          if (application.interviewLocation != null) ...[
            const SizedBox(height: 12),
            _InterviewInfoRow(
              icon: Icons.location_on,
              label: 'Location',
              value: application.interviewLocation!,
            ),
          ],
          if (application.interviewNotes != null &&
              application.interviewNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InterviewInfoRow(
              icon: Icons.note,
              label: 'Notes',
              value: application.interviewNotes!,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please arrive on time for your interview. Good luck!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InterviewInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InterviewInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
