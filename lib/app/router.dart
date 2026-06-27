import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
 
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/splash_screen.dart';
import '../features/home/presentation/onboarding_screen.dart';
import '../features/folders/presentation/folder_detail_screen.dart';
import '../features/editor/presentation/editor_screen.dart';
import '../features/templates/presentation/templates_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/about_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/pdf_viewer/presentation/screens/pdf_reader_workspace_screen.dart';
import '../features/editor/presentation/widgets/blocks/pdf_reader_screen.dart';
import '../features/planner/presentation/screens/planner_screen.dart';
import '../features/planner/presentation/screens/planner_item_detail_screen.dart';
import '../features/planner/presentation/screens/create_edit_planner_item_screen.dart';
import '../features/goals/presentation/goals_dashboard_screen.dart';
import '../features/goals/presentation/goal_detail_screen.dart';
import '../features/goals/presentation/create_edit_goal_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final uriStr = state.uri.toString();
      if (!uriStr.startsWith('/')) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/folders/:id',
        builder: (context, state) {
          final folderId = state.pathParameters['id']!;
          return FolderDetailScreen(folderId: folderId);
        },
      ),
      GoRoute(
        path: '/notes/create',
        builder: (context, state) {
          final folderId = state.uri.queryParameters['folderId'];
          final templateId = state.uri.queryParameters['templateId'];
          return EditorScreen(
            noteId: null,
            initialFolderId: folderId,
            initialTemplateId: templateId,
          );
        },
      ),
      GoRoute(
        path: '/notes/edit/:id',
        builder: (context, state) {
          final noteId = state.pathParameters['id']!;
          return EditorScreen(noteId: noteId);
        },
      ),
      GoRoute(
        path: '/pdf-reader',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return PdfReaderWorkspaceScreen(pdfPath: path);
        },
      ),
      GoRoute(
        path: '/templates',
        builder: (context, state) => const TemplatesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/planner',
        builder: (context, state) => const PlannerScreen(),
      ),
      GoRoute(
        path: '/planner/create',
        builder: (context, state) => const CreateEditPlannerItemScreen(),
      ),
      GoRoute(
        path: '/planner/item/:id',
        builder: (context, state) {
          final itemId = state.pathParameters['id']!;
          return PlannerItemDetailScreen(itemId: itemId);
        },
      ),
      GoRoute(
        path: '/planner/edit/:id',
        builder: (context, state) {
          // Edit is handled via Navigator.push from detail screen.
          // This route exists for notification tap deep links.
          final itemId = state.pathParameters['id']!;
          return PlannerItemDetailScreen(itemId: itemId);
        },
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsDashboardScreen(),
      ),
      GoRoute(
        path: '/goals/create',
        builder: (context, state) => const CreateEditGoalScreen(),
      ),
      GoRoute(
        path: '/goals/detail/:id',
        builder: (context, state) {
          final goalId = state.pathParameters['id']!;
          return GoalDetailScreen(goalId: goalId);
        },
      ),
      GoRoute(
        path: '/goals/edit_form/:id',
        builder: (context, state) {
          final goalId = state.pathParameters['id']!;
          return CreateEditGoalScreen(goalId: goalId);
        },
      ),
    ],
  );

  // Set up MethodChannel listener globally for PDF sharing
  const channel = MethodChannel('com.gentlegraph.gentlenotes/pdf_share');
  
  channel.setMethodCallHandler((call) async {
    if (call.method == 'onPdfShared') {
      final path = call.arguments as String?;
      if (path != null && path.isNotEmpty) {
        router.push('/pdf-reader?path=${Uri.encodeComponent(path)}');
      }
    }
  });

  return router;
});
