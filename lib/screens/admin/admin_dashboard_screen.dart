import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import your existing providers
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/application_provider.dart';

// Import your existing models and themes
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

// Import your existing animation widgets
import '../../widgets/fade_in_widget.dart';
import '../../widgets/slide_in_widget.dart';

// Import screens to navigate to
import '../auth/role_selection_screen.dart';
import '../hr/job_management_screen.dart';
import '../hr/applications_screen.dart';
import 'admin_job_approval_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  int _hrCount = 0;
  int _candidateCount = 0;

  @override
  void initState() {
    super.initState();
    // Schedule the load after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobProvider>(context, listen: false).loadJobs();
      Provider.of<ApplicationProvider>(
        context,
        listen: false,
      ).loadApplications();
      _loadCounts();
    });
  }

  Future<void> _loadCounts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final candidates = await authProvider.fetchCandidates();
    final hrs = await authProvider.fetchHRs();
    if (mounted) {
      setState(() {
        _candidateCount = candidates.length;
        _hrCount = hrs.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Accessing your data providers
    final authProvider = Provider.of<AuthProvider>(context);
    final jobProvider = Provider.of<JobProvider>(context);

    final user = authProvider.currentUser;

    // DATA FOR THE FUNCTIONALITIES
    final int totalJobs = jobProvider.jobs.length;
    final int totalPendingJobs = jobProvider.pendingApprovalJobs.length;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMainDashboard(
            context,
            user,
            totalJobs,
            totalPendingJobs,
            authProvider,
          ), // Pass authProvider
          const JobManagementScreen(),
          const ApplicationsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Apps'),
          // Users tab removed
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildMainDashboard(
    BuildContext context,
    User? user,
    int totalJobs,
    int totalPendingJobs,
    AuthProvider authProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.red.withOpacity(0.05), Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Welcome Card with Logout button
            Stack(
              children: [
                FadeInWidget(
                  child: SlideInWidget(
                    direction: SlideDirection.top,
                    child: _AdminHeader(userName: user?.name ?? 'Admin'),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Logout',
                    onPressed: () {
                      authProvider.logout();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const RoleSelectionScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Text(
              'System Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // THE 4 CORE FUNCTIONALITIES GRID
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.3,
              children: [
                _StatCard(
                  title: 'Jobs Posted',
                  value: totalJobs.toString(),
                  icon: Icons.post_add,
                  color: Colors.blue,
                  onTap: () => setState(() => _selectedIndex = 1), // Jobs tab
                ),
                _StatCard(
                  title: 'HR Managers',
                  value: _hrCount.toString(),
                  icon: Icons.business,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const UserManagementScreen(initialIndex: 1),
                      ),
                    );
                  },
                ),
                _StatCard(
                  title: 'Candidates',
                  value: _candidateCount.toString(),
                  icon: Icons.group,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const UserManagementScreen(initialIndex: 0),
                      ),
                    );
                  },
                ),
                _StatCard(
                  title: 'Pending Jobs',
                  value: totalPendingJobs.toString(),
                  icon: Icons.pending_actions,
                  color: AppTheme.warningColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminJobApprovalScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            Text(
              'Quick Management',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Secondary Action List
            _buildActionTile(
              Icons.analytics,
              "View Hiring Analytics",
              "Check recruitment conversion rates",
            ),
            _buildActionTile(
              Icons.security,
              "Access Logs",
              "Review system activity logs",
            ),
            _buildActionTile(
              Icons.settings,
              "System Settings",
              "Configure AI API keys and site settings",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.1),
          child: Icon(icon, color: Colors.red),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Add logic for specific admin settings
        },
      ),
    );
  }
}

// --- Supporting Custom Widgets ---

class _AdminHeader extends StatelessWidget {
  final String userName;
  const _AdminHeader({
    super.key,
    required this.userName,
  }); // Added super.key and fixed constructor

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'System Administrator',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shadowColor: color.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.1), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
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
