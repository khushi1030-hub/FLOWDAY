import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/constants/audio_assets.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/flow_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/flow_buttons.dart';

/// Screen 05: Personalize Your Flow
class PersonalizeScreen extends ConsumerStatefulWidget {
  const PersonalizeScreen({super.key});

  @override
  ConsumerState<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends ConsumerState<PersonalizeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Settings values with defaults
  int _wakeMin = 420; // 07:00 AM
  int _sleepMin = 1380; // 11:00 PM (23:00)
  int _nightlyMin = 1290; // 09:30 PM (21:30) per D6
  String _selectedSound = 'Soft Chime';
  int _defaultBreakMin = 15;

  String? _currentlyPlayingSound;
  String? _errorMessage;

  static const List<Map<String, String>> _sounds = [
    {'name': 'Soft Chime', 'asset': AudioAssets.softChime},
    {'name': 'Morning Breeze', 'asset': AudioAssets.morningBreeze},
    {'name': 'Crystal Bell', 'asset': AudioAssets.crystalBell},
    {'name': 'Lo-fi Piano', 'asset': AudioAssets.lofiPiano},
  ];

  static const List<int> _breakOptions = [5, 10, 15, 20, 30];

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _currentlyPlayingSound = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _previewSound(String name, String assetPath) async {
    try {
      if (_currentlyPlayingSound == name) {
        await _audioPlayer.stop();
        setState(() => _currentlyPlayingSound = null);
        return;
      }

      await _audioPlayer.stop();
      setState(() => _currentlyPlayingSound = name);
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.play();
    } catch (_) {
      if (mounted) {
        setState(() => _currentlyPlayingSound = null);
      }
    }
  }

  Future<void> _pickTime({
    required int initialMinutes,
    required void Function(int newMinutes) onSelected,
  }) async {
    final initialTime = TimeUtils.minutesToTimeOfDay(initialMinutes);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: FlowColors.primary,
              onPrimary: Colors.white,
              surface: FlowColors.surface,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: FlowColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newMin = TimeUtils.timeOfDayToMinutes(picked);
      onSelected(newMin);
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _onContinue() async {
    final name = _nameController.text.trim();

    // 1. Name validation
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name to personalize your schedule.');
      return;
    }

    // 2. Daily rhythm & nightly review validation (supports overnight sleep schedules)
    final rhythmError = TimeUtils.validateRhythm(
      wakeMin: _wakeMin,
      sleepMin: _sleepMin,
      nightlyMin: _nightlyMin,
    );
    if (rhythmError != null) {
      setState(() => _errorMessage = rhythmError);
      return;
    }

    // Save through SettingsRepository
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final current = await settingsRepo.getSettings();

    await settingsRepo.updateSettings(
      current.copyWith(
        userName: name,
        wakeMin: _wakeMin,
        sleepMin: _sleepMin,
        dayStartMin: _wakeMin,
        dayEndMin: _sleepMin,
        nightlyReviewMin: _nightlyMin,
        notificationSound: _selectedSound,
        defaultBreakMin: _defaultBreakMin,
      ),
    );

    // Stop audio before navigating
    await _audioPlayer.stop();

    if (mounted) {
      context.go('/onboarding/permissions');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNameValid = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: FlowColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back button, 50% progress line, "1 of 2"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                    onPressed: () => context.go('/onboarding/3'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 4,
                        color: const Color(0xFF262244),
                        child: Row(
                          children: [
                            Expanded(child: Container(color: FlowColors.primary)),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text('1 of 2', style: TextStyle(fontSize: 12, color: Color(0xFF71717A), fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Header
                  const Text(
                    "Let's personalize\nyour flow ✨",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A few details help FlowDay plan around your real rhythm. You can change these anytime.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // Validation Error Banner if present
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: FlowColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FlowColors.error, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: FlowColors.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // SECTION: YOUR NAME
                  const Text(
                    'YOUR NAME',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161424),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isNameValid ? FlowColors.success : const Color(0xFF2A2640),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: FlowColors.primaryLight, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            onChanged: (_) => setState(() => _errorMessage = null),
                            style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
                            cursorColor: FlowColors.primaryLight,
                            decoration: const InputDecoration(
                              hintText: 'Your name',
                              hintStyle: TextStyle(fontSize: 15, color: Color(0xFF6B6882)),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (isNameValid)
                          const Icon(Icons.check_circle_rounded, color: FlowColors.success, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SECTION: DAILY RHYTHM
                  const Text(
                    'DAILY RHYTHM',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Wake-up Time
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickTime(
                            initialMinutes: _wakeMin,
                            onSelected: (min) => setState(() => _wakeMin = min),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161424),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF262244), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: FlowColors.warning.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.wb_sunny_rounded, color: FlowColors.warning, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Wake-up', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  TimeUtils.formatMinutesToTime(_wakeMin),
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Sleeping Time
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickTime(
                            initialMinutes: _sleepMin,
                            onSelected: (min) => setState(() => _sleepMin = min),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161424),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF262244), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: FlowColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.nightlight_round, color: FlowColors.primaryLight, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Sleeping', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  TimeUtils.formatMinutesToTime(_sleepMin),
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // SECTION: NIGHTLY PLANNING REMINDER
                  const Text(
                    'NIGHTLY PLANNING REMINDER',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickTime(
                      initialMinutes: _nightlyMin,
                      onSelected: (min) => setState(() => _nightlyMin = min),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161424),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF262244), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: FlowColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.nights_stay_rounded, color: FlowColors.primaryLight, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  TimeUtils.formatMinutesToTime(_nightlyMin),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "We'll ask you to review tomorrow",
                                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF71717A), size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SECTION: NOTIFICATION SOUND
                  const Text(
                    'NOTIFICATION SOUND',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161424),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF262244), width: 1),
                    ),
                    child: Column(
                      children: _sounds.map((sound) {
                        final name = sound['name']!;
                        final asset = sound['asset']!;
                        final isSelected = _selectedSound == name;
                        final isPlaying = _currentlyPlayingSound == name;

                        return InkWell(
                          onTap: () => setState(() => _selectedSound = name),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                // Play preview button
                                GestureDetector(
                                  onTap: () => _previewSound(name, asset),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isPlaying ? FlowColors.primary : const Color(0xFF221F36),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                      size: 18,
                                      color: isPlaying ? Colors.white : FlowColors.primaryLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                                // Custom radio dot
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? FlowColors.primary : const Color(0xFF4B4868),
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: isSelected
                                      ? Container(
                                          width: 9,
                                          height: 9,
                                          decoration: const BoxDecoration(
                                            color: FlowColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SECTION: DEFAULT BREAK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'DEFAULT BREAK',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 1.2),
                      ),
                      Text('between tasks', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _breakOptions.map((min) {
                      final isSelected = _defaultBreakMin == min;
                      return GestureDetector(
                        onTap: () => setState(() => _defaultBreakMin = min),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFF161424),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? Colors.white : const Color(0xFF262244),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${min}m',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF0B0B14) : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Continue Button
                  FlowPrimaryButton(
                    label: 'Continue',
                    onPressed: _onContinue,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
