import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class EditItemScreen extends StatelessWidget {
  final String subjectId;
  final String? itemId;

  const EditItemScreen({super.key, required this.subjectId, this.itemId});

  @override
  Widget build(BuildContext context) {
    final isEditing = itemId != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Edit Item' : 'New Item',
          style: AppTypography.cardTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Item title'),
              style: AppTypography.body,
            ),
            const SizedBox(height: 16),
            // Type selector
            Row(
              children: [
                _TypeChip(label: 'Assignment', isSelected: true),
                const SizedBox(width: 8),
                _TypeChip(label: 'Homework', isSelected: false),
                const SizedBox(width: 8),
                _TypeChip(label: 'Test', isSelected: false),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(hintText: 'Description'),
              style: AppTypography.body,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(hintText: 'Due date'),
              style: AppTypography.body,
              readOnly: true,
              onTap: () {},
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => context.pop(),
                child: Text(
                  isEditing ? 'Save Changes' : 'Create Item',
                  style: AppTypography.body,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _TypeChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.chipActive,
      backgroundColor: AppColors.chipDefault,
      labelStyle: AppTypography.chip.copyWith(
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
      showCheckmark: false,
      onSelected: (_) {},
    );
  }
}
