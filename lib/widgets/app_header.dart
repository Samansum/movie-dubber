import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AppHeader({
    super.key,
    this.title = 'CineDub AI',
    this.subtitle = 'Khmer Engine',
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.88),
        border: const Border(
          bottom: BorderSide(
            color: Color(0x1AFFFFFF),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand / Logo or Back Button
          Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.onSurface),
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                )
              else
                // CineDub Logo Emblem
                Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 10),
                  child: const Center(
                    child: Image(
                        image: AssetImage('assets/images/logo.png'),
                        width: 34,
                        height: 34),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle.toUpperCase(),
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.secondary,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Status & Avatar
          // Row(
          //   children: [
          //     // Online Indicator with Creator Avatar
          //     Stack(
          //       clipBehavior: Clip.none,
          //       children: [
          //         Container(
          //           width: 36,
          //           height: 36,
          //           decoration: BoxDecoration(
          //             shape: BoxShape.circle,
          //             border: Border.all(
          //                 color: AppColors.primaryContainer, width: 1.5),
          //             boxShadow: const [
          //               BoxShadow(
          //                 color: Color(0x667C3AED),
          //                 blurRadius: 12,
          //               ),
          //             ],
          //             image: const DecorationImage(
          //               image: AssetImage('assets/images/logo.png'),
          //               fit: BoxFit.cover,
          //             ),
          //           ),
          //         ),
          //         // Positioned(
          //         //   bottom: -1,
          //         //   right: -1,
          //         //   child: Container(
          //         //     width: 10,
          //         //     height: 10,
          //         //     decoration: BoxDecoration(
          //         //       color: AppColors.tertiary,
          //         //       shape: BoxShape.circle,
          //         //       border: Border.all(color: AppColors.surface, width: 2),
          //         //       boxShadow: const [
          //         //         BoxShadow(
          //         //           color: AppColors.tertiary,
          //         //           blurRadius: 6,
          //         //           spreadRadius: 1,
          //         //         ),
          //         //       ],
          //         //     ),
          //         //   ),
          //         // ),
          //       ],
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
