import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/job_model.dart';
import '../../models/application_model.dart';
import '../../models/user_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_theme.dart';
import 'job_form_screen.dart';

class JobAnalyticsScreen extends StatefulWidget {
  final Job job;

  const JobAnalyticsScreen({super.key, required this.job});

  @override
  State<JobAnalyticsScreen> createState() => _JobAnalyticsScreenState();
}

class _JobAnalyticsScreenState extends State<JobAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applicationProvider = Provider.of<ApplicationProvider>(context);
    final jobProvider = Provider.of<JobProvider>(context);

    // Get fresh job data in case it was updated
    final currentJob = jobProvider.getJobById(widget.job.id) ?? widget.job;
    final applications = applicationProvider.getApplicationsByJob(
      currentJob.id,
    );

    final totalApplications = applications.length;
    final pendingCount = applications
        .where((a) => a.status == ApplicationStatus.applied)
        .length;
    final interviewCount = applications
        .where((a) => a.status == ApplicationStatus.interviewScheduled)
        .length;
    final selectedCount = applications
        .where((a) => a.status == ApplicationStatus.accepted)
        .length;

    final selectedCandidates = applications
        .where((a) => a.status == ApplicationStatus.accepted)
        .toList();

    final otherCandidates = applications
        .where((a) => a.status != ApplicationStatus.accepted)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Job',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobFormScreen(job: currentJob),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Job Status Banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentJob.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatusChip(
                            label: currentJob.isApproved
                                ? 'Approved'
                                : 'Pending Approval',
                            color: currentJob.isApproved
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: currentJob.isActive ? 'Active' : 'Closed',
                            color: currentJob.isActive
                                ? AppTheme.accentColor
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total',
                    value: totalApplications.toString(),
                    color: Colors.blue,
                    icon: Icons.people,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'Pending',
                    value: pendingCount.toString(),
                    color: Colors.orange,
                    icon: Icons.hourglass_empty,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'Interviews',
                    value: interviewCount.toString(),
                    color: Colors.purple,
                    icon: Icons.calendar_month,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'Selected',
                    value: selectedCount.toString(),
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Applicants'),
              Tab(text: 'Selected Candidates'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Applicants List
                otherCandidates.isEmpty && selectedCandidates.isEmpty
                    ? const Center(child: Text('No applications yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: otherCandidates.length,
                        itemBuilder: (context, index) {
                          final app = otherCandidates[index];
                          return _CandidateCard(application: app);
                        },
                      ),

                // Selected Candidates List
                selectedCandidates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            const Text('No candidates selected yet.'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: selectedCandidates.length,
                        itemBuilder: (context, index) {
                          final app = selectedCandidates[index];
                          return _CandidateCard(
                            application: app,
                            isSelected: true,
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Application application;
  final bool isSelected;

  const _CandidateCard({required this.application, this.isSelected = false});

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.accepted:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
      case ApplicationStatus.interviewScheduled:
        return Colors.purple;
      case ApplicationStatus.shortlisted:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    application.candidateName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.candidateName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        application.candidateEmail,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(application.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    application.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(application.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            if (application.matchPercentage != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: application.matchPercentage! / 100,
                backgroundColor: Colors.grey[200],
                color: application.matchPercentage! >= 70
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(height: 4),
              Text(
                'AI Match Score: ${application.matchPercentage!.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (application.interviewDate != null &&
                application.status == ApplicationStatus.interviewScheduled) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Interview: ${DateFormat('MMM dd, hh:mm a').format(application.interviewDate!)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
