import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class UserProfileScreen extends StatelessWidget {
  final User user;

  const UserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${user.role == UserRole.hr ? "HR Manager" : "Candidate"} Profile',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      user.role == UserRole.hr ? 'HR Manager' : 'Candidate',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: user.role == UserRole.hr
                        ? Colors.blueAccent
                        : Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Details Section
            _buildDetailTile(Icons.email, 'Email', user.email),
            if (user.phone != null && user.phone!.isNotEmpty)
              _buildDetailTile(Icons.phone, 'Phone', user.phone!),
            if (user.role == UserRole.hr &&
                user.company != null &&
                user.company!.isNotEmpty)
              _buildDetailTile(Icons.business, 'Company', user.company!),

            _buildDetailTile(
              Icons.calendar_today,
              'Joined',
              '${user.createdAt.year}-${user.createdAt.month.toString().padLeft(2, '0')}-${user.createdAt.day.toString().padLeft(2, '0')}',
            ),

            // Placeholder for future stats (e.g., Jobs Posted for HR)
            const SizedBox(height: 20),
            // We can add "Jobs Posted" count or list here later if needed
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600]),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
