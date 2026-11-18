import 'package:material_ui/material_ui.dart';
import '../../core/theme/flow_colors.dart';
import '../../core/theme/flow_typography.dart';
import '../../core/widgets/flow_buttons.dart';
import '../../core/widgets/flow_chips.dart';
import '../../core/widgets/flow_card.dart';
import '../../core/widgets/flow_progress_ring.dart';
import '../../core/widgets/flow_task_tile.dart';
import '../../core/widgets/flow_toggle_row.dart';
import '../../core/widgets/flow_text_field.dart';
import '../../core/widgets/flow_bottom_sheet.dart';

/// Interactive Component & Token Gallery for Phase 1 verification.
class ComponentsGalleryScreen extends StatefulWidget {
  const ComponentsGalleryScreen({super.key});

  @override
  State<ComponentsGalleryScreen> createState() => _ComponentsGalleryScreenState();
}

class _ComponentsGalleryScreenState extends State<ComponentsGalleryScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Khushi');
  bool _toggleValue1 = true;
  bool _toggleValue2 = false;
  String _selectedPriority = 'Medium';
  String _selectedCategory = 'Study';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlowColors.background,
      appBar: AppBar(
        backgroundColor: FlowColors.background,
        elevation: 0,
        title: const Text('Design System Gallery', style: FlowTypography.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FlowColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FlowColors.primary.withValues(alpha: 0.4), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: FlowColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('PHASE 1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Tokens & Reusable Components', style: FlowTypography.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Compare all tokens and components below against the 24 screens in design/screens/.',
                  style: FlowTypography.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Uncertainty & Review Notes
          _buildSectionHeader('HEX VALUE ESTIMATES & UNCERTAINTIES'),
          const SizedBox(height: 12),
          _buildUncertaintiesCard(),
          const SizedBox(height: 28),

          // Screenshot vs Swatch Comparison
          _buildSectionHeader('COLOR SWATCHES VS DESIGN SCREENSHOTS'),
          const SizedBox(height: 8),
          const Text(
            'Compare extracted hex swatches side-by-side with original mockup screenshots.',
            style: FlowTypography.bodyMedium,
          ),
          const SizedBox(height: 12),
          _buildScreenshotsComparison(),
          const SizedBox(height: 28),

          // Section 1: Color Tokens
          _buildSectionHeader('1. COLOR TOKENS & SWATCHES'),
          const SizedBox(height: 12),
          _buildColorGroup('Backgrounds & Surfaces', [
            _ColorSwatch(name: 'background', hex: '#0B0B14', color: FlowColors.background, note: 'Near-black deep canvas'),
            _ColorSwatch(name: 'surface', hex: '#161426', color: FlowColors.surface, note: 'Default card background'),
            _ColorSwatch(name: 'surfaceElevated', hex: '#1D1B32', color: FlowColors.surfaceElevated, note: 'Selected / elevated tile'),
            _ColorSwatch(name: 'surfaceDark', hex: '#12101F', color: FlowColors.surfaceDark, note: 'Recessed input / button'),
            _ColorSwatch(name: 'surfaceBorder', hex: '#262244', color: FlowColors.surfaceBorder, note: 'Hairline 1px border'),
          ]),
          const SizedBox(height: 16),
          _buildColorGroup('Brand & Accents', [
            _ColorSwatch(name: 'primary', hex: '#7C6EF6', color: FlowColors.primary, note: 'Main active lavender purple'),
            _ColorSwatch(name: 'primaryLight', hex: '#9B8AFB', color: FlowColors.primaryLight, note: 'Text accent & glows'),
            _ColorSwatch(name: 'primaryContainer', hex: '#221F45', color: FlowColors.primaryContainer, note: 'Tinted container fill'),
          ]),
          const SizedBox(height: 16),
          _buildColorGroup('Semantic Status Colors', [
            _ColorSwatch(name: 'success', hex: '#10B981', color: FlowColors.success, note: 'Mint green (Done / On track)'),
            _ColorSwatch(name: 'warning', hex: '#F59E0B', color: FlowColors.warning, note: 'Amber (Medium / Streak)'),
            _ColorSwatch(name: 'error', hex: '#EF4444', color: FlowColors.error, note: 'Coral (High / Overdue / Clashes)'),
            _ColorSwatch(name: 'info', hex: '#60A5FA', color: FlowColors.info, note: 'Blue (Low priority / Shifted)'),
          ]),
          const SizedBox(height: 16),
          _buildColorGroup('Category Colors', [
            _ColorSwatch(name: 'catStudy', hex: '#818CF8', color: FlowColors.catStudy, note: 'Study (Indigo / Blue)'),
            _ColorSwatch(name: 'catWork', hex: '#34D399', color: FlowColors.catWork, note: 'Work (Mint)'),
            _ColorSwatch(name: 'catHealth', hex: '#F472B6', color: FlowColors.catHealth, note: 'Health (Pink)'),
            _ColorSwatch(name: 'catPersonal', hex: '#FBBF24', color: FlowColors.catPersonal, note: 'Personal (Warm Amber)'),
            _ColorSwatch(name: 'catSocial', hex: '#FB923C', color: FlowColors.catSocial, note: 'Social (Warm Coral)'),
            _ColorSwatch(name: 'catBreak', hex: '#D97706', color: FlowColors.catBreak, note: 'Break (Coffee / Ochre)'),
          ]),
          const SizedBox(height: 28),

          // Section 2: Buttons
          _buildSectionHeader('2. BUTTONS'),
          const SizedBox(height: 12),
          FlowPrimaryButton(
            label: 'Get Started ->',
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          FlowPrimaryButton(
            label: 'Next ->',
            isWhite: true,
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          FlowSecondaryButton(
            label: 'Cancel',
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FlowIconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              FlowIconButton(
                icon: const Icon(Icons.notifications_outlined, size: 20, color: Colors.white),
                badge: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: FlowColors.error, shape: BoxShape.circle),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              FlowIconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              FlowIconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: FlowColors.error),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Section 3: Priority & Status Chips
          _buildSectionHeader('3. CHIPS & BADGES'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FlowChip.priority(
                priority: 'Low',
                isSelected: _selectedPriority == 'Low',
                onTap: () => setState(() => _selectedPriority = 'Low'),
              ),
              FlowChip.priority(
                priority: 'Medium',
                isSelected: _selectedPriority == 'Medium',
                onTap: () => setState(() => _selectedPriority = 'Medium'),
              ),
              FlowChip.priority(
                priority: 'High',
                isSelected: _selectedPriority == 'High',
                onTap: () => setState(() => _selectedPriority = 'High'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FlowChip.status(label: '✓ 3 completed', color: FlowColors.success),
              FlowChip.status(label: '⭘ 5 pending', color: FlowColors.textSecondary),
              FlowChip.status(label: '⚠ 1 overdue', color: FlowColors.error),
              FlowChip.status(label: '• In progress', color: FlowColors.primaryLight),
              FlowChip.status(label: 'Protected', color: FlowColors.warning),
              FlowChip.status(label: 'Shifted', color: FlowColors.info),
              FlowChip.status(label: 'CARRIED OVER', color: FlowColors.warning),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryChip('Study', Icons.menu_book_rounded, FlowColors.catStudy),
              _buildCategoryChip('Work', Icons.work_outline_rounded, FlowColors.catWork),
              _buildCategoryChip('Health', Icons.favorite_outline_rounded, FlowColors.catHealth),
              _buildCategoryChip('Personal', Icons.person_outline_rounded, FlowColors.catPersonal),
              _buildCategoryChip('Break', Icons.coffee_rounded, FlowColors.catBreak),
            ],
          ),
          const SizedBox(height: 28),

          // Section 4: Progress Rings & Stat Tiles
          _buildSectionHeader('4. PROGRESS RING & STAT TILES'),
          const SizedBox(height: 12),
          FlowCard(
            child: Row(
              children: [
                const FlowProgressRing(
                  progress: 0.38,
                  size: 80,
                  centerText: '38%',
                  subtitle: 'today',
                  color: FlowColors.primary,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FlowChip.status(label: '• On track', color: FlowColors.success),
                      const SizedBox(height: 8),
                      const Text('3 of 8 tasks completed', style: FlowTypography.titleMedium),
                      const SizedBox(height: 4),
                      const Text("You're flowing nicely — keep it gentle.", style: FlowTypography.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: FlowStatTile(label: 'DONE', value: '3')),
              SizedBox(width: 8),
              Expanded(child: FlowStatTile(label: 'REMAINING', value: '5')),
              SizedBox(width: 8),
              Expanded(child: FlowStatTile(label: 'FOCUS', value: '1h 24m', accentColor: FlowColors.primaryLight)),
            ],
          ),
          const SizedBox(height: 28),

          // Section 5: Task Tiles
          _buildSectionHeader('5. TIMELINE TASK TILES'),
          const SizedBox(height: 12),
          FlowTaskTile(
            title: 'Morning run',
            timeRange: '07:00 – 07:30',
            duration: '30m',
            category: 'Health',
            categoryColor: FlowColors.catHealth,
            categoryIcon: Icons.directions_run_rounded,
            isCompleted: true,
          ),
          const SizedBox(height: 10),
          FlowTaskTile(
            title: 'Learn Flutter',
            timeRange: '09:00 – 10:00',
            duration: '60m',
            category: 'Study',
            categoryColor: FlowColors.catStudy,
            categoryIcon: Icons.code_rounded,
            isCurrent: true,
            statusBadge: FlowChip.status(label: 'In progress', color: FlowColors.primaryLight),
          ),
          const SizedBox(height: 10),
          FlowTaskTile(
            title: 'Practice DSA',
            timeRange: '10:00 – 11:00 AM',
            duration: '60m',
            category: 'Study',
            categoryColor: FlowColors.catStudy,
            categoryIcon: Icons.psychology_rounded,
            priority: 'High',
            statusBadge: FlowChip.status(label: 'Upcoming', color: FlowColors.textSecondary),
          ),
          const SizedBox(height: 10),
          FlowTaskTile(
            title: 'Break',
            timeRange: '11:00 – 11:30 AM',
            duration: '30m',
            category: 'Break',
            categoryColor: FlowColors.catBreak,
            categoryIcon: Icons.coffee_rounded,
            isBreak: true,
            statusBadge: FlowChip.status(label: 'Protected', color: FlowColors.warning),
          ),
          const SizedBox(height: 10),
          FlowTaskTile(
            title: 'Lunch with Aarav',
            timeRange: '12:30 – 01:30 PM',
            duration: '60m',
            category: 'Personal',
            categoryColor: FlowColors.catPersonal,
            categoryIcon: Icons.restaurant_rounded,
            isFixed: true,
            statusBadge: FlowChip.status(label: 'Fixed', color: FlowColors.info),
          ),
          const SizedBox(height: 28),

          // Section 6: Form Controls & Inputs
          _buildSectionHeader('6. FORM CONTROLS & INPUTS'),
          const SizedBox(height: 12),
          FlowTextField(
            controller: _nameController,
            hintText: 'Your name',
            prefixIcon: Icons.person_outline_rounded,
            suffixIcon: const Icon(Icons.check_circle_rounded, color: FlowColors.success, size: 20),
          ),
          const SizedBox(height: 12),
          FlowToggleRow(
            title: 'Task alarms',
            subtitle: "Full-screen alarm when time's up",
            icon: Icons.alarm_rounded,
            iconColor: FlowColors.primaryLight,
            value: _toggleValue1,
            onChanged: (val) => setState(() => _toggleValue1 = val),
          ),
          const SizedBox(height: 10),
          FlowToggleRow(
            title: 'Nightly schedule review',
            subtitle: 'A calm nudge at 09:30 PM',
            icon: Icons.nights_stay_rounded,
            iconColor: FlowColors.warning,
            value: _toggleValue2,
            onChanged: (val) => setState(() => _toggleValue2 = val),
          ),
          const SizedBox(height: 28),

          // Section 7: Bottom Sheet Trigger
          _buildSectionHeader('7. MODAL BOTTOM SHEET'),
          const SizedBox(height: 12),
          FlowSecondaryButton(
            label: 'Test Bottom Sheet',
            icon: const Icon(Icons.arrow_upward_rounded, size: 18),
            onPressed: () {
              FlowBottomSheetContainer.show(
                context: context,
                builder: (ctx) => Column(
                  children: [
                    const Text('This is a test bottom sheet container matching design specs.', style: FlowTypography.bodyLarge),
                    const SizedBox(height: 24),
                    FlowPrimaryButton(
                      label: 'Got it',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: FlowTypography.labelSmall.copyWith(
        color: FlowColors.primaryLight,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildUncertaintiesCard() {
    return FlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.help_outline_rounded, color: FlowColors.warning, size: 20),
              SizedBox(width: 8),
              Text('Extracted Hex Estimates & Uncertainties', style: FlowTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Because the design mockups are bitmap exports with antialiasing and gradients, these are our sampled hex values. Compare them on your phone against the screenshots below:',
            style: FlowTypography.bodyMedium,
          ),
          const SizedBox(height: 12),
          _uncertainItem('1. Canvas Background (#0B0B14)', 'Deep ink-indigo near black canvas. Screen 01 & 07 show a faint top-left violet glow. Unsure if pure OLED black (#000000) or #0D0C18 is preferred for battery saving.'),
          _uncertainItem('2. Card Surface (#161426) & Border (#262244)', 'Primary card container. Varies across mockups between #141224 and #18152B due to compression. 1px hairline border (#262244) separates cards from canvas.'),
          _uncertainItem('3. Brand Primary (#7C6EF6)', 'CTA button and progress ring lavender purple. Sub-pixel sampling ranges from #7562F8 to #8374FA.'),
          _uncertainItem('4. Focus Primary Container (#221F45)', 'Active focus banner fill on Screen 11. Dark tinted purple. Alternative: #25204C.'),
          _uncertainItem('5. Category Tag Opacities', 'Work (#34D399) and Study (#818CF8) tags use 15% opacity fills with solid colored text.'),
        ],
      ),
    );
  }

  Widget _uncertainItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: FlowTypography.titleMedium.copyWith(fontSize: 13, color: FlowColors.warning)),
          const SizedBox(height: 2),
          Text(desc, style: FlowTypography.bodyLarge.copyWith(fontSize: 11, color: FlowColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildScreenshotsComparison() {
    final comparisons = [
      {
        'title': 'Screen 07: Daily Command Center',
        'image': 'design/screens/07_home.png',
        'tokens': [
          _ColorSwatch(name: 'background', hex: '#0B0B14', color: FlowColors.background, note: 'Canvas'),
          _ColorSwatch(name: 'surface', hex: '#161426', color: FlowColors.surface, note: 'Card tile'),
          _ColorSwatch(name: 'primary', hex: '#7C6EF6', color: FlowColors.primary, note: 'Action CTA'),
          _ColorSwatch(name: 'success', hex: '#10B981', color: FlowColors.success, note: 'Done badge'),
        ],
      },
      {
        'title': 'Screen 08: Schedule Today',
        'image': 'design/screens/08_schedule_today.png',
        'tokens': [
          _ColorSwatch(name: 'catStudy', hex: '#818CF8', color: FlowColors.catStudy, note: 'Study tag'),
          _ColorSwatch(name: 'catWork', hex: '#34D399', color: FlowColors.catWork, note: 'Work tag'),
          _ColorSwatch(name: 'catBreak', hex: '#D97706', color: FlowColors.catBreak, note: 'Break badge'),
          _ColorSwatch(name: 'primaryLight', hex: '#9B8AFB', color: FlowColors.primaryLight, note: 'Now dot'),
        ],
      },
      {
        'title': 'Screen 11: Focus Mode',
        'image': 'design/screens/11_focus.png',
        'tokens': [
          _ColorSwatch(name: 'primaryContainer', hex: '#221F45', color: FlowColors.primaryContainer, note: 'Focus card'),
          _ColorSwatch(name: 'primary', hex: '#7C6EF6', color: FlowColors.primary, note: 'Play ring'),
          _ColorSwatch(name: 'surfaceBorder', hex: '#262244', color: FlowColors.surfaceBorder, note: 'Ring border'),
        ],
      },
      {
        'title': 'Screen 23: Insights',
        'image': 'design/screens/23_insights.png',
        'tokens': [
          _ColorSwatch(name: 'warning', hex: '#F59E0B', color: FlowColors.warning, note: 'Streak flame'),
          _ColorSwatch(name: 'primary', hex: '#7C6EF6', color: FlowColors.primary, note: 'Productivity bar'),
          _ColorSwatch(name: 'surfaceElevated', hex: '#1D1B32', color: FlowColors.surfaceElevated, note: 'Stat card'),
        ],
      },
      {
        'title': 'Screen 24: Settings',
        'image': 'design/screens/24_settings.png',
        'tokens': [
          _ColorSwatch(name: 'surfaceDark', hex: '#12101F', color: FlowColors.surfaceDark, note: 'Toggle track off'),
          _ColorSwatch(name: 'textSecondary', hex: '#8E8BA7', color: FlowColors.textSecondary, note: 'Subtitle'),
          _ColorSwatch(name: 'primary', hex: '#7C6EF6', color: FlowColors.primary, note: 'Toggle active'),
        ],
      },
    ];

    return Column(
      children: comparisons.map((comp) {
        final title = comp['title'] as String;
        final imagePath = comp['image'] as String;
        final tokens = comp['tokens'] as List<_ColorSwatch>;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FlowCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: FlowTypography.titleMedium),
                    const Text('Tap image to zoom', style: TextStyle(fontSize: 10, color: FlowColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(16),
                            child: InteractiveViewer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(imagePath, fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 100,
                          height: 180,
                          color: FlowColors.surfaceDark,
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Center(
                              child: Icon(Icons.broken_image_rounded, color: FlowColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: tokens.map((swatch) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: swatch.color,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: FlowColors.surfaceBorder, width: 1),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(swatch.name, style: FlowTypography.titleMedium.copyWith(fontSize: 12)),
                                    Text('${swatch.hex} (${swatch.note})', style: FlowTypography.bodyMedium.copyWith(fontSize: 10, color: FlowColors.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorGroup(String groupName, List<_ColorSwatch> swatches) {
    return FlowCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(groupName, style: FlowTypography.titleMedium),
          const SizedBox(height: 10),
          ...swatches.map((swatch) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: swatch.color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FlowColors.surfaceBorder, width: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(swatch.name, style: FlowTypography.titleMedium.copyWith(fontSize: 13)),
                              const SizedBox(width: 8),
                              Text(swatch.hex, style: FlowTypography.bodyMedium.copyWith(fontSize: 12, color: FlowColors.textMuted)),
                            ],
                          ),
                          Text(swatch.note, style: FlowTypography.bodyLarge.copyWith(fontSize: 11, color: FlowColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String name, IconData icon, Color color) {
    final isSelected = _selectedCategory == name;
    return FlowChip(
      label: name,
      isSelected: isSelected,
      icon: Icon(icon, size: 14, color: isSelected ? const Color(0xFF0B0B14) : color),
      onTap: () => setState(() => _selectedCategory = name),
    );
  }
}

class _ColorSwatch {
  _ColorSwatch({
    required this.name,
    required this.hex,
    required this.color,
    required this.note,
  });

  final String name;
  final String hex;
  final Color color;
  final String note;
}
