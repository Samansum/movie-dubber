import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_header.dart';
import 'new_dub_screen.dart';
import 'queue_screen.dart';
import 'completed_player_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  final AppState state;

  const MainNavigationScreen({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        String screenTitle = 'CineDub AI';
        String screenSubtitle = 'Khmer Engine';

        switch (state.currentTabIndex) {
          case 0:
            screenTitle = 'CineDub AI';
            screenSubtitle = 'Khmer Engine';
            break;
          case 1:
            screenTitle = 'Dubbing Queue';
            screenSubtitle = 'Pipeline Monitor';
            break;
          case 2:
            screenTitle = 'Completed Dub';
            screenSubtitle = 'Studio Player';
            break;
          case 3:
            screenTitle = 'Dubbing Settings';
            screenSubtitle = 'Gemini & TTS Config';
            break;
        }

        final List<Widget> screens = [
          NewDubScreen(state: state),
          QueueScreen(state: state),
          CompletedPlayerScreen(state: state),
          SettingsScreen(state: state),
        ];

        return Scaffold(
          backgroundColor: AppColors.canvasBase,
          appBar: AppHeader(
            title: screenTitle,
            subtitle: screenSubtitle,
            showBackButton: state.currentTabIndex != 0,
            onBack: () => state.setTabIndex(0),
          ),
          body: Stack(
            children: [
              // Screen Body
              IndexedStack(
                index: state.currentTabIndex,
                children: screens,
              ),

              // Bottom Navigation Bar with Glassmorphic Floating Pill
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 68 + MediaQuery.of(context).padding.bottom,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 4,
                    left: 20,
                    right: 20,
                    top: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest.withOpacity(0.92),
                    border: const Border(
                      top: BorderSide(
                        color: Color(0x1AFFFFFF),
                        width: 1,
                      ),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80000000),
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.videocam_rounded,
                        label: 'Dub',
                        isSelected: state.currentTabIndex == 0,
                        onTap: () => state.setTabIndex(0),
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.graphic_eq_rounded,
                        label: 'Queue',
                        isSelected: state.currentTabIndex == 1,
                        hasBadge: state.isPipelineBusy,
                        onTap: () => state.setTabIndex(1),
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.play_circle_fill_rounded,
                        label: 'Player',
                        isSelected: state.currentTabIndex == 2,
                        onTap: () => state.setTabIndex(2),
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.tune_rounded,
                        label: 'Settings',
                        isSelected: state.currentTabIndex == 3,
                        onTap: () => state.setTabIndex(3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer.withOpacity(0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Color(0x667C3AED),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                if (hasBadge)
                  Positioned(
                    top: -2,
                    right: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color:
                    isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
