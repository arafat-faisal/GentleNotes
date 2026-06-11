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
import '../features/editor/presentation/widgets/blocks/pdf_reader_screen.dart';
 
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
          return PdfReaderScreen(pdfPath: path);
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
