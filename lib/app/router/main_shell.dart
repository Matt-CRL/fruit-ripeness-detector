import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/core/layout/kami_responsive.dart';

const _mainNavigationPillHeight = 76.0;
const _mainNavigationBottomMargin = 12.0;

double mainNavigationContentBottomInset(BuildContext context) {
  final systemBottomInset = MediaQuery.viewPaddingOf(context).bottom;
  return _mainNavigationPillHeight +
      (systemBottomInset > _mainNavigationBottomMargin
          ? systemBottomInset
          : _mainNavigationBottomMargin);
}

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    void openBranch(int index) {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      key: const Key('main-shell-scaffold'),
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          key: const Key('main-nav-pill'),
          elevation: 4,
          shadowColor: theme.cardTheme.shadowColor ?? colorScheme.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colorScheme.outline, width: 0.7),
          ),
          clipBehavior: Clip.antiAlias,
          color: colorScheme.surface,
          child: SizedBox(
            height: _mainNavigationPillHeight,
            child: Row(
              children: [
                _NavigationItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                  selected: navigationShell.currentIndex == 0,
                  onTap: () => openBranch(0),
                ),
                _NavigationItem(
                  icon: Icons.inventory_2_outlined,
                  selectedIcon: Icons.inventory_2,
                  label: 'Batches',
                  selected: navigationShell.currentIndex == 1,
                  onTap: () => openBranch(1),
                ),
                _CenterScanButton(onTap: () => context.push(AppRoutes.scan)),
                _NavigationItem(
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history,
                  label: 'History',
                  selected: navigationShell.currentIndex == 2,
                  onTap: () => openBranch(2),
                ),
                _NavigationItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Profile',
                  selected: navigationShell.currentIndex == 3,
                  onTap: () => openBranch(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final compact = KamiResponsive.isCompactPhone(context);

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          child: ExcludeSemantics(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? selectedIcon : icon,
                    color: color,
                    size: compact ? 22 : 25,
                  ),
                  SizedBox(height: compact ? 3 : 5),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: color,
                      fontSize: compact ? 11 : 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterScanButton extends StatelessWidget {
  const _CenterScanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: 'Scan',
        child: Center(
          child: Material(
            key: const Key('main-nav-scan-button'),
            color: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
                child: const SizedBox(
                  width: 60,
                  height: 48,
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.document_scanner_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
