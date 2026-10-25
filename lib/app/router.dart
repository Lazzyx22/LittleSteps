import 'package:flutter/material.dart';
import '../core/widgets/learning_widgets.dart';
import '../features/home/child_screens.dart';
import '../features/lessons/lesson_runner.dart';
import '../features/parent/parent_screens.dart';
import '../features/profiles/profile_picker.dart';
import 'di/app_view_model.dart';

abstract final class AppRoutes {
  static const profiles = '/',
      home = '/child/home',
      subjects = '/child/subjects',
      subject = '/child/subject',
      topic = '/child/topic',
      lesson = '/child/lesson',
      games = '/child/games',
      journey = '/child/journey',
      progress = '/child/progress',
      parent = '/parent',
      settings = '/parent/settings';
}

class AppRouter {
  AppRouter(this.model);
  final AppViewModel model;
  Route<void> generate(RouteSettings settings) {
    final id = settings.arguments is String
        ? settings.arguments as String
        : null;
    if (settings.name == AppRoutes.profiles || model.child == null) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ProfilePicker(
          model: model,
          onSelected: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.home),
        ),
      );
    }
    final screen = switch (settings.name) {
      AppRoutes.home => ChildHome(model: model),
      AppRoutes.subjects => ContentBrowser(model: model),
      AppRoutes.subject => ContentBrowser(model: model, subjectId: id),
      AppRoutes.topic => ContentBrowser(
        model: model,
        subjectId: model.content.catalog.topics
            .where((t) => t.id == id)
            .firstOrNull
            ?.subjectId,
        topicId: id,
      ),
      AppRoutes.games => ContentBrowser(model: model, gamesOnly: true),
      AppRoutes.journey => ContentBrowser(model: model, journey: true),
      AppRoutes.progress => ProgressScreen(model: model),
      AppRoutes.parent || AppRoutes.settings => ParentArea(
        model: model,
        settingsFirst: settings.name == AppRoutes.settings,
      ),
      AppRoutes.lesson => _lesson(id),
      _ => const LearningPage(
        title: 'Adventure unavailable',
        children: [Text('Go back and choose another discovery.')],
      ),
    };
    return MaterialPageRoute(settings: settings, builder: (_) => screen);
  }

  Widget _lesson(String? id) {
    final lesson = model.lessons.where((l) => l.id == id).firstOrNull;
    return lesson == null
        ? const LearningPage(
            title: 'Adventure unavailable',
            children: [
              Text('This lesson is missing or not enabled for this explorer.'),
            ],
          )
        : LessonRunner(app: model, lesson: lesson);
  }
}
