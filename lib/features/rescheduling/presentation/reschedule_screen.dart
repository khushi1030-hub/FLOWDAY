import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/core/theme/flow_colors.dart';
import 'package:flow_day/core/theme/flow_typography.dart';
import 'package:flow_day/core/utils/time_utils.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import '../domain/entities/reschedule_proposal.dart';
import 'providers/reschedule_providers.dart';

/// Screen 16: Smart Rescheduling (and Screen 19: New Plan Conflict Variant).
///
/// Features:
/// - Side-by-side Before & After timeline comparison with legend (Fixed, Flexible, Protected)
/// - Multi-plan proposal selection (Plan A Recommended, Plan B, Plan C, Plan D)
/// - Conflict clash preview & resolution options (Screen 19)
/// - Atomic transactional apply & undo integration
class RescheduleScreen extends ConsumerStatefulWidget {
  const RescheduleScreen({
    super.key,
    this.taskId,
    this.extraMinutes = 30,
    this.newConflictingTask,
    this.dateKey,
  });

  final String? taskId;
  final int extraMinutes;
  final Task? newConflictingTask;
  final String? dateKey;

  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
  late final RescheduleScreenParams _params;

  @override
  void initState() {
    super.initState();
    _params = RescheduleScreenParams(
      triggerTaskId: widget.taskId,
      extraMinutes: widget.extraMinutes,
      newConflictingTask: widget.newConflictingTask,
      dateKey: widget.dateKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final proposalsAsync = ref.watch(rescheduleProposalsProvider(_params));
    final selectedId = ref.watch(selectedProposalIdProvider);
    final isConflictVariant = _params.isConflictVariant;

    return Scaffold(
      backgroundColor: FlowColors.background,
      body: SafeArea(
        child: proposalsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: FlowColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: FlowColors.error),
                  const SizedBox(height: 16),
                  Text('Failed to calculate proposals', style: FlowTypography.titleMedium),
                  const SizedBox(height: 8),
                  Text(err.toString(), style: FlowTypography.bodySmall, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: FlowColors.primary),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
          data: (proposals) {
            if (proposals.isEmpty) {
              return const Center(child: Text('No proposals available', style: FlowTypography.bodyMedium));
            }

            final activeProposal = proposals.firstWhere(
              (p) => p.id == selectedId,
              orElse: () => proposals.first,
            );

            return Column(
              children: [
                // Top App Bar
                _buildTopAppBar(context, isConflictVariant),

                // Main Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isConflictVariant) ...[
                          // Screen 19: Target Plan Card & Conflict Warning
                          _buildTargetPlanCard(widget.newConflictingTask!),
                          const SizedBox(height: 16),
                          _buildConflictClashCard(widget.newConflictingTask!, activeProposal),
                        ] else ...[
                          // Screen 16: Hero Card
                          _buildHeroCard(activeProposal),
                          const SizedBox(height: 24),

                          // Screen 16: Before & After Timeline Section
                          _buildBeforeAfterSection(activeProposal),
                        ],

                        const SizedBox(height: 24),

                        // Plan Choices / Recommendations Section
                        Text(
                          isConflictVariant ? 'Recommendations' : 'Choose a plan',
                          style: FlowTypography.headlineMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),

                        // List of proposal option cards
                        ...proposals.map((proposal) {
                          final isSelected = proposal.id == activeProposal.id;
                          return _buildPlanCard(proposal, isSelected);
                        }),

                        const SizedBox(height: 16),

                        // Impact Summary Banner
                        _buildImpactSummaryBanner(activeProposal.impactSummary),

                        const SizedBox(height: 16),

                        // Footer Safety Note
                        _buildFooterSafetyNote(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                _buildBottomActionBar(context, activeProposal, isConflictVariant),
              ],
            );
          },
        ),
      ),
    );
  }

  void _safePop([dynamic result]) {
    try {
      if (context.canPop()) {
        context.pop(result);
        return;
      }
    } catch (_) {}
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  /// Top app bar with back button, title, and action icon.
  Widget _buildTopAppBar(BuildContext context, bool isConflict) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _safePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: FlowColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: FlowColors.surfaceBorder, width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: FlowColors.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isConflict ? 'New plan' : 'Smart Rescheduling',
              style: FlowTypography.headlineMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FlowColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 20, color: FlowColors.primaryLight),
          ),
        ],
      ),
    );
  }

  /// Hero Card for Screen 16.
  Widget _buildHeroCard(RescheduleProposal activeProposal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B182B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2E2A4A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: FlowColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FlowColors.primary.withValues(alpha: 0.4), width: 1),
            ),
            child: Text(
              '⌛ +${widget.extraMinutes} min needed',
              style: FlowTypography.labelMedium.copyWith(color: FlowColors.primaryLight, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your task needs more time. Let\'s protect the rest of your day.',
            style: FlowTypography.headlineMedium.copyWith(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            'Extending it overlaps scheduled tasks. Fixed appointments and breaks won\'t move.',
            style: FlowTypography.bodyMedium.copyWith(color: FlowColors.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  /// Screen 19 Target Plan Card.
  Widget _buildTargetPlanCard(Task task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF23161A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF482028), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FlowColors.catSocial.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.movie_rounded, color: FlowColors.catSocial, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: FlowTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${TimeUtils.formatMinutesToTime(task.startMin)} - ${TimeUtils.formatMinutesToTime(task.endMin)} · ${task.durationMin}m',
                  style: FlowTypography.bodySmall.copyWith(color: FlowColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniChip('Fixed 🔒', FlowColors.textMuted),
                    const SizedBox(width: 6),
                    _buildMiniChip('Social', FlowColors.catSocial),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Screen 19 Conflict Warning Card.
  Widget _buildConflictClashCard(Task newPlan, RescheduleProposal activeProposal) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.warning_amber_rounded, size: 20, color: FlowColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your new plan conflicts with scheduled tasks.',
                  style: FlowTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pick a fix below — nothing changes until you confirm.',
            style: FlowTypography.bodySmall.copyWith(color: FlowColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Section "Before & after" for Screen 16.
  Widget _buildBeforeAfterSection(RescheduleProposal activeProposal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Before & after',
              style: FlowTypography.headlineMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Row(
              children: [
                Text('🔒 Fixed', style: FlowTypography.labelSmall.copyWith(color: FlowColors.textMuted, fontSize: 11)),
                const SizedBox(width: 8),
                Text('↕ Flexible', style: FlowTypography.labelSmall.copyWith(color: FlowColors.textMuted, fontSize: 11)),
                const SizedBox(width: 8),
                Text('🛡 Protected', style: FlowTypography.labelSmall.copyWith(color: FlowColors.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Timeline Comparison Grid (Before vs After)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Before Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Before', style: FlowTypography.labelMedium.copyWith(color: FlowColors.textMuted)),
                  const SizedBox(height: 8),
                  ...activeProposal.moves.map((m) {
                    final isTrigger = m.taskId == widget.taskId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isTrigger ? const Color(0xFF201D38) : const Color(0xFF161424),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTrigger ? FlowColors.primary.withValues(alpha: 0.4) : const Color(0xFF262244),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TimeUtils.formatMinutesToTime(m.oldStartMin),
                            style: FlowTypography.labelSmall.copyWith(color: FlowColors.textSecondary, fontSize: 10),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.taskTitle,
                            style: FlowTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // After Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('After', style: FlowTypography.labelMedium.copyWith(color: FlowColors.primaryLight, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...activeProposal.moves.map((m) {
                    final isTrigger = m.taskId == widget.taskId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isTrigger ? FlowColors.primary.withValues(alpha: 0.25) : const Color(0xFF1B182B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTrigger ? FlowColors.primary : const Color(0xFF332F52),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${TimeUtils.formatMinutesToTime(m.newStartMin)} - ${TimeUtils.formatMinutesToTime(m.newEndMin)}',
                                style: FlowTypography.labelSmall.copyWith(
                                  color: isTrigger ? FlowColors.primaryLight : FlowColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                              if (m.isShifted)
                                Text(
                                  m.isDifferentDate ? 'Tomorrow' : '+${m.shiftMinutes}m',
                                  style: FlowTypography.labelSmall.copyWith(
                                    color: FlowColors.warning,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.taskTitle,
                            style: FlowTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isTrigger ? Colors.white : FlowColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Selectable Plan Card (Plan A, B, C, D).
  Widget _buildPlanCard(RescheduleProposal proposal, bool isSelected) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedProposalIdProvider.notifier).state = proposal.id;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF221F45) : const Color(0xFF161424),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? FlowColors.primary : const Color(0xFF262244),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge / Letter (A, B, C, D)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? FlowColors.primary : const Color(0xFF201D38),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                proposal.id,
                style: TextStyle(
                  color: isSelected ? Colors.white : FlowColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Plan details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          proposal.title,
                          style: FlowTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (proposal.badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: FlowColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: FlowColors.success.withValues(alpha: 0.4), width: 1),
                          ),
                          child: Text(
                            proposal.badgeText!,
                            style: FlowTypography.labelSmall.copyWith(
                              color: FlowColors.success,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    proposal.subtitle,
                    style: FlowTypography.bodySmall.copyWith(
                      color: FlowColors.textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Positive impact banner.
  Widget _buildImpactSummaryBanner(String summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF102B21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1D4A3A), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: FlowColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summary,
              style: FlowTypography.bodySmall.copyWith(color: const Color(0xFF6EE7B7), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Footer Safety Note.
  Widget _buildFooterSafetyNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_outlined, size: 14, color: FlowColors.textMuted),
        const SizedBox(width: 6),
        Text(
          'Nothing is deleted or moved without your approval.',
          style: FlowTypography.labelSmall.copyWith(color: FlowColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  /// Bottom action bar.
  Widget _buildBottomActionBar(
    BuildContext context,
    RescheduleProposal activeProposal,
    bool isConflictVariant,
  ) {
    final actionState = ref.watch(rescheduleActionProvider);
    final isApplying = actionState.isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: FlowColors.background,
        border: Border(top: BorderSide(color: FlowColors.surfaceBorder, width: 1)),
      ),
      child: Row(
        children: [
          if (isConflictVariant) ...[
            // "Keep overlap" option per Decision D3
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: isApplying ? null : () => _keepOverlap(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: FlowColors.surfaceBorder, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: Text('Keep overlap', style: FlowTypography.bodyLarge.copyWith(color: FlowColors.textSecondary)),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isApplying || !activeProposal.isValid ? null : () => _applyProposal(context, activeProposal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlowColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  elevation: 0,
                ),
                child: isApplying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        isConflictVariant ? 'Apply & Save' : 'Apply Plan ${activeProposal.id}',
                        style: FlowTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Commits the selected proposal transactionally.
  Future<void> _applyProposal(BuildContext context, RescheduleProposal proposal) async {
    try {
      await ref.read(rescheduleActionProvider.notifier).applyProposal(
            proposal: proposal,
            reason: widget.newConflictingTask != null ? 'conflict' : 'extra_time',
            triggerTaskId: widget.taskId ?? widget.newConflictingTask?.id,
          );

      if (!context.mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      _safePop(true);

      // Trigger SnackBar with functional Undo
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Schedule updated'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Undo',
            textColor: FlowColors.primaryLight,
            onPressed: () async {
              try {
                await ref.read(rescheduleActionProvider.notifier).undoLatestBatch();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Reschedule undone')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Cannot undo: ${e.toString()}')),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply schedule: ${e.toString()}'), backgroundColor: FlowColors.error),
      );
    }
  }

  /// Decision D3: Keep overlap.
  Future<void> _keepOverlap(BuildContext context) async {
    if (widget.newConflictingTask == null) return;
    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      final flaggedNew = widget.newConflictingTask!.copyWith(hasConflict: true);
      await taskRepo.insertTask(flaggedNew);

      if (!context.mounted) return;
      _safePop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added with conflict flag')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving task: ${e.toString()}')),
      );
    }
  }

  Widget _buildMiniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: FlowTypography.labelSmall.copyWith(color: color, fontSize: 10)),
    );
  }
}
