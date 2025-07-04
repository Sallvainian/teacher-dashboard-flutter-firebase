import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/common/adaptive_layout.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../theme/app_spacing.dart';
import '../../services/test_service.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;
    final theme = Theme.of(context);

    return AdaptiveLayout(
      title: 'Teacher Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Navigate to notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            context.go('/settings');
          },
        ),
      ],
      body: ResponsiveContainer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Card(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            user?.displayName.isNotEmpty == true
                                ? user!.displayName[0].toUpperCase()
                                : 'T',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getUserFirstName(user, authProvider),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Quick Stats
              Text(
                  'Quick Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              _buildQuickStatsGrid(context),
              const SizedBox(height: AppSpacing.lg),

              // Recent Activity
              Text(
                  'Recent Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              _buildRecentActivityCard(context),
              const SizedBox(height: AppSpacing.lg),

              // Quick Actions
              Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              _buildQuickActionsGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid(BuildContext context) {
    return ResponsiveGrid(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mobileColumns: 2,
      tabletColumns: 4,
      desktopColumns: 4,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      childAspectRatio: 1.2, // Reduced from 1.5 to give more height
      children: [
        _buildStatCard(
          context,
          icon: Icons.class_,
          title: 'Classes',
          value: '5',
          color: Colors.blue,
        ),
        _buildStatCard(
          context,
          icon: Icons.people,
          title: 'Students',
          value: '127',
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          icon: Icons.assignment,
          title: 'Assignments',
          value: '23',
          color: Colors.orange,
        ),
        _buildStatCard(
          context,
          icon: Icons.grade,
          title: 'To Grade',
          value: '8',
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildActivityItem(
              context,
              icon: Icons.assignment_turned_in,
              title: 'New assignment submitted',
              subtitle: 'John Doe submitted Math Homework #5',
              time: '2 hours ago',
              color: Colors.green,
            ),
            const Divider(),
            _buildActivityItem(
              context,
              icon: Icons.message,
              title: 'New message',
              subtitle: 'Parent inquiry about Sarah\'s progress',
              time: '4 hours ago',
              color: Colors.blue,
            ),
            const Divider(),
            _buildActivityItem(
              context,
              icon: Icons.schedule,
              title: 'Upcoming deadline',
              subtitle: 'Science Project due tomorrow',
              time: '1 day left',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return ResponsiveGrid(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mobileColumns: 2,
      tabletColumns: 3,
      desktopColumns: 3,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      childAspectRatio: 1.0, // Reduced to give more height for action cards
      children: [
        _buildActionCard(
          context,
          icon: Icons.add_circle_outline,
          title: 'Create Assignment',
          subtitle: 'Add new homework or project',
          onTap: () {
            // TODO: Navigate to create assignment
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.grade,
          title: 'Grade Work',
          subtitle: 'Review student submissions',
          onTap: () {
            // TODO: Navigate to grading
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.bug_report,
          title: 'Test Crashlytics',
          subtitle: 'Test crash reporting',
          onTap: () {
            context.go('/crashlytics-test');
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.chat,
          title: 'Message Parents',
          subtitle: 'Send updates and announcements',
          onTap: () {
            context.go('/messages');
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.analytics,
          title: 'View Reports',
          subtitle: 'Class performance analytics',
          onTap: () {
            // TODO: Navigate to reports
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.schedule,
          title: 'Schedule Event',
          subtitle: 'Add to class calendar',
          onTap: () {
            // TODO: Navigate to calendar
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.backup,
          title: 'Export Data',
          subtitle: 'Download gradebook backup',
          onTap: () {
            // TODO: Export functionality
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.storage,
          title: 'Test Write DB',
          subtitle: 'Test Firestore write',
          onTap: () async {
            final testService = TestService();
            await testService.testWriteData();
          },
        ),
        _buildActionCard(
          context,
          icon: Icons.search,
          title: 'Test Read DB',
          subtitle: 'Test Firestore read',
          onTap: () async {
            final testService = TestService();
            await testService.testReadData();
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getUserFirstName(UserModel? user, AuthProvider authProvider) {
    // Try firstName field first
    if (user?.firstName.isNotEmpty == true) {
      return '${user!.firstName}!';
    }
    
    // Try displayName from user model
    if (user?.displayName.isNotEmpty == true) {
      final nameParts = user!.displayName.split(' ');
      if (nameParts.isNotEmpty) {
        return '${nameParts.first}!';
      }
    }
    
    // Try Firebase Auth displayName
    final firebaseUser = authProvider.firebaseUser;
    if (firebaseUser?.displayName?.isNotEmpty == true) {
      final nameParts = firebaseUser!.displayName!.split(' ');
      if (nameParts.isNotEmpty) {
        return '${nameParts.first}!';
      }
    }
    
    // Default fallback
    return 'Teacher!';
  }
}