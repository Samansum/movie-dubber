import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/dub_models.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;

  const SettingsScreen({
    super.key,
    required this.state,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  bool _obscureToken = true;

  final List<String> _models = [
    'Gemini 2.5 Flash',
    'Gemini 3.5 Flash',
    'Gemini 3.7 Flash',
    'Gemini 3.8 Flash',
  ];

  final List<String> _tones = [
    'Cinematic Dynamic',
    'Natural Dialogues',
    'Documentary Formal',
  ];

  final List<String> _rotationStrategies = [
    'Rate-Limit Balanced',
    'Round-Robin',
    'Failover Priority',
  ];

  @override
  void dispose() {
    _aliasController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _addApiKey() {
    final l10n = AppLocalizations.of(context);
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidTokenMessage)),
      );
      return;
    }

    widget.state.addApiKey(_aliasController.text.trim(), token);
    _aliasController.clear();
    _tokenController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryContainer,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(l10n.apiKeySavedMessage),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final keys = state.apiKeys;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Language / ភាសា — first so the language switch is easy to find.
          // Switching locale rebuilds MaterialApp, which re-inflates this tree
          // with the other catalog's strings on the next frame.
          Text(
            l10n.languageSectionTitle,
            style: AppTypography.labelSm.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.translate_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.languageSectionTitle,
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.languageSectionSubtitle,
                            style: AppTypography.bodySm
                                .copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildLanguageChip(
                      state: state,
                      l10n: l10n,
                      code: 'en',
                      label: l10n.languageEnglish,
                      isSelected: !state.isKhmer,
                    ),
                    _buildLanguageChip(
                      state: state,
                      l10n: l10n,
                      code: 'km',
                      label: l10n.languageKhmer,
                      isSelected: state.isKhmer,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Informational Banner: Gemini API Keys Pool
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF262A33), Color(0xFF181C24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.key_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.keysPoolTitle,
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.keysPoolSubtitle,
                        style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Registered Keys Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.registeredKeys,
                style: AppTypography.headlineSm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.borderSubtle, width: 0.5),
                ),
                child: Text(
                  l10n.configuredCount(keys.length),
                  style: AppTypography.labelSm.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // List of Registered Keys
          ...keys.map((key) => _buildKeyCard(key, state)),

          const SizedBox(height: 20),

          // Add New Key Form Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.addGeminiApiKey,
                      style: AppTypography.headlineSm.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Key Alias Field
                Text(l10n.keyAliasLabel, style: AppTypography.labelSm),
                const SizedBox(height: 6),
                TextField(
                  controller: _aliasController,
                  style: AppTypography.bodyMd,
                  decoration: InputDecoration(
                    hintText: l10n.keyAliasHint,
                    isDense: true,
                  ),
                ),

                const SizedBox(height: 12),

                // Secret Token Field
                Text(l10n.geminiSecretTokenLabel, style: AppTypography.labelSm),
                const SizedBox(height: 6),
                TextField(
                  controller: _tokenController,
                  obscureText: _obscureToken,
                  style: AppTypography.codeMono.copyWith(color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: l10n.tokenHint,
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureToken ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureToken = !_obscureToken;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Add API Key Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _addApiKey,
                    icon: const Icon(Icons.key_rounded, size: 18),
                    label: Text(
                      l10n.addApiKeyButton,
                      style: AppTypography.labelMd.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // AI Model & Translation Settings Section
          Text(
            l10n.translationSectionTitle,
            style: AppTypography.labelSm.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),

          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.defaultGeminiModel,
                  style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _models.map((model) {
                    final isSelected = state.selectedModel == model;
                    return ChoiceChip(
                      label: Text(
                        model,
                        style: AppTypography.labelSm.copyWith(
                          color: isSelected ? Colors.white : AppColors.onSurface,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryContainer,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      onSelected: (_) => state.setSelectedModel(model),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: 16),

                Text(
                  l10n.khmerToneStyle,
                  style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tones.map((tone) {
                    final isSelected = state.selectedTone == tone;
                    return ChoiceChip(
                      label: Text(
                        tone,
                        style: AppTypography.labelSm.copyWith(
                          color: isSelected ? Colors.white : AppColors.onSurface,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.secondaryContainer,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      onSelected: (_) => state.setSelectedTone(tone),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: 16),

                Text(
                  l10n.keyRotationStrategy,
                  style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _rotationStrategies.map((strat) {
                    final isSelected = state.keyRotationStrategy == strat;
                    return ChoiceChip(
                      label: Text(
                        strat,
                        style: AppTypography.labelSm.copyWith(
                          color: isSelected ? Colors.white : AppColors.onSurface,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF4F46E5),
                      backgroundColor: AppColors.surfaceContainerHigh,
                      onSelected: (_) => state.setKeyRotationStrategy(strat),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One of the two App Language options (English / ខ្មែរ).
  ///
  /// The chip shows the language in its own script in both locales — that is
  /// the convention for language pickers, so the option stays recognisable no
  /// matter which language the UI is currently in.
  Widget _buildLanguageChip({
    required AppState state,
    required AppLocalizations l10n,
    required String code,
    required String label,
    required bool isSelected,
  }) {
    return ChoiceChip(
      avatar: isSelected
          ? const Icon(Icons.check_circle_rounded,
              size: 16, color: Colors.white)
          : null,
      label: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          color: isSelected ? Colors.white : AppColors.onSurface,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryContainer,
      backgroundColor: AppColors.surfaceContainerHigh,
      onSelected: (_) {
        state.setAppLanguage(code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryContainer,
            content: Text(
              code == 'km'
                  ? l10n.languageSwitchedToKhmer
                  : l10n.languageSwitchedToEnglish,
            ),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  Widget _buildKeyCard(ApiKeyItem key, AppState state) {
    final l10n = AppLocalizations.of(context);
    Color statusColor;
    // The stored status is an invariant code ('Active'/'Standby'/'Cooldown'),
    // so switch on the raw value and translate only what gets rendered.
    switch (key.status) {
      case 'Active':
        statusColor = AppColors.tertiary;
        break;
      case 'Standby':
        statusColor = AppColors.secondary;
        break;
      case 'Cooldown':
      default:
        statusColor = AppColors.warning;
        break;
    }

    final String statusLabel;
    switch (key.status) {
      case 'Active':
        statusLabel = l10n.statusActive;
        break;
      case 'Standby':
        statusLabel = l10n.statusStandby;
        break;
      default:
        statusLabel = l10n.statusCooldown;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: statusColor.withOpacity(0.6), blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        key.alias,
                        style: AppTypography.labelLg.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTypography.labelSm.copyWith(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons (Copy, Delete)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: key.maskedToken));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surfaceContainerHighest,
                          content: Text(
                            l10n.copiedTokenMessage(key.maskedToken),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    tooltip: l10n.copyMaskedTokenTooltip,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    color: AppColors.error,
                    onPressed: () => state.removeApiKey(key.id),
                    tooltip: l10n.deleteKeyTooltip,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            key.maskedToken,
            style: AppTypography.codeMono.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.rpmUsageLabel(
                  key.rpmUsage,
                  key.rpmMax,
                  ((key.rpmUsage / key.rpmMax) * 100).toInt(),
                ),
                style: AppTypography.bodySm.copyWith(fontSize: 11),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.latencyMsLabel(key.latencyMs),
                  style: AppTypography.codeMono.copyWith(
                    fontSize: 10,
                    color: AppColors.tertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
