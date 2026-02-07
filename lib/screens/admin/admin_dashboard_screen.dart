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
import '../../widgets/glass_container.dart';

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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=2072&auto=format&fit=crop',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(color: AppTheme.backgroundColor);
              },
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: AppTheme.backgroundColor),
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildMainDashboard(
                  context,
                  user,
                  totalJobs,
                  totalPendingJobs,
                  authProvider,
                ),
                const JobManagementScreen(),
                const ApplicationsScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Apps'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin Welcome Card with Logout button
          FadeInWidget(
            delay: const Duration(milliseconds: 100),
            child: GlassContainer(
              opacity: 0.2,
              blur: 10,
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
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
                          'Welcome, ${user?.name ?? 'Admin'}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
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
                  IconButton(
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
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          FadeInWidget(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'System Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
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
              FadeInWidget(
                delay: const Duration(milliseconds: 300),
                child: _StatCard(
                  title: 'Jobs Posted',
                  value: totalJobs.toString(),
                  icon: Icons.post_add,
                  color: Colors.blue,
                  onTap: () => setState(() => _selectedIndex = 1), // Jobs tab
                ),
              ),
              FadeInWidget(
                delay: const Duration(milliseconds: 400),
                child: _StatCard(
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
              ),
              FadeInWidget(
                delay: const Duration(milliseconds: 500),
                child: _StatCard(
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
              ),
              FadeInWidget(
                delay: const Duration(milliseconds: 600),
                child: _StatCard(
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
              ),
            ],
          ),

          const SizedBox(height: 30),

          FadeInWidget(
            delay: const Duration(milliseconds: 700),
            child: Text(
              'Quick Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Secondary Action List
          FadeInWidget(
            delay: const Duration(milliseconds: 800),
            child: Column(
              children: [
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
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        opacity: 0.1,
        blur: 5,
        padding: const EdgeInsets.all(0),
        color: Colors.white,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.1),
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white),
          onTap: () {
            // Add logic for specific admin settings
          },
        ),
      ),
    );
  }
}

// --- Supporting Custom Widgets ---

class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_controller.value * 0.05),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: GlassContainer(
                opacity: _isHovered ? 0.2 : 0.1,
                blur: 10,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      color: widget.color.withOpacity(0.8),
                      size: 30,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.value,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
