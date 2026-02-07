import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/fade_in_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.8),
                    AppTheme.backgroundColor,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: notificationProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return FadeInWidget(
                        delay: Duration(milliseconds: index * 50),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              if (!notification.isRead) {
                                notificationProvider.markAsRead(
                                  notification.id,
                                );
                              }
                              // Navigate to related screen if needed based on type
                              // For now, just mark as read
                            },
                            child: GlassContainer(
                              opacity: notification.isRead ? 0.2 : 0.4,
                              blur: 10,
                              padding: const EdgeInsets.all(16),
                              border: Border.all(
                                color: notification.isRead
                                    ? Colors.white.withOpacity(0.1)
                                    : AppTheme.accentColor.withOpacity(0.5),
                                width: 1,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _getIconColor(
                                        notification.type,
                                      ).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getIcon(notification.type),
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notification.title,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      notification.isRead
                                                      ? FontWeight.normal
                                                      : FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            if (!notification.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.accentColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notification.message,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          DateFormat(
                                            'MMM d, h:mm a',
                                          ).format(notification.timestamp),
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                            fontSize: 12,
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'status_update':
        return Icons.update;
      case 'interview_scheduled':
        return Icons.calendar_today;
      case 'application_received':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'status_update':
        return Colors.blue;
      case 'interview_scheduled':
        return AppTheme.accentColor;
      case 'application_received':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
