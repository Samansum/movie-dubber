import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_header.dart';
import 'new_dub_screen.dart';
import 'queue_screen.dart';
import 'completed_player_screen.dart';
import 'settings_screen.dart';
import 'video_chunk_screen.dart';

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
        // Read the catalog once per rebuild: switching App Language notifies
        // AppState, which re-runs this builder against the new locale.
        final l10n = AppLocalizations.of(context);
        String screenTitle = l10n.screenHomeTitle;
        String screenSubtitle = l10n.screenHomeSubtitle;

        switch (state.currentTabIndex) {
          case 0:
            screenTitle = l10n.screenHomeTitle;
            screenSubtitle = l10n.screenHomeSubtitle;
            break;
          case 1:
            screenTitle = l10n.screenQueueTitle;
            screenSubtitle = l10n.screenQueueSubtitle;
            break;
          case 2:
            screenTitle = l10n.screenPlayerTitle;
            screenSubtitle = l10n.screenPlayerSubtitle;
            break;
          case 3:
            screenTitle = l10n.screenSettingsTitle;
            screenSubtitle = l10n.screenSettingsSubtitle;
            break;
          case 4:
            screenTitle = l10n.screenChunkingTitle;
            screenSubtitle = l10n.screenChunkingSubtitle;
            break;
        }

        final List<Widget> screens = [
          NewDubScreen(state: state),
          QueueScreen(state: state),
          CompletedPlayerScreen(state: state),
          SettingsScreen(state: state),
          VideoChunkScreen(state: state),
        ];

        return Scaffold(
          backgroundColor: AppColors.canvasBase,
          appBar: AppHeader(
            title: screenTitle,
            subtitle: screenSubtitle,
            showBackButton: _showBackButton(state.currentTabIndex),
            onBack: () => state.setTabIndex(0),
            onSettingsTap: () => state.setTabIndex(3),
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
                        label: l10n.tabDub,
                        isSelected: state.currentTabIndex == 0,
                        onTap: () => state.setTabIndex(0),
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.graphic_eq_rounded,
                        label: l10n.tabQueue,
                        isSelected: state.currentTabIndex == 1,
                        hasBadge: state.isPipelineBusy,
                        onTap: () => state.setTabIndex(1),
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.play_circle_fill_rounded,
                        label: l10n.tabPlayer,
                        isSelected: state.currentTabIndex == 2,
                        onTap: () => state.setTabIndex(2),
                      ),
                      _buildNavItem(
                        index: 4,
                        icon: Icons.layers_rounded,
                        label: l10n.tabChunking,
                        isSelected: state.currentTabIndex == 4,
                        onTap: () => state.setTabIndex(4),
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

  /// Whether to show the back button in the header for the current tab.
  bool _showBackButton(int tabIndex) {
    return tabIndex != 0 && tabIndex != 4; // Don't show on Dub or Chunking
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
