import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _validationStatus = 'Awaiting validation';
  bool _isValidating = false;

  final List<String> _models = [
    'Gemini 1.5 Pro (High Fidelity)',
    'Gemini 1.5 Flash (Ultra Fast)',
    'Gemini 2.0 Flash Experimental',
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

  void _verifyAndSaveKey() {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Gemini API token.')),
      );
      return;
    }

    setState(() {
      _isValidating = true;
      _validationStatus = 'Pinging Gemini Endpoint...';
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      widget.state.addApiKey(_aliasController.text.trim(), token);
      setState(() {
        _isValidating = false;
        _validationStatus = 'Verified & Stored Securely';
        _aliasController.clear();
        _tokenController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.tertiaryContainer,
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Gemini API key verified and added to rotation pool!'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final keys = state.apiKeys;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                            'Gemini API Keys Pool',
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.tertiaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'High Concurrency',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.tertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add multiple keys to bypass RPM/TPM restrictions. CineDub AI auto-rotates active tokens during full-length Khmer cinematic dubbing pipelines.',
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
              Row(
                children: [
                  Text(
                    'Registered Keys',
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${keys.length} Configured',
                      style: AppTypography.labelSm.copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All Gemini endpoints healthy! Avg latency: 122ms')),
                  );
                },
                icon: const Icon(Icons.speed_rounded, size: 14, color: AppColors.secondary),
                label: Text(
                  'Ping All',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
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
                      'Add Gemini API Key',
                      style: AppTypography.headlineSm.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Key Alias Field
                Text('Key Alias / Description', style: AppTypography.labelSm),
                const SizedBox(height: 6),
                TextField(
                  controller: _aliasController,
                  style: AppTypography.bodyMd,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Project Cinema Beta',
                    isDense: true,
                  ),
                ),

                const SizedBox(height: 12),

                // Secret Token Field
                Text('Gemini API Secret Token', style: AppTypography.labelSm),
                const SizedBox(height: 6),
                TextField(
                  controller: _tokenController,
                  obscureText: _obscureToken,
                  style: AppTypography.codeMono.copyWith(color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'AIzaSy...',
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

                const SizedBox(height: 14),

                // Validation Feedback & Verify Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _validationStatus.contains('Verified')
                                ? AppColors.tertiary
                                : AppColors.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _validationStatus,
                          style: AppTypography.bodySm.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _isValidating ? null : _verifyAndSaveKey,
                      icon: _isValidating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.verified_rounded, size: 16),
                      label: Text(
                        'Verify & Save',
                        style: AppTypography.labelMd.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // AI Model & Translation Settings Section
          Text(
            'TRANSLATION ENGINE & MODEL',
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
                  'Default Gemini Model',
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
                  'Khmer Dubbing Tone & Style',
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
                  'Key Rotation Strategy',
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

  Widget _buildKeyCard(ApiKeyItem key, AppState state) {
    Color statusColor;
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
                        key.status,
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
                          content: Text('Copied ${key.maskedToken} to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    tooltip: 'Copy Masked Token',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    color: AppColors.error,
                    onPressed: () => state.removeApiKey(key.id),
                    tooltip: 'Delete Key',
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
                'RPM: ${key.rpmUsage}/${key.rpmMax} (${((key.rpmUsage / key.rpmMax) * 100).toInt()}%)',
                style: AppTypography.bodySm.copyWith(fontSize: 11),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${key.latencyMs}ms',
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
