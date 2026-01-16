import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/application_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/slide_in_widget.dart';
import '../auth/role_selection_screen.dart';
import '../hr/job_management_screen.dart';
import '../hr/applications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final jobProvider = Provider.of<JobProvider>(context);
    final applicationProvider = Provider.of<ApplicationProvider>(context);

    final user = authProvider.currentUser;
    final totalJobs = jobProvider.jobs.length;
    final totalApplications = applicationProvider.applications.length;
    final totalHRs = 0; // Will be fetched from database
    final totalCandidates = 0; // Will be fetched from database

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const RoleSelectionScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildDashboard(user, totalJobs, totalApplications, totalHRs, totalCandidates)
          : _selectedIndex == 1
              ? const JobManagementScreen()
              : const ApplicationsScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.red,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Applications',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(
    User? user,
    int totalJobs,
    int totalApplications,
    int totalHRs,
    int totalCandidates,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInWidget(
              delay: const Duration(milliseconds: 100),
              child: SlideInWidget(
                direction: SlideDirection.top,
                delay: const Duration(milliseconds: 100),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${user?.name ?? 'Admin'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'System Administrator',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInWidget(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'System Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                SlideInWidget(
                  direction: SlideDirection.left,
                  delay: const Duration(milliseconds: 300),
                  child: _StatCard(
                    title: 'Total Jobs',
                    value: totalJobs.toString(),
                    icon: Icons.work,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SlideInWidget(
                  direction: SlideDirection.right,
                  delay: const Duration(milliseconds: 400),
                  child: _StatCard(
                    title: 'Applications',
                    value: totalApplications.toString(),
                    icon: Icons.assignment,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                SlideInWidget(
                  direction: SlideDirection.left,
                  delay: const Duration(milliseconds: 500),
                  child: _StatCard(
                    title: 'HR Managers',
                    value: totalHRs.toString(),
                    icon: Icons.business_center,
                    color: AppTheme.accentColor,
                  ),
                ),
                SlideInWidget(
                  direction: SlideDirection.right,
                  delay: const Duration(milliseconds: 600),
                  child: _StatCard(
                    title: 'Candidates',
                    value: totalCandidates.toString(),
                    icon: Icons.people,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FadeInWidget(
              delay: const Duration(milliseconds: 700),
              child: Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                SlideInWidget(
                  direction: SlideDirection.left,
                  delay: const Duration(milliseconds: 800),
                  child: _ActionCard(
                    title: 'Manage Jobs',
                    icon: Icons.work_outline,
                    color: AppTheme.primaryColor,
                    onTap: () {
                      setState(() => _selectedIndex = 1);
                    },
                  ),
                ),
                SlideInWidget(
                  direction: SlideDirection.right,
                  delay: const Duration(milliseconds: 900),
                  child: _ActionCard(
                    title: 'View Applications',
                    icon: Icons.assignment_outlined,
                    color: AppTheme.secondaryColor,
                    onTap: () {
                      setState(() => _selectedIndex = 2);
                    },
                  ),
                ),
                SlideInWidget(
                  direction: SlideDirection.left,
                  delay: const Duration(milliseconds: 1000),
                  child: _ActionCard(
                    title: 'User Management',
                    icon: Icons.people_outline,
                    color: AppTheme.accentColor,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User Management coming soon!')),
                      );
                    },
                  ),
                ),
                SlideInWidget(
                  direction: SlideDirection.right,
                  delay: const Duration(milliseconds: 1100),
                  child: _ActionCard(
                    title: 'System Settings',
                    icon: Icons.settings_outlined,
                    color: Colors.red,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('System Settings coming soon!')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
