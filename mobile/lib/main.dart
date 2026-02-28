import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/storage/local_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.init();
  runApp(const ProviderScope(child: ScholarFluxApp()));
}
