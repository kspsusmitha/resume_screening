import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/fade_in_widget.dart';
import 'job_form_screen.dart';
import 'job_analytics_screen.dart';

class JobManagementScreen extends StatelessWidget {
  final bool isCreating;

  const JobManagementScreen({super.key, this.isCreating = false});

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isHumanResources = user?.role == UserRole.hr;

    // Admin sees all jobs; HR sees only their jobs
    final displayedJobs = isHumanResources
        ? jobProvider.getJobsByHr(user?.id ?? '')
        : jobProvider.jobs;

    if (isCreating) {
      return const JobFormScreen();
    }

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Transparent to show dashboard background
      body: displayedJobs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 64,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No jobs posted yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  if (isHumanResources) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Create your first job posting',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayedJobs.length,
              itemBuilder: (context, index) {
                final job = displayedJobs[index];
                return FadeInWidget(
                  delay: Duration(milliseconds: index * 50),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      opacity: 0.2,
                      blur: 10,
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          job.title,
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
                              '${job.domain} • ${job.location}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _StatusChip(
                                  label: job.isApproved
                                      ? 'Approved'
                                      : 'Pending',
                                  color: job.isApproved
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                _StatusChip(
                                  label: job.isActive ? 'Active' : 'Closed',
                                  color: job.isActive
                                      ? AppTheme.accentColor
                                      : Colors.grey,
                                  isOutlined: !job.isActive,
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: isHumanResources
                            ? IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JobFormScreen(job: job),
                                    ),
                                  );
                                },
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobAnalyticsScreen(job: job),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: isHumanResources
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JobFormScreen()),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isOutlined;

  const _StatusChip({
    required this.label,
    required this.color,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOutlined ? color.withOpacity(0.5) : color.withOpacity(0.5),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Always white text for contrast on dark glass
        ),
      ),
    );
  }
}
