import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';

/// Bottom navigation shell with a floating Liquid Glass tab bar.
class NavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const NavShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.glassBorder,
                  width: 0.5,
                ),
              ),
              child: Stack(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: BottomNavigationBar(
                      currentIndex: navigationShell.currentIndex,
                      onTap: (index) => navigationShell.goBranch(
                        index,
                        initialLocation:
                            index == navigationShell.currentIndex,
                      ),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      type: BottomNavigationBarType.fixed,
                      selectedItemColor: AppColors.primary,
                      unselectedItemColor: AppColors.textTertiary,
                      selectedFontSize: 10,
                      unselectedFontSize: 10,
                      iconSize: 22,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: EdgeInsets.only(bottom: 2),
                            child: Icon(Icons.dashboard_rounded),
                          ),
                          label: 'Dashboard',
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: EdgeInsets.only(bottom: 2),
                            child: Icon(Icons.book_rounded),
                          ),
                          label: 'Subjects',
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: EdgeInsets.only(bottom: 2),
                            child: Icon(Icons.calendar_month_rounded),
                          ),
                          label: 'Calendar',
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: EdgeInsets.only(bottom: 2),
                            child: Icon(Icons.schedule_rounded),
                          ),
                          label: 'Schedule',
                        ),
                      ],
                    ),
                  ),
                  // Specular highlight overlaid at top
                  Positioned(
                    top: 0.5,
                    left: 40,
                    right: 40,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            AppColors.glassHighlight,
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
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
