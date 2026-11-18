import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/utils/time_utils.dart';
import 'category_selector.dart';

class TaskPreviewCard extends StatelessWidget {
  const TaskPreviewCard({
    super.key,
    required this.title,
    required this.startMin,
    required this.endMin,
    required this.categoryId,
    required this.priority,
    required this.isFixed,
    required this.reminderOffsetMin,
  });

  final String title;
  final int startMin;
  final int endMin;
  final int? categoryId;
  final int priority;
  final bool isFixed;
  final int? reminderOffsetMin;

  CategoryOption get _category {
    return defaultCategoryOptions.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => defaultCategoryOptions.first,
    );
  }

  int get _duration => (endMin - startMin).clamp(0, 1440);

  @override
  Widget build(BuildContext context) {
    final cat = _category;
    final displayTitle = title.trim().isEmpty ? 'New Task' : title.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171528),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2D2848), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'PREVIEW',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E8CA3), letterSpacing: 1.2),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isFixed ? const Color(0xFF26203D) : const Color(0xFF1E2838),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isFixed ? '🔒 Fixed' : '↔ Flexible',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isFixed ? FlowColors.primaryLight : const Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: cat.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${TimeUtils.formatTimeRange(startMin, endMin)} · ${_duration}m',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E8CA3)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildBadge(
                priority == 2 ? 'High' : (priority == 1 ? 'Medium' : 'Low'),
                priority == 2 ? FlowColors.error : (priority == 1 ? FlowColors.warning : FlowColors.catStudy),
              ),
              _buildBadge(cat.name, cat.color),
              if (reminderOffsetMin != null)
                _buildBadge(
                  reminderOffsetMin == 0 ? '⏰ At start' : '⏰ ${reminderOffsetMin}m before',
                  const Color(0xFF8E8CA3),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
