import 'package:flutter/material.dart';

class EditItemScreen extends StatelessWidget {
  final String subjectId;
  final String? itemId;

  const EditItemScreen({super.key, required this.subjectId, this.itemId});

  @override
  Widget build(BuildContext context) {
    final isEditing = itemId != null;
    return Scaffold(
      body: Center(
        child: Text('${isEditing ? "Edit" : "New"} Item — TODO'),
      ),
    );
  }
}
