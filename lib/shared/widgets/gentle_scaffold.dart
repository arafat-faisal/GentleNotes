/// The primary scaffold wrapper for GentleNotes.
///
/// Wraps all screens with consistent navigation (sidebar on desktop,
/// bottom nav on mobile) and an AppBar. Screens should use [GentleScaffold]
/// instead of [Scaffold] directly to ensure consistent chrome.
///
/// Responsibilities of this widget:
/// - Responsive layout switching (mobile vs desktop)
/// - Navigation item highlighting based on current route
/// - Folder list rendering in sidebar (desktop)
/// - User badge display
///
/// This widget does NOT contain business logic. Navigation decisions are
/// driven by route state, and data (folders, user role) is read via Riverpod.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/responsive_helper.dart';
import '../../features/folders/presentation/controllers/folders_controller.dart';
import '../../features/notes/presentation/controllers/notes_controller.dart';
import '../../features/settings/presentation/controllers/settings_controller.dart';
import '../../models/models.dart';

class GentleScaffold extends ConsumerWidget {
  const GentleScaffold({
    super.key,
    required this.body,
    required this.title,
    this.titleWidget,
    this.floatingActionButton,
    this.actions,
    this.showBackButton = false,
    this.showBottomNav = true,
    this.appBar,
  });

  final Widget body;
  final String title;
  final Widget? titleWidget;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showBottomNav;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final theme = Theme.of(context);
    final currentRoute = GoRouterState.of(context).uri.path;

    final selectedIds = ref.watch(selectedNoteIdsProvider);
    final isBatchActive = selectedIds.isNotEmpty;

    if (isMobile) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar ?? (isBatchActive ? _buildBatchAppBar(context, ref, theme, selectedIds) : _buildAppBar(context, theme)),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: showBottomNav
            ? Container(
                decoration: BoxDecoration(
                  color: theme.bottomNavigationBarTheme.backgroundColor ?? theme.cardColor,
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _getBottomNavIndex(currentRoute),
                  onTap: (index) => _onBottomNavTapped(context, index),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor ?? theme.colorScheme.primary,
                  unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
                      icon: Icon(Icons.flag_outlined),
                      activeIcon: Icon(Icons.flag_rounded),
                      label: 'Goals',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_month_outlined),
                      activeIcon: Icon(Icons.calendar_month_rounded),
                      label: 'Planner',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.tune_rounded),
                      activeIcon: Icon(Icons.tune_rounded),
                      label: 'Settings',
                    ),
                  ],
                ),
              )
            : null,
      );
    }

    // Desktop/Web Layout: Sidebar + Main Body
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          _buildSidebar(context, ref, currentRoute),
          Expanded(
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: appBar ?? (isBatchActive ? _buildBatchAppBar(context, ref, theme, selectedIds) : _buildAppBar(context, theme)),
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
    if (route.startsWith('/goals'))     return 2;
    if (route.startsWith('/planner'))   return 3;
    if (route.startsWith('/settings'))  return 4;
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
        context.go('/goals');
        break;
      case 3:
        context.go('/planner');
        break;
      case 4:
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
        color: theme.cardColor,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor,
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
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
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
                    Text('v1.0 · MVP', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
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
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        userRole.displayName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
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
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            userRole.displayName,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: theme.colorScheme.primary, letterSpacing: 0.5),
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
              color: theme.dividerColor,
              height: 16,
            ),
          ),

          // ── Nav Items ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              children: [
                _buildSidebarTile(context: context, icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'Dashboard', route: '/home', currentRoute: currentRoute),
                _buildSidebarTile(context: context, icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Templates', route: '/templates', currentRoute: currentRoute),
                _buildSidebarTile(context: context, icon: Icons.flag_outlined, activeIcon: Icons.flag_rounded, label: 'Goals', route: '/goals', currentRoute: currentRoute),
                _buildSidebarTile(context: context, icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Planner', route: '/planner', currentRoute: currentRoute),
                _buildSidebarTile(context: context, icon: Icons.tune_rounded, activeIcon: Icons.tune_rounded, label: 'Settings', route: '/settings', currentRoute: currentRoute),
                _buildSidebarTile(context: context, icon: Icons.help_outline_rounded, activeIcon: Icons.help_rounded, label: 'About & Help', route: '/about', currentRoute: currentRoute),

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
                          color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
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
                                boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)] : null,
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
                                  color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
            color: isActive ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                    color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final backButtonWidth = width * 0.10;
          final titleWidth = width * 0.50;
          final actionsWidth = width * 0.40;

          return Row(
            children: [
              // Back button container (10%)
              SizedBox(
                width: backButtonWidth,
                child: showBackButton
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        child: const Center(
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              // Title container (50%)
              SizedBox(
                width: titleWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: titleWidget ?? Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // Actions/Tools container (40%)
              SizedBox(
                width: actionsWidth,
                child: actions != null
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: actions ?? [],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildBatchAppBar(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<String> selectedIds,
  ) {
    final folders = ref.watch(foldersProvider);

    return AppBar(
      backgroundColor: theme.colorScheme.primaryContainer,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          ref.read(selectedNoteIdsProvider.notifier).state = [];
        },
        tooltip: 'Cancel Selection',
      ),
      title: Text(
        '${selectedIds.length} Selected',
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: 'Select All Visible',
          onPressed: () {
            final visibleNotes = ref.read(filteredNotesProvider);
            ref.read(selectedNoteIdsProvider.notifier).state =
                visibleNotes.map((n) => n.id).toList();
          },
        ),
        IconButton(
          icon: const Icon(Icons.folder_open_outlined),
          tooltip: 'Move Selected to Folder',
          onPressed: () async {
            final targetFolderId = await showDialog<String?>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Move Notes to Folder'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.folder_off_outlined),
                        title: const Text('No Folder (General)'),
                        onTap: () => Navigator.pop(context, ''),
                      ),
                      const Divider(),
                      ...folders.map((f) {
                            final parent = folders.cast<FolderModel?>().firstWhere(
                                  (x) => x?.id == f.parentFolderId,
                                  orElse: () => null,
                                );
                            return ListTile(
                              leading: Icon(Icons.folder, color: f.color),
                              title: Text(f.name),
                              subtitle: parent != null 
                                  ? Text('Subfolder of: ${parent.name}', style: const TextStyle(fontSize: 11)) 
                                  : null,
                              onTap: () => Navigator.pop(context, f.id),
                            );
                          }),
                    ],
                  ),
                ),
              ),
            );
            if (targetFolderId != null) {
              final folderId = targetFolderId.isEmpty ? null : targetFolderId;
              await ref.read(notesProvider.notifier).moveNotesToFolder(selectedIds, folderId);
              ref.read(selectedNoteIdsProvider.notifier).state = [];
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete Selected',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Notes?'),
                content: Text(
                  'Are you sure you want to permanently delete these ${selectedIds.length} notes?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await ref.read(notesProvider.notifier).deleteMultipleNotes(selectedIds);
              ref.read(selectedNoteIdsProvider.notifier).state = [];
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
