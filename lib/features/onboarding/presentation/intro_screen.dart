import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/theme/flow_colors.dart';
import '../../../core/widgets/flow_buttons.dart';

/// Swipeable pager hosting Onboarding screens 02, 03, and 04.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, this.initialPage = 0});

  final int initialPage;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(0, 2);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/onboarding/personalize');
    }
  }

  void _onSkip() {
    context.go('/onboarding/personalize');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlowColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: Brand logo on left, Skip on right (hidden on page 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF181528),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: const Color(0xFF2E284A), width: 1),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.check_rounded, size: 14, color: FlowColors.primaryLight),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'FlowDay',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: _onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8E8BA7),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),

            // PageView for Screens 02, 03, 04
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildPage02(),
                  _buildPage03(),
                  _buildPage04(),
                ],
              ),
            ),

            // Bottom Section: Dots Pager + CTA Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Pager Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isSelected = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (_currentPage == 2 ? FlowColors.primary : Colors.white)
                              : const Color(0xFF2B283E),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Action Button: "Next ->" on pages 1 & 2; "Get Started ->" on page 3
                  if (_currentPage < 2)
                    FlowPrimaryButton(
                      label: 'Next ->',
                      isWhite: true,
                      onPressed: _onNext,
                    )
                  else
                    FlowPrimaryButton(
                      label: 'Get Started ->',
                      onPressed: _onNext,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Screen 02: Plan Your Day
  // ==========================================
  Widget _buildPage02() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Hero Mockup Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14131E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF26233B), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('TUESDAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF71717A))),
                        SizedBox(height: 2),
                        Text('May 14', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF221F36),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today_rounded, size: 16, color: FlowColors.primaryLight),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Week strip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _DateBadge(day: 'M', date: '13', isSelected: false),
                    _DateBadge(day: 'T', date: '14', isSelected: true),
                    _DateBadge(day: 'W', date: '15', isSelected: false),
                    _DateBadge(day: 'T', date: '16', isSelected: false),
                    _DateBadge(day: 'F', date: '17', isSelected: false),
                  ],
                ),
                const SizedBox(height: 14),

                // Task 1: Learn Flutter
                _TaskCardMini(
                  icon: Icons.code_rounded,
                  iconColor: FlowColors.catStudy,
                  title: 'Learn Flutter',
                  time: '09:00 - 10:00 AM',
                  bgColor: const Color(0xFF201D38),
                ),
                const SizedBox(height: 8),

                // Task 2: Workout
                _TaskCardMini(
                  icon: Icons.fitness_center_rounded,
                  iconColor: FlowColors.catWork,
                  title: 'Workout',
                  time: '06:00 - 07:00 PM',
                  bgColor: const Color(0xFF132B23),
                ),
                const SizedBox(height: 8),

                // Task 3: Coffee Break
                _TaskCardMini(
                  icon: Icons.coffee_rounded,
                  iconColor: FlowColors.catBreak,
                  title: 'Coffee break',
                  time: '11:00 - 11:30 AM',
                  bgColor: const Color(0xFF2E181B),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Headlines
          Text.rich(
            const TextSpan(
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2),
              children: [
                TextSpan(text: 'Plan your day\n', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'your way.', style: TextStyle(color: FlowColors.primaryLight)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Build a daily schedule in minutes. Organize every task, break and plan into a calm, clear timeline that fits how you actually live.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF), height: 1.45),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==========================================
  // Screen 03: Stay on Track
  // ==========================================
  Widget _buildPage03() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Hero Notification + Clock Graphic
          SizedBox(
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Concentric pulse circles
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: FlowColors.primary.withValues(alpha: 0.15), width: 1.5),
                  ),
                ),
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: FlowColors.primary.withValues(alpha: 0.3), width: 1.5),
                  ),
                ),
                // Clock Center
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141322),
                    shape: BoxShape.circle,
                    border: Border.all(color: FlowColors.primaryLight, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: FlowColors.primary.withValues(alpha: 0.25),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.alarm_rounded, size: 44, color: FlowColors.primaryLight),
                ),

                // Floating Notification Banner at top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191726),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2D2845), width: 1),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: FlowColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_active_rounded, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Time's up · Learn Flutter",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Your 60-min session is done. Did you finish?',
                                style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Text('now', style: TextStyle(fontSize: 10, color: Color(0xFF71717A))),
                      ],
                    ),
                  ),
                ),

                // Floating Progress Card at bottom
                Positioned(
                  bottom: 0,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181724),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2B2744), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle_rounded, color: FlowColors.success, size: 16),
                        SizedBox(width: 8),
                        Text('60% on track', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Headlines
          Text.rich(
            const TextSpan(
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2),
              children: [
                TextSpan(text: 'Stay on track,\n', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'effortlessly.', style: TextStyle(color: FlowColors.primaryLight)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "FlowDay gently lets you know the moment a task's time is up — so you can wrap up, check in, and move on without watching the clock.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF), height: 1.45),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==========================================
  // Screen 04: Plans Change, Schedule Adapts
  // ==========================================
  Widget _buildPage04() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Hero Adaptive Timeline Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151322),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF262142), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262046),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('🪄 Smart reschedule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FlowColors.primaryLight)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Item 1: Completed
                Row(
                  children: [
                    const Text('09:00', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B182E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle_rounded, color: FlowColors.success, size: 16),
                            SizedBox(width: 8),
                            Text('Morning run', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Item 2: Fixed Lunch (Locked)
                Row(
                  children: [
                    const Text('12:00', style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252044),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FlowColors.primary.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Lunch break 🔒', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FlowColors.primaryLight)),
                            Text('Fixed', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Floating Shifted Card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B1A1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Text('🎬 Movie with friends · 06:00 - 09:00 PM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: FlowColors.catSocial)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Headlines
          Text.rich(
            const TextSpan(
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2),
              children: [
                TextSpan(text: 'Plans change.\n', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'Your schedule adapts.', style: TextStyle(color: FlowColors.primaryLight)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ran over? Something new came up? FlowDay suggests smart shifts that protect your priorities and breaks — and never changes anything without asking.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF), height: 1.45),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.day, required this.date, required this.isSelected});
  final String day;
  final String date;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? FlowColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(day, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : const Color(0xFF71717A))),
          const SizedBox(height: 2),
          Text(date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

class _TaskCardMini extends StatelessWidget {
  const _TaskCardMini({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
    required this.bgColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}
