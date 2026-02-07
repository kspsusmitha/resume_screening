import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_in_widget.dart';
import '../../widgets/glass_container.dart';
import 'login_screen.dart';
import 'admin_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1497215728101-856f4ea42174?q=80&w=2070&auto=format&fit=crop',
              fit: BoxFit.cover,
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
                    Colors.white.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(100),
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: const Icon(
                          Icons.work_outline,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInWidget(
                      delay: const Duration(milliseconds: 400),
                      child: Text(
                        'Welcome to Resume Screening',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.8),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInWidget(
                      delay: const Duration(milliseconds: 600),
                      child: Text(
                        'Choose your role to continue',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),
                    FadeInWidget(
                      delay: const Duration(milliseconds: 800),
                      child: _RoleCard(
                        icon: Icons.business_center,
                        title: 'HR Manager',
                        description:
                            'Post jobs, screen candidates, and manage hiring',
                        role: UserRole.hr,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInWidget(
                      delay: const Duration(milliseconds: 1000),
                      child: _RoleCard(
                        icon: Icons.person,
                        title: 'Candidate',
                        description: 'Browse jobs, build resume, and apply',
                        role: UserRole.candidate,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInWidget(
                      delay: const Duration(milliseconds: 1200),
                      child: const _AdminCard(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final UserRole role;
  final Color color;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.role,
    required this.color,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
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
            scale: 1.0 + (_controller.value * 0.02),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        LoginScreen(role: widget.role),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: GlassContainer(
                opacity: _isHovered ? 0.8 : 0.5,
                blur: 10,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                border: Border.all(
                  color: widget.color.withOpacity(_isHovered ? 0.5 : 0.1),
                  width: 1.5,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withOpacity(0.2),
                            widget.color.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: widget.color.withOpacity(0.5),
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

class _AdminCard extends StatefulWidget {
  const _AdminCard();

  @override
  State<_AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<_AdminCard>
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
            scale: 1.0 + (_controller.value * 0.02),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const AdminLoginScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: GlassContainer(
                opacity: _isHovered ? 0.8 : 0.5,
                blur: 10,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                border: Border.all(
                  color: Colors.red.withOpacity(_isHovered ? 0.5 : 0.1),
                  width: 1.5,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.2),
                            Colors.red.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrator',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'System administration and management',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.red.withOpacity(0.5),
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
