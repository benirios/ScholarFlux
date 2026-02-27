import 'package:flutter/material.dart';

class SubjectsScreen extends StatelessWidget {
  final String? subjectId;

  const SubjectsScreen({super.key, this.subjectId});

  @override
  Widget build(BuildContext context) {
    if (subjectId != null) {
      return Scaffold(
        body: Center(child: Text('Subject Detail: $subjectId — TODO')),
      );
    }
    return const Scaffold(
      body: Center(child: Text('Subjects List — TODO')),
    );
  }
}
