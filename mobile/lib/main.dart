import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/storage/local_db.dart';
import 'data/remote/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.init();
  await SupabaseClientWrapper.init();
  runApp(const ProviderScope(child: ScholarFluxApp()));
}
