import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../models/application_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/fade_in_widget.dart';
import 'application_detail_screen.dart';

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final applicationProvider = Provider.of<ApplicationProvider>(context);
    final jobProvider = Provider.of<JobProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final currentUser = authProvider.currentUser;
    List<Application> applications = [];

    if (currentUser?.role == UserRole.admin) {
      // Admin sees all applications
      applications = applicationProvider.applications;
    } else {
      // HR sees only applications for their jobs
      final hrJobs = jobProvider.getJobsByHr(currentUser?.id ?? '');
      applications = applicationProvider.applications
          .where((a) => hrJobs.any((j) => j.id == a.jobId))
          .toList();
    }

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Transparent to show dashboard background
      // Removed AppBar as this screen is embedded in AdminDashboardScreen's IndexedStack
      body: (applicationProvider.isLoading || jobProvider.isLoading)
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : applications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No applications yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
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

                return FadeInWidget(
                  delay: Duration(
                    milliseconds: index * 50,
                  ), // Staggered animation
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      opacity: 0.2,
                      blur: 10,
                      padding: EdgeInsets.zero, // ListTile handles padding
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          application.candidateName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              application.candidateEmail,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                            if (job != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Applied for: ${job.title}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (application.matchPercentage != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (application.matchPercentage! >= 70
                                              ? AppTheme.accentColor
                                              : AppTheme.warningColor)
                                          .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        (application.matchPercentage! >= 70
                                                ? AppTheme.accentColor
                                                : AppTheme.warningColor)
                                            .withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  'Match: ${application.matchPercentage!.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
                              builder: (_) => ApplicationDetailScreen(
                                application: application,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toString().split('.').last.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CandidateCategory category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category.toString().split('.').last,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
