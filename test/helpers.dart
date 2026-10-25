import 'dart:io';
import 'package:little_steps/app/di/app_view_model.dart';
import 'package:little_steps/data/dto/content_parser.dart';
import 'package:little_steps/data/repositories/repositories.dart';
import 'package:little_steps/data/services/local_store.dart';

AppViewModel demoModel({LocalStore? localStore}) {
  final store = localStore ?? MemoryStore();
  return AppViewModel(
    ContentRepository(
      ContentParser().parse(
        File('assets/content/catalog.json').readAsStringSync(),
      ),
    ),
    ProfileRepository(),
    ProgressRepository(store),
    SettingsRepository(store),
  );
}
