import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'core/service_locator.dart';
import 'providers/auth_provider.dart';
import 'providers/assignment_provider.dart';
import 'providers/student_assignment_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/chat_provider.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/teacher/teacher_dashboard_screen.dart';
import 'screens/teacher/classes/classes_screen.dart';
import 'screens/teacher/gradebook/gradebook_screen.dart';
import 'screens/teacher/assignments_screen.dart';
import 'screens/teacher/assignments/assignment_create_screen.dart';
import 'screens/student/student_dashboard_screen.dart';
import 'screens/student/courses_screen.dart';
import 'screens/student/grades_screen.dart';
import 'screens/student/assignments_screen.dart';
import 'screens/crashlytics_test_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'screens/chat/user_selection_screen.dart';
import 'screens/chat/group_creation_screen.dart';
import 'screens/chat/class_selection_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

bool _firebaseInitialized = false;

bool get isFirebaseInitialized => _firebaseInitialized;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase properly
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firebaseInitialized = true;
    
    // Enable Firestore offline persistence
    if (!kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
    
    // Initialize service locator
    await setupServiceLocator();
    
    // Initialize Crashlytics
    if (!kIsWeb) {
      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      
      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    _firebaseInitialized = false;
    // Firebase initialization failed - app will handle gracefully
  }

  runApp(const TeacherDashboardApp());
}

class TeacherDashboardApp extends StatelessWidget {
  const TeacherDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()),
        ChangeNotifierProvider(create: (_) => StudentAssignmentProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        // Gradebook provider will be added here
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.watch<AuthProvider>();
          final themeProvider = context.watch<ThemeProvider>();

          return MaterialApp.router(
            title: 'Teacher Dashboard',
            theme: AppTheme.lightTheme().copyWith(
              textTheme: AppTypography.createTextTheme(
                AppTheme.lightTheme().colorScheme,
              ),
            ),
            darkTheme: AppTheme.darkTheme().copyWith(
              textTheme: AppTypography.createTextTheme(
                AppTheme.darkTheme().colorScheme,
              ),
            ),
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: _createRouter(authProvider),
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/auth/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation.startsWith('/auth');

        // If not authenticated and trying to access protected route
        if (!isAuthenticated && !isAuthRoute) {
          return '/auth/login';
        }

        // If authenticated and trying to access auth routes
        if (isAuthenticated && isAuthRoute) {
          return '/dashboard';
        }

        // If authenticated but needs role selection (Google sign-in)
        if (authProvider.status == AuthStatus.authenticating &&
            state.matchedLocation != '/auth/role-selection') {
          return '/auth/role-selection';
        }

        return null;
      },
      routes: [
        // Auth Routes
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/auth/role-selection',
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: '/auth/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Main App Routes
        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final user = authProvider.userModel;

            if (user?.role == UserRole.teacher) {
              return const TeacherDashboardScreen();
            } else if (user?.role == UserRole.student) {
              return const StudentDashboardScreen();
            } else {
              return const DashboardScreen(); // Admin or fallback
            }
          },
        ),

        // Teacher Routes
        GoRoute(
          path: '/teacher/classes',
          builder: (context, state) => const ClassesScreen(),
        ),
        GoRoute(
          path: '/teacher/gradebook',
          builder: (context, state) => const GradebookScreen(),
        ),
        GoRoute(
          path: '/teacher/assignments',
          builder: (context, state) => const TeacherAssignmentsScreen(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const AssignmentCreateScreen(),
            ),
            GoRoute(
              path: ':assignmentId',
              builder: (context, state) {
                final assignmentId = state.pathParameters['assignmentId']!;
                return PlaceholderScreen(title: 'Assignment: $assignmentId');
              },
            ),
          ],
        ),
        GoRoute(
          path: '/teacher/students',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Students'),
        ),

        // Student Routes
        GoRoute(
          path: '/student/courses',
          builder: (context, state) => const StudentCoursesScreen(),
        ),
        GoRoute(
          path: '/student/assignments',
          builder: (context, state) => const StudentAssignmentsScreen(),
        ),
        GoRoute(
          path: '/student/grades',
          builder: (context, state) => const StudentGradesScreen(),
        ),

        // Common Routes
        GoRoute(
          path: '/messages',
          builder: (context, state) => const ChatListScreen(),
          routes: [
            GoRoute(
              path: ':chatRoomId',
              builder: (context, state) {
                final chatRoomId = state.pathParameters['chatRoomId']!;
                return ChatDetailScreen(chatRoomId: chatRoomId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/chat/user-selection',
          builder: (context, state) => const UserSelectionScreen(),
        ),
        GoRoute(
          path: '/chat/group-creation',
          builder: (context, state) => const GroupCreationScreen(),
        ),
        GoRoute(
          path: '/chat/class-selection',
          builder: (context, state) => const ClassSelectionScreen(),
        ),
        GoRoute(
          path: '/chat/:chatRoomId',
          builder: (context, state) {
            final chatRoomId = state.pathParameters['chatRoomId']!;
            return ChatDetailScreen(chatRoomId: chatRoomId);
          },
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Calendar'),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Notifications'),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/help',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Help & Support'),
        ),
        GoRoute(
          path: '/crashlytics-test',
          builder: (context, state) => const CrashlyticsTestScreen(),
        ),

        // Redirect root to login
        GoRoute(
          path: '/',
          redirect: (_, __) => '/auth/login',
        ),
      ],
    );
  }
}

// Temporary Dashboard Screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome, ${user?.displayName ?? 'User'}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Role: ${user?.role.toString().split('.').last ?? 'Unknown'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}


class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This screen is under construction',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
