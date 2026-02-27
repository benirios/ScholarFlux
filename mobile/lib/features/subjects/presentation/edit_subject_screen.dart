import 'package:flutter/material.dart';

class EditSubjectScreen extends StatelessWidget {
  final String? subjectId;

  const EditSubjectScreen({super.key, this.subjectId});

  @override
  Widget build(BuildContext context) {
    final isEditing = subjectId != null;
    return Scaffold(
      body: Center(
        child: Text('${isEditing ? "Edit" : "New"} Subject — TODO'),
      ),
    );
  }
}
