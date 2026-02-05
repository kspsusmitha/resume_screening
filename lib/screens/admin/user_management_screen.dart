import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'user_profile_screen.dart';

class UserManagementScreen extends StatefulWidget {
  final int initialIndex;
  const UserManagementScreen({super.key, this.initialIndex = 0});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> _allCandidates = [];
  List<User> _allHRs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Fetch both lists in parallel
    final results = await Future.wait([
      authProvider.fetchCandidates(),
      authProvider.fetchHRs(),
    ]);

    if (mounted) {
      setState(() {
        _allCandidates = results[0];
        _allHRs = results[1];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Candidates'),
            Tab(text: 'HR Managers'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(_allCandidates, UserRole.candidate),
                _buildUserList(_allHRs, UserRole.hr),
              ],
            ),
    );
  }

  Widget _buildUserList(List<User> users, UserRole role) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              role == UserRole.candidate
                  ? Icons.people_outline
                  : Icons.business,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${role == UserRole.candidate ? 'candidates' : 'HR managers'} found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                if (user.company != null && user.company!.isNotEmpty)
                  Text(
                    'Company: ${user.company}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            trailing: role == UserRole.hr
                ? const Chip(
                    label: Text('HR', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.blueAccent,
                  )
                : const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(user: user),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
