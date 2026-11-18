import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../domain/entities/category.dart';

class CategoryOption {
  const CategoryOption({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  final int id;
  final String name;
  final Color color;
  final IconData icon;

  Category toDomainCategory() {
    return Category(
      id: id,
      name: name,
      color: color.toARGB32(),
      iconKey: name.toLowerCase(),
      isDefault: true,
    );
  }
}

const List<CategoryOption> defaultCategoryOptions = [
  CategoryOption(id: 1, name: 'Study', color: FlowColors.catStudy, icon: Icons.school_rounded),
  CategoryOption(id: 2, name: 'Work', color: FlowColors.catWork, icon: Icons.work_rounded),
  CategoryOption(id: 3, name: 'Health', color: FlowColors.catHealth, icon: Icons.fitness_center_rounded),
  CategoryOption(id: 4, name: 'Personal', color: FlowColors.catPersonal, icon: Icons.person_rounded),
  CategoryOption(id: 5, name: 'Social', color: FlowColors.catSocial, icon: Icons.people_rounded),
  CategoryOption(id: 6, name: 'Break', color: FlowColors.catBreak, icon: Icons.coffee_rounded),
];

class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final int? selectedCategoryId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CATEGORY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF71717A),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: defaultCategoryOptions.map((cat) {
            final isSelected = selectedCategoryId == cat.id;
            return GestureDetector(
              onTap: () => onSelected(cat.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFF161424),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.white : const Color(0xFF2A2640),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 14,
                      color: isSelected ? const Color(0xFF0B0B14) : cat.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF0B0B14) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
