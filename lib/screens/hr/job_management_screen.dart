import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'job_form_screen.dart';

class JobManagementScreen extends StatelessWidget {
  final bool isCreating;

  const JobManagementScreen({super.key, this.isCreating = false});

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final hrJobs = jobProvider.getJobsByHr(authProvider.currentUser?.id ?? '');

    if (isCreating) {
      return JobFormScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Management'),
      ),
      body: hrJobs.isEmpty
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
                  const SizedBox(height: 8),
                  Text(
                    'Create your first job posting',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: hrJobs.length,
              itemBuilder: (context, index) {
                final job = hrJobs[index];
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
                            job.isActive ? 'Active' : 'Closed',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: job.isActive
                              ? AppTheme.accentColor.withOpacity(0.2)
                              : Colors.grey[300],
                        ),
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
                          builder: (_) => JobFormScreen(job: job),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const JobFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

