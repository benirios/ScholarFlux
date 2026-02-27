import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class EditSubjectScreen extends StatelessWidget {
  final String? subjectId;

  const EditSubjectScreen({super.key, this.subjectId});

  @override
  Widget build(BuildContext context) {
    final isEditing = subjectId != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Edit Subject' : 'New Subject',
          style: AppTypography.cardTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Subject name'),
              style: AppTypography.body,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(hintText: 'Room (optional)'),
              style: AppTypography.body,
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
                  isEditing ? 'Save Changes' : 'Create Subject',
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
