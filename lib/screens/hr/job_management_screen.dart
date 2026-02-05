import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
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
      return const JobFormScreen(); // Fixed constructor call
    }

    return Scaffold(
      body: displayedJobs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No jobs posted yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (isHumanResources) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Create your first job posting',
                      style: Theme.of(context).textTheme.bodyMedium,
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(job.title),
                    subtitle: Text('${job.domain} • ${job.location}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: Text(
                            job.isApproved
                                ? 'Approved'
                                : 'Pending', // Show approval status
                            style: TextStyle(
                              fontSize: 12,
                              color: job.isApproved
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: job.isApproved
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                        ),
                        const SizedBox(width: 4),
                        Chip(
                          label: Text(
                            job.isActive ? 'Active' : 'Closed',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: job.isActive
                              ? AppTheme.accentColor.withOpacity(0.2)
                              : Colors.grey[300],
                        ),
                        // Only show Edit button for HR users who own the job
                        // Admin can edit via analytics screen if needed, or we can allow it here too.
                        // For now, let's keep it consistent: Admin views distinct lists.
                        if (isHumanResources)
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JobFormScreen(job: job),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobAnalyticsScreen(job: job),
                        ),
                      );
                    },
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
              child: const Icon(Icons.add),
            )
          : null, // Hide FAB for Admin
    );
  }
}
