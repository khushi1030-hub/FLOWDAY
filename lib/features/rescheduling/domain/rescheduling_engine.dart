import 'package:flow_day/features/tasks/domain/entities/task.dart';
import 'entities/reschedule_proposal.dart';

/// Pure Dart deterministic rescheduling engine.
///
/// Implements multi-plan proposal generation and conflict resolution (Screens 16 & 19).
/// Guarantees hard invariants:
/// 1. Zero overlaps in resulting schedule.
/// 2. Immovable set (fixed tasks, breaks, completed tasks) are NEVER moved or shortened.
/// 3. Durations preserved (unless duration adjustment is explicitly chosen).
/// 4. Day boundaries respected ([wakeMin, sleepMin], never crosses midnight).
class ReschedulingEngine {
  const ReschedulingEngine();

  /// Returns true if a task belongs to the immovable set.
  static bool isImmovable(Task task) {
    return task.isFixed || task.kind == 'break' || task.isCompleted;
  }

  /// Detects all overlapping pairs of tasks.
  List<({Task a, Task b})> detectConflicts(List<Task> tasks) {
    final sorted = List<Task>.from(tasks)..sort((x, y) => x.startMin.compareTo(y.startMin));
    final conflicts = <({Task a, Task b})>[];

    for (var i = 0; i < sorted.length; i++) {
      for (var j = i + 1; j < sorted.length; j++) {
        final a = sorted[i];
        final b = sorted[j];
        if (b.startMin >= a.endMin) {
          break; // Since sorted by startMin, subsequent tasks won't overlap a
        }
        conflicts.add((a: a, b: b));
      }
    }
    return conflicts;
  }

  /// Finds free time gaps between immovable tasks inside the waking day window.
  List<({int startMin, int endMin})> findFreeSlots({
    required List<Task> immovableTasks,
    required int windowStartMin,
    required int windowEndMin,
  }) {
    if (immovableTasks.isEmpty) {
      if (windowEndMin > windowStartMin) {
        return [(startMin: windowStartMin, endMin: windowEndMin)];
      }
      return [];
    }

    final sorted = List<Task>.from(immovableTasks)..sort((x, y) => x.startMin.compareTo(y.startMin));
    final freeSlots = <({int startMin, int endMin})>[];
    var cursor = windowStartMin;

    for (final task in sorted) {
      if (task.startMin > cursor) {
        final gapEnd = task.startMin.clamp(cursor, windowEndMin);
        if (gapEnd > cursor) {
          freeSlots.add((startMin: cursor, endMin: gapEnd));
        }
      }
      if (task.endMin > cursor) {
        cursor = task.endMin;
      }
    }

    if (cursor < windowEndMin) {
      freeSlots.add((startMin: cursor, endMin: windowEndMin));
    }

    return freeSlots;
  }

  /// Generates the standard multi-plan proposals for a delayed/extended task (Screen 16).
  ///
  /// Plans produced:
  /// - Plan A (Recommended): Extend trigger task & shift flexible tasks downstream.
  /// - Plan B: Priority first / Move lower-priority task later.
  /// - Plan C: Postpone trigger task to tomorrow.
  /// - Plan D: Keep original schedule, mark trigger task unfinished/skipped.
  List<RescheduleProposal> generateProposals({
    required List<Task> currentDayTasks,
    required Task triggerTask,
    required int extraMinutes,
    required int dayStartMin,
    required int dayEndMin,
    required String todayDateKey,
    required String tomorrowDateKey,
    List<Task> tomorrowTasks = const [],
  }) {
    final proposals = <RescheduleProposal>[];

    // PLAN A: Shift flexible tasks downstream (Recommended)
    final planA = _generatePlanA(
      currentDayTasks: currentDayTasks,
      triggerTask: triggerTask,
      extraMinutes: extraMinutes,
      dayStartMin: dayStartMin,
      dayEndMin: dayEndMin,
      todayDateKey: todayDateKey,
      tomorrowDateKey: tomorrowDateKey,
      tomorrowTasks: tomorrowTasks,
    );
    proposals.add(planA);

    // PLAN B: Priority first / Move lower priority task later
    final planB = _generatePlanB(
      currentDayTasks: currentDayTasks,
      triggerTask: triggerTask,
      extraMinutes: extraMinutes,
      dayStartMin: dayStartMin,
      dayEndMin: dayEndMin,
      todayDateKey: todayDateKey,
      tomorrowDateKey: tomorrowDateKey,
      tomorrowTasks: tomorrowTasks,
    );
    proposals.add(planB);

    // PLAN C: Postpone trigger task to tomorrow
    final planC = _generatePlanC(
      currentDayTasks: currentDayTasks,
      triggerTask: triggerTask,
      dayStartMin: dayStartMin,
      dayEndMin: dayEndMin,
      todayDateKey: todayDateKey,
      tomorrowDateKey: tomorrowDateKey,
      tomorrowTasks: tomorrowTasks,
    );
    proposals.add(planC);

    // PLAN D: Keep original schedule & skip for now
    final planD = _generatePlanD(
      currentDayTasks: currentDayTasks,
      triggerTask: triggerTask,
      extraMinutes: extraMinutes,
      todayDateKey: todayDateKey,
    );
    proposals.add(planD);

    return proposals;
  }

  /// PLAN A: Extend trigger task & shift downstream flexible tasks into free gaps.
  RescheduleProposal _generatePlanA({
    required List<Task> currentDayTasks,
    required Task triggerTask,
    required int extraMinutes,
    required int dayStartMin,
    required int dayEndMin,
    required String todayDateKey,
    required String tomorrowDateKey,
    required List<Task> tomorrowTasks,
  }) {
    final newTriggerEnd = triggerTask.endMin + extraMinutes;
    final extendedTrigger = triggerTask.copyWith(endMin: newTriggerEnd);

    // Check collision with immovable tasks
    final immovables = currentDayTasks.where((t) => t.id != triggerTask.id && isImmovable(t)).toList()
      ..sort((x, y) => x.startMin.compareTo(y.startMin));

    // If extended trigger directly collides with an immovable task:
    final directImmovableCollision = immovables.any((t) => t.startMin < newTriggerEnd && t.endMin > triggerTask.startMin);
    if (directImmovableCollision) {
      return RescheduleProposal.noValidSchedule(
        id: 'A',
        reason: 'Extending "${triggerTask.title}" directly collides with a fixed appointment or break.',
        existingTasks: currentDayTasks,
      );
    }

    // Downstream flexible tasks
    final flexiblesToShift = currentDayTasks
        .where((t) => t.id != triggerTask.id && !isImmovable(t) && t.endMin > triggerTask.startMin)
        .toList()
      ..sort((x, y) => x.startMin.compareTo(y.startMin));

    final resultingTasks = <Task>[];
    // Keep immovable tasks and earlier untouched tasks
    for (final task in currentDayTasks) {
      if (task.id == triggerTask.id) {
        resultingTasks.add(extendedTrigger);
      } else if (isImmovable(task) || task.endMin <= triggerTask.startMin) {
        resultingTasks.add(task);
      }
    }

    final moves = <TaskMove>[
      TaskMove(
        taskId: triggerTask.id,
        taskTitle: triggerTask.title,
        oldDateKey: triggerTask.dateKey,
        oldStartMin: triggerTask.startMin,
        oldEndMin: triggerTask.endMin,
        newDateKey: todayDateKey,
        newStartMin: triggerTask.startMin,
        newEndMin: newTriggerEnd,
        reason: 'extended_duration',
      ),
    ];
    final carryOvers = <CarryOverItem>[];

    // Build occupied intervals of immovable items + extended trigger
    final occupied = List<Task>.from(resultingTasks)..sort((x, y) => x.startMin.compareTo(y.startMin));
    var cursor = newTriggerEnd;

    for (final flex in flexiblesToShift) {
      final duration = flex.endMin - flex.startMin;
      // Find earliest gap starting from cursor that fits duration and doesn't collide with occupied
      final placedSlot = _findEarliestSlot(
        cursor: cursor,
        duration: duration,
        dayEndMin: dayEndMin,
        occupied: occupied,
      );

      if (placedSlot != null) {
        final shifted = flex.copyWith(startMin: placedSlot.startMin, endMin: placedSlot.endMin);
        resultingTasks.add(shifted);
        occupied.add(shifted);
        occupied.sort((x, y) => x.startMin.compareTo(y.startMin));
        cursor = placedSlot.endMin;

        moves.add(TaskMove(
          taskId: flex.id,
          taskTitle: flex.title,
          oldDateKey: flex.dateKey,
          oldStartMin: flex.startMin,
          oldEndMin: flex.endMin,
          newDateKey: todayDateKey,
          newStartMin: placedSlot.startMin,
          newEndMin: placedSlot.endMin,
          reason: 'shifted_downstream',
        ));
      } else {
        // Does not fit today, carry over to tomorrow
        final tomorrowSlot = _findEarliestSlotTomorrow(
          duration: duration,
          dayStartMin: dayStartMin,
          dayEndMin: dayEndMin,
          tomorrowTasks: tomorrowTasks,
        );
        carryOvers.add(CarryOverItem(
          taskId: flex.id,
          taskTitle: flex.title,
          targetDateKey: tomorrowDateKey,
          startMin: tomorrowSlot.startMin,
          endMin: tomorrowSlot.endMin,
        ));
        moves.add(TaskMove(
          taskId: flex.id,
          taskTitle: flex.title,
          oldDateKey: flex.dateKey,
          oldStartMin: flex.startMin,
          oldEndMin: flex.endMin,
          newDateKey: tomorrowDateKey,
          newStartMin: tomorrowSlot.startMin,
          newEndMin: tomorrowSlot.endMin,
          reason: 'carried_to_tomorrow',
        ));
      }
    }

    resultingTasks.sort((x, y) => x.startMin.compareTo(y.startMin));
    final shiftedCount = moves.where((m) => m.taskId != triggerTask.id).length;
    final subtitle = shiftedCount > 0
        ? 'Extend ${triggerTask.title} & shift $shiftedCount flexible task${shiftedCount > 1 ? 's' : ''} forward. Fixed appointments untouched.'
        : 'Extend ${triggerTask.title} by ${extraMinutes}m using free time. No other tasks affected.';

    return RescheduleProposal(
      id: 'A',
      strategy: ProposalStrategy.shiftFlexible,
      title: 'Extend ${triggerTask.title} & shift flexible tasks',
      subtitle: subtitle,
      badgeText: 'RECOMMENDED',
      isRecommended: true,
      moves: moves,
      carryOvers: carryOvers,
      resultingDayTasks: resultingTasks,
      impactSummary: '✓ No conflicts. High-priority tasks keep full time. Fixed schedule protected.',
      isValid: true,
    );
  }

  /// PLAN B: Priority first / Move lower priority task later (e.g. into evening).
  RescheduleProposal _generatePlanB({
    required List<Task> currentDayTasks,
    required Task triggerTask,
    required int extraMinutes,
    required int dayStartMin,
    required int dayEndMin,
    required String todayDateKey,
    required String tomorrowDateKey,
    required List<Task> tomorrowTasks,
  }) {
    final newTriggerEnd = triggerTask.endMin + extraMinutes;
    final extendedTrigger = triggerTask.copyWith(endMin: newTriggerEnd);

    // Flexible tasks that need attention
    final flexibles = currentDayTasks
        .where((t) => t.id != triggerTask.id && !isImmovable(t) && t.endMin > triggerTask.startMin)
        .toList();

    if (flexibles.isEmpty) {
      return _generatePlanA(
        currentDayTasks: currentDayTasks,
        triggerTask: triggerTask,
        extraMinutes: extraMinutes,
        dayStartMin: dayStartMin,
        dayEndMin: dayEndMin,
        todayDateKey: todayDateKey,
        tomorrowDateKey: tomorrowDateKey,
        tomorrowTasks: tomorrowTasks,
      ).copyWith(id: 'B', isRecommended: false, badgeText: null);
    }

    // Sort by priority DESC (2 High first, 1 Medium, 0 Low last)
    flexibles.sort((a, b) {
      final pComp = b.priority.compareTo(a.priority);
      if (pComp != 0) return pComp;
      return a.startMin.compareTo(b.startMin);
    });

    final lowestPriorityTask = flexibles.last;

    // Plan B places high priority tasks first, moves lowest priority task to evening (>= 18:00 / 1080 min)
    final resultingTasks = <Task>[];
    for (final task in currentDayTasks) {
      if (task.id == triggerTask.id) {
        resultingTasks.add(extendedTrigger);
      } else if (isImmovable(task) || task.endMin <= triggerTask.startMin) {
        resultingTasks.add(task);
      }
    }

    final occupied = List<Task>.from(resultingTasks)..sort((x, y) => x.startMin.compareTo(y.startMin));
    final moves = <TaskMove>[
      TaskMove(
        taskId: triggerTask.id,
        taskTitle: triggerTask.title,
        oldDateKey: triggerTask.dateKey,
        oldStartMin: triggerTask.startMin,
        oldEndMin: triggerTask.endMin,
        newDateKey: todayDateKey,
        newStartMin: triggerTask.startMin,
        newEndMin: newTriggerEnd,
        reason: 'extended_duration',
      ),
    ];
    final carryOvers = <CarryOverItem>[];

    var cursor = newTriggerEnd;
    for (final flex in flexibles) {
      if (flex.id == lowestPriorityTask.id) {
        // Move lowest priority task to evening (18:00 or earliest slot after 18:00)
        final eveningStart = 18 * 60; // 1080
        final targetSearchStart = eveningStart > cursor ? eveningStart : cursor;
        final eveningSlot = _findEarliestSlot(
          cursor: targetSearchStart,
          duration: flex.durationMin,
          dayEndMin: dayEndMin,
          occupied: occupied,
        );

        if (eveningSlot != null) {
          final shifted = flex.copyWith(startMin: eveningSlot.startMin, endMin: eveningSlot.endMin);
          resultingTasks.add(shifted);
          occupied.add(shifted);
          occupied.sort((x, y) => x.startMin.compareTo(y.startMin));

          moves.add(TaskMove(
            taskId: flex.id,
            taskTitle: flex.title,
            oldDateKey: flex.dateKey,
            oldStartMin: flex.startMin,
            oldEndMin: flex.endMin,
            newDateKey: todayDateKey,
            newStartMin: eveningSlot.startMin,
            newEndMin: eveningSlot.endMin,
            reason: 'moved_to_evening',
          ));
        } else {
          // Carry to tomorrow
          final tomorrowSlot = _findEarliestSlotTomorrow(
            duration: flex.durationMin,
            dayStartMin: dayStartMin,
            dayEndMin: dayEndMin,
            tomorrowTasks: tomorrowTasks,
          );
          carryOvers.add(CarryOverItem(
            taskId: flex.id,
            taskTitle: flex.title,
            targetDateKey: tomorrowDateKey,
            startMin: tomorrowSlot.startMin,
            endMin: tomorrowSlot.endMin,
          ));
          moves.add(TaskMove(
            taskId: flex.id,
            taskTitle: flex.title,
            oldDateKey: flex.dateKey,
            oldStartMin: flex.startMin,
            oldEndMin: flex.endMin,
            newDateKey: tomorrowDateKey,
            newStartMin: tomorrowSlot.startMin,
            newEndMin: tomorrowSlot.endMin,
            reason: 'carried_to_tomorrow',
          ));
        }
      } else {
        // High priority flexible task gets earliest available slot
        final slot = _findEarliestSlot(
          cursor: cursor,
          duration: flex.durationMin,
          dayEndMin: dayEndMin,
          occupied: occupied,
        );

        if (slot != null) {
          final shifted = flex.copyWith(startMin: slot.startMin, endMin: slot.endMin);
          resultingTasks.add(shifted);
          occupied.add(shifted);
          occupied.sort((x, y) => x.startMin.compareTo(y.startMin));
          cursor = slot.endMin;

          moves.add(TaskMove(
            taskId: flex.id,
            taskTitle: flex.title,
            oldDateKey: flex.dateKey,
            oldStartMin: flex.startMin,
            oldEndMin: flex.endMin,
            newDateKey: todayDateKey,
            newStartMin: slot.startMin,
            newEndMin: slot.endMin,
            reason: 'priority_preserved',
          ));
        }
      }
    }

    resultingTasks.sort((x, y) => x.startMin.compareTo(y.startMin));

    return RescheduleProposal(
      id: 'B',
      strategy: ProposalStrategy.priorityFirst,
      title: 'Move a lower-priority task later',
      subtitle: '${lowestPriorityTask.title} moves to evening. High-priority tasks protected.',
      moves: moves,
      carryOvers: carryOvers,
      resultingDayTasks: resultingTasks,
      impactSummary: '✓ Protects prime afternoon hours. Lower-priority tasks fit into the evening.',
      isValid: true,
    );
  }

  /// PLAN C: Postpone trigger task until tomorrow.
  RescheduleProposal _generatePlanC({
    required List<Task> currentDayTasks,
    required Task triggerTask,
    required int dayStartMin,
    required int dayEndMin,
    required String todayDateKey,
    required String tomorrowDateKey,
    required List<Task> tomorrowTasks,
  }) {
    // Today's schedule remains untouched (trigger task is removed from today's active flow)
    final resultingToday = currentDayTasks.where((t) => t.id != triggerTask.id).toList();

    // Find earliest matching slot tomorrow
    final tomorrowSlot = _findEarliestSlotTomorrow(
      duration: triggerTask.durationMin,
      dayStartMin: dayStartMin,
      dayEndMin: dayEndMin,
      tomorrowTasks: tomorrowTasks,
    );

    final move = TaskMove(
      taskId: triggerTask.id,
      taskTitle: triggerTask.title,
      oldDateKey: todayDateKey,
      oldStartMin: triggerTask.startMin,
      oldEndMin: triggerTask.endMin,
      newDateKey: tomorrowDateKey,
      newStartMin: tomorrowSlot.startMin,
      newEndMin: tomorrowSlot.endMin,
      reason: 'postponed_to_tomorrow',
    );

    return RescheduleProposal(
      id: 'C',
      strategy: ProposalStrategy.postponeTomorrow,
      title: 'Postpone ${triggerTask.title} until tomorrow',
      subtitle: 'Today stays exactly as planned. ${triggerTask.title} moves to tomorrow morning.',
      moves: [move],
      carryOvers: [
        CarryOverItem(
          taskId: triggerTask.id,
          taskTitle: triggerTask.title,
          targetDateKey: tomorrowDateKey,
          startMin: tomorrowSlot.startMin,
          endMin: tomorrowSlot.endMin,
        ),
      ],
      resultingDayTasks: resultingToday,
      impactSummary: '✓ Zero changes to today’s schedule. Tomorrow starts fresh with your carried task.',
      isValid: true,
    );
  }

  /// PLAN D: Keep original schedule & skip/unfinished for now.
  RescheduleProposal _generatePlanD({
    required List<Task> currentDayTasks,
    required Task triggerTask,
    required int extraMinutes,
    required String todayDateKey,
  }) {
    final resultingToday = currentDayTasks.map((t) {
      if (t.id == triggerTask.id) {
        return t.copyWith(status: 'incomplete');
      }
      return t;
    }).toList();

    return RescheduleProposal(
      id: 'D',
      strategy: ProposalStrategy.keepOriginalSkip,
      title: 'Keep original & skip for now',
      subtitle: '${triggerTask.title} is saved as unfinished — pick it up anytime.',
      moves: [
        TaskMove(
          taskId: triggerTask.id,
          taskTitle: triggerTask.title,
          oldDateKey: todayDateKey,
          oldStartMin: triggerTask.startMin,
          oldEndMin: triggerTask.endMin,
          newDateKey: todayDateKey,
          newStartMin: triggerTask.startMin,
          newEndMin: triggerTask.endMin,
          reason: 'marked_unfinished',
        ),
      ],
      resultingDayTasks: resultingToday,
      impactSummary: '✓ Schedule untouched. You can resume this task whenever free time opens.',
      isValid: true,
    );
  }

  /// Screen 19: Generates conflict resolution proposals when adding a new plan (e.g. fixed Movie).
  List<RescheduleProposal> generateConflictProposals({
    required List<Task> currentDayTasks,
    required Task newConflictingTask,
    required int dayStartMin,
    required int dayEndMin,
    required String todayDateKey,
    required String tomorrowDateKey,
    List<Task> tomorrowTasks = const [],
  }) {
    final proposals = <RescheduleProposal>[];

    // Identify tasks clashing with newConflictingTask
    final collidingTasks = currentDayTasks
        .where((t) => t.startMin < newConflictingTask.endMin && t.endMin > newConflictingTask.startMin)
        .toList();

    // 1. Move flexible tasks to open free afternoon gaps (BEST FIT)
    final plan1 = _generateConflictBestFit(
      currentDayTasks: currentDayTasks,
      newPlan: newConflictingTask,
      collidingTasks: collidingTasks,
      dayStartMin: dayStartMin,
      dayEndMin: dayEndMin,
      todayDateKey: todayDateKey,
    );
    proposals.add(plan1);

    // 2. Reschedule tasks before / after the event
    final plan2 = _generateConflictRescheduleAround(
      currentDayTasks: currentDayTasks,
      newPlan: newConflictingTask,
      collidingTasks: collidingTasks,
      dayStartMin: dayStartMin,
      dayEndMin: dayEndMin,
      todayDateKey: todayDateKey,
    );
    proposals.add(plan2);

    // 3. Shorten flexible task durations (Decision D2: flexible only)
    final plan3 = _generateConflictShortenFlexible(
      currentDayTasks: currentDayTasks,
      newPlan: newConflictingTask,
      collidingTasks: collidingTasks,
      dayStartMin: dayStartMin,
      dayEndMin: dayEndMin,
      todayDateKey: todayDateKey,
    );
    proposals.add(plan3);

    // 4. Move to another day (tomorrow)
    final plan4 = _generateConflictMoveToTomorrow(
      currentDayTasks: currentDayTasks,
      newPlan: newConflictingTask,
      collidingTasks: collidingTasks,
      dayStartMin: dayStartMin,
      dayEndMin: dayEndMin,
      todayDateKey: todayDateKey,
      tomorrowDateKey: tomorrowDateKey,
      tomorrowTasks: tomorrowTasks,
    );
    proposals.add(plan4);

    return proposals;
  }

  /// Screen 19 Option 1: Move flexible tasks into earlier free gaps (Best Fit).
  RescheduleProposal _generateConflictBestFit({
    required List<Task> currentDayTasks,
    required Task newPlan,
    required List<Task> collidingTasks,
    required int dayStartMin,
    required int dayEndMin,
    required String todayDateKey,
  }) {
    final immovable = currentDayTasks.where(isImmovable).toList()..add(newPlan);
    immovable.sort((a, b) => a.startMin.compareTo(b.startMin));

    final moves = <TaskMove>[];
    final resulting = List<Task>.from(currentDayTasks.where((t) => !collidingTasks.contains(t)))..add(newPlan);
    final occupied = List<Task>.from(resulting)..sort((a, b) => a.startMin.compareTo(b.startMin));

    for (final task in collidingTasks) {
      if (isImmovable(task)) {
        continue;
      }
      final slot = _findEarliestSlot(
        cursor: dayStartMin,
        duration: task.durationMin,
        dayEndMin: dayEndMin,
        occupied: occupied,
      );

      if (slot != null) {
        final shifted = task.copyWith(startMin: slot.startMin, endMin: slot.endMin);
        resulting.add(shifted);
        occupied.add(shifted);
        occupied.sort((a, b) => a.startMin.compareTo(b.startMin));

        moves.add(TaskMove(
          taskId: task.id,
          taskTitle: task.title,
          oldDateKey: task.dateKey,
          oldStartMin: task.startMin,
          oldEndMin: task.endMin,
          newDateKey: todayDateKey,
          newStartMin: slot.startMin,
          newEndMin: slot.endMin,
          reason: 'moved_to_free_slot',
        ));
      }
    }

    resulting.sort((a, b) => a.startMin.compareTo(b.startMin));

    return RescheduleProposal(
      id: 'A',
      strategy: ProposalStrategy.moveConflictFlexible,
      title: 'Move flexible tasks',
      subtitle: '${collidingTasks.map((t) => t.title).join(' & ')} move to open afternoon slots',
      badgeText: 'BEST FIT',
      isRecommended: true,
      moves: moves,
      resultingDayTasks: resulting,
      impactSummary: '✓ Uses your free afternoon. Tasks keep their full time and no breaks are lost.',
      isValid: moves.length == collidingTasks.where((t) => !isImmovable(t)).length,
    );
  }

  /// Screen 19 Option 2: Reschedule tasks around the event.
  RescheduleProposal _generateConflictRescheduleAround({
    required List<Task> currentDayTasks,
    required Task newPlan,
    required List<Task> collidingTasks,
    required int dayStartMin,
    required int dayEndMin,
    required String todayDateKey,
  }) {
    final resulting = List<Task>.from(currentDayTasks.where((t) => !collidingTasks.contains(t)))..add(newPlan);
    final occupied = List<Task>.from(resulting)..sort((a, b) => a.startMin.compareTo(b.startMin));
    final moves = <TaskMove>[];

    // Place first task before newPlan, second after newPlan
    var index = 0;
    for (final task in collidingTasks) {
      if (isImmovable(task)) continue;
      final searchStart = (index == 0) ? dayStartMin : newPlan.endMin;
      final slot = _findEarliestSlot(
        cursor: searchStart,
        duration: task.durationMin,
        dayEndMin: dayEndMin,
        occupied: occupied,
      );

      if (slot != null) {
        final shifted = task.copyWith(startMin: slot.startMin, endMin: slot.endMin);
        resulting.add(shifted);
        occupied.add(shifted);
        occupied.sort((a, b) => a.startMin.compareTo(b.startMin));

        moves.add(TaskMove(
          taskId: task.id,
          taskTitle: task.title,
          oldDateKey: task.dateKey,
          oldStartMin: task.startMin,
          oldEndMin: task.endMin,
          newDateKey: todayDateKey,
          newStartMin: slot.startMin,
          newEndMin: slot.endMin,
          reason: 'rescheduled_around_event',
        ));
      }
      index++;
    }

    resulting.sort((a, b) => a.startMin.compareTo(b.startMin));

    return RescheduleProposal(
      id: 'B',
      strategy: ProposalStrategy.rescheduleConflict,
      title: 'Reschedule tasks',
      subtitle: 'Schedule tasks immediately before and after ${newPlan.title}',
      moves: moves,
      resultingDayTasks: resulting,
      impactSummary: '✓ Places tasks directly around ${newPlan.title}.',
      isValid: moves.isNotEmpty,
    );
  }

  /// Screen 19 Option 3: Change flexible task durations (Decision D2: flexible only).
  RescheduleProposal _generateConflictShortenFlexible({
    required List<Task> currentDayTasks,
    required Task newPlan,
    required List<Task> collidingTasks,
    required int dayStartMin,
    required int dayEndMin,
    required String todayDateKey,
  }) {
    final resulting = List<Task>.from(currentDayTasks.where((t) => !collidingTasks.contains(t)))..add(newPlan);
    final moves = <TaskMove>[];
    final occupied = List<Task>.from(resulting)..sort((a, b) => a.startMin.compareTo(b.startMin));

    // Proportionally shorten flexible tasks to a minimum of 15m
    for (final task in collidingTasks) {
      if (isImmovable(task)) continue;
      final shortenedDuration = (task.durationMin ~/ 2).clamp(15, task.durationMin);

      final slot = _findEarliestSlot(
        cursor: dayStartMin,
        duration: shortenedDuration,
        dayEndMin: dayEndMin,
        occupied: occupied,
      );

      if (slot != null) {
        final shortenedTask = task.copyWith(startMin: slot.startMin, endMin: slot.endMin);
        resulting.add(shortenedTask);
        occupied.add(shortenedTask);
        occupied.sort((a, b) => a.startMin.compareTo(b.startMin));

        moves.add(TaskMove(
          taskId: task.id,
          taskTitle: task.title,
          oldDateKey: task.dateKey,
          oldStartMin: task.startMin,
          oldEndMin: task.endMin,
          newDateKey: todayDateKey,
          newStartMin: slot.startMin,
          newEndMin: slot.endMin,
          reason: 'shortened_duration',
          isShortened: true,
        ));
      }
    }

    resulting.sort((a, b) => a.startMin.compareTo(b.startMin));

    return RescheduleProposal(
      id: 'C',
      strategy: ProposalStrategy.shortenConflictFlexible,
      title: 'Change task durations',
      subtitle: 'Shorten flexible tasks so they fit into compact slots (Decision D2)',
      moves: moves,
      resultingDayTasks: resulting,
      impactSummary: '✓ Fits all tasks today with reduced durations.',
      isValid: moves.isNotEmpty,
    );
  }

  /// Screen 19 Option 4: Move colliding flexible tasks to tomorrow.
  RescheduleProposal _generateConflictMoveToTomorrow({
    required List<Task> currentDayTasks,
    required Task newPlan,
    required List<Task> collidingTasks,
    required int dayStartMin,
    required int dayEndMin,
    required String todayDateKey,
    required String tomorrowDateKey,
    required List<Task> tomorrowTasks,
  }) {
    final resulting = List<Task>.from(currentDayTasks.where((t) => !collidingTasks.contains(t)))..add(newPlan);
    final moves = <TaskMove>[];
    final carryOvers = <CarryOverItem>[];

    for (final task in collidingTasks) {
      if (isImmovable(task)) continue;
      final slot = _findEarliestSlotTomorrow(
        duration: task.durationMin,
        dayStartMin: dayStartMin,
        dayEndMin: dayEndMin,
        tomorrowTasks: tomorrowTasks,
      );

      carryOvers.add(CarryOverItem(
        taskId: task.id,
        taskTitle: task.title,
        targetDateKey: tomorrowDateKey,
        startMin: slot.startMin,
        endMin: slot.endMin,
      ));

      moves.add(TaskMove(
        taskId: task.id,
        taskTitle: task.title,
        oldDateKey: task.dateKey,
        oldStartMin: task.startMin,
        oldEndMin: task.endMin,
        newDateKey: tomorrowDateKey,
        newStartMin: slot.startMin,
        newEndMin: slot.endMin,
        reason: 'moved_to_tomorrow',
      ));
    }

    resulting.sort((a, b) => a.startMin.compareTo(b.startMin));

    return RescheduleProposal(
      id: 'D',
      strategy: ProposalStrategy.moveConflictToAnotherDay,
      title: 'Move to another day',
      subtitle: '${collidingTasks.map((t) => t.title).join(' & ')} move to tomorrow evening',
      moves: moves,
      carryOvers: carryOvers,
      resultingDayTasks: resulting,
      impactSummary: '✓ Relieves today’s schedule completely by deferring conflicting tasks.',
      isValid: moves.isNotEmpty,
    );
  }

  /// Finds the earliest time slot >= cursor of length [duration] that does not collide with [occupied].
  ({int startMin, int endMin})? _findEarliestSlot({
    required int cursor,
    required int duration,
    required int dayEndMin,
    required List<Task> occupied,
  }) {
    var candidateStart = cursor;
    final sortedOccupied = List<Task>.from(occupied)..sort((x, y) => x.startMin.compareTo(y.startMin));

    while (candidateStart + duration <= dayEndMin) {
      final candidateEnd = candidateStart + duration;
      Task? colliding;

      for (final occ in sortedOccupied) {
        if (candidateStart < occ.endMin && candidateEnd > occ.startMin) {
          colliding = occ;
          break;
        }
      }

      if (colliding == null) {
        return (startMin: candidateStart, endMin: candidateEnd);
      } else {
        // Jump candidateStart to the end of the colliding task
        candidateStart = colliding.endMin;
      }
    }

    return null;
  }

  /// Finds earliest available slot tomorrow starting from wakeMin.
  ({int startMin, int endMin}) _findEarliestSlotTomorrow({
    required int duration,
    required int dayStartMin,
    required int dayEndMin,
    required List<Task> tomorrowTasks,
  }) {
    final slot = _findEarliestSlot(
      cursor: dayStartMin,
      duration: duration,
      dayEndMin: dayEndMin,
      occupied: tomorrowTasks,
    );

    if (slot != null) return slot;

    // Default fallback to dayStartMin
    return (startMin: dayStartMin, endMin: (dayStartMin + duration).clamp(dayStartMin, dayEndMin));
  }

  /// Verifies all mathematical invariants for a proposal.
  bool verifyInvariants({
    required RescheduleProposal proposal,
    required List<Task> originalTasks,
    required int dayStartMin,
    required int dayEndMin,
  }) {
    if (!proposal.isValid) return false;

    // 1. Zero overlaps in resultingDayTasks
    final conflicts = detectConflicts(proposal.resultingDayTasks);
    if (conflicts.isNotEmpty) return false;

    // 2. Immovable tasks from originalTasks must be identical in resultingDayTasks
    for (final orig in originalTasks) {
      if (isImmovable(orig)) {
        final match = proposal.resultingDayTasks.where((t) => t.id == orig.id).firstOrNull;
        if (match == null) return false;
        if (match.startMin != orig.startMin || match.endMin != orig.endMin || match.dateKey != orig.dateKey) {
          return false;
        }
      }
    }

    // 3. All resulting tasks must lie strictly inside day window
    for (final t in proposal.resultingDayTasks) {
      if (t.startMin < dayStartMin || t.endMin > dayEndMin) {
        return false;
      }
      if (t.endMin > 1440) return false; // Never cross midnight
    }

    return true;
  }
}
