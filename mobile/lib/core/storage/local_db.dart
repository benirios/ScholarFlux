import 'package:hive_flutter/hive_flutter.dart';

const String subjectsBoxName = 'subjects';
const String itemsBoxName = 'items';
const String classesBoxName = 'classes';
const String preferencesBoxName = 'preferences';

class LocalDb {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(subjectsBoxName);
    await Hive.openBox<Map>(itemsBoxName);
    await Hive.openBox<Map>(classesBoxName);
    await Hive.openBox(preferencesBoxName);
  }

  static Box<Map> get subjectsBox => Hive.box<Map>(subjectsBoxName);
  static Box<Map> get itemsBox => Hive.box<Map>(itemsBoxName);
  static Box<Map> get classesBox => Hive.box<Map>(classesBoxName);
  static Box get preferencesBox => Hive.box(preferencesBoxName);
}
