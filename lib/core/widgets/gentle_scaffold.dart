import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../responsive/responsive_layout.dart';
import '../../features/folders/data/folders_repository.dart';
import '../../features/settings/data/settings_repository.dart';

class GentleScaffold extends ConsumerWidget {
  final Widget body;
  final String title;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool showBackButton;

  const GentleScaffold({
    super.key,
    required this.body,
    required this.title,
    this.floatingActionButton,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentRoute = GoRouterState.of(context).uri.path;

    if (isMobile) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(title),
          leading: showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                )
              : null,
          actions: actions,
        ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF10121F) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _getBottomNavIndex(currentRoute),
            onTap: (index) => _onBottomNavTapped(context, index),
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFF8B5CF6),
            unselectedItemColor: isDark ? const Color(0xFF6B5F8A) : const Color(0xFFAA9ECC),
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined),
                activeIcon: Icon(Icons.grid_view_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment_rounded),
                label: 'Templates',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tune_rounded),
                activeIcon: Icon(Icons.tune_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      );
    }

    // Desktop/Web Layout: Sidebar + Main Body
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // Futuristic Navigation Sidebar
          _buildSidebar(context, ref, currentRoute),
          // Main content area
          Expanded(
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                title: Text(title),
                leading: showBackButton
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                      )
                    : null,
                actions: actions,
              ),
              body: body,
              floatingActionButton: floatingActionButton,
            ),
          ),
        ],
      ),
    );
  }

  int _getBottomNavIndex(String route) {
    if (route.startsWith('/templates')) return 1;
    if (route.startsWith('/settings')) return 2;
    return 0;
  }

  void _onBottomNavTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/templates');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref, String currentRoute) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);
    final userRole = ref.watch(userRoleProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0B1A) : const Color(0xFFF8F5FF),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gentle Notes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'v1.0 · MVP',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── User Badge ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF13111C) : const Color(0xFFEDE9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF252234) : const Color(0xFFD8D0F0),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        userRole.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local Workspace',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            userRole.displayName,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8B5CF6),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(
              color: isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5),
              height: 16,
            ),
          ),

          // ── Nav Items ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              children: [
                _buildSidebarTile(
                  context: context,
                  icon: Icons.grid_view_rounded,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  route: '/home',
                  currentRoute: currentRoute,
                ),
                _buildSidebarTile(
                  context: context,
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment_rounded,
                  label: 'Templates',
                  route: '/templates',
                  currentRoute: currentRoute,
                ),
                _buildSidebarTile(
                  context: context,
                  icon: Icons.tune_rounded,
                  activeIcon: Icons.tune_rounded,
                  label: 'Settings',
                  route: '/settings',
                  currentRoute: currentRoute,
                ),
                _buildSidebarTile(
                  context: context,
                  icon: Icons.help_outline_rounded,
                  activeIcon: Icons.help_rounded,
                  label: 'About & Help',
                  route: '/about',
                  currentRoute: currentRoute,
                ),

                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    'FOLDERS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      color: isDark ? const Color(0xFF5A4F7A) : const Color(0xFFAA9ECC),
                    ),
                  ),
                ),

                ...folders.map((folder) {
                  final folderRoute = '/folders/${folder.id}';
                  final isActive = currentRoute == folderRoute;
                  final color = folder.color;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: InkWell(
                      onTap: () => context.go(folderRoute),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF7C3AED).withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: isActive
                                    ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                folder.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                  color: isActive
                                      ? const Color(0xFF8B5CF6)
                                      : theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    required String currentRoute,
  }) {
    final theme = Theme.of(context);
    final isActive = currentRoute == route;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF7C3AED).withOpacity(isDark ? 0.2 : 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? const Color(0xFF8B5CF6)
                    : theme.colorScheme.onSurface.withOpacity(0.5),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF8B5CF6)
                        : theme.colorScheme.onSurface.withOpacity(0.65),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B5CF6),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
