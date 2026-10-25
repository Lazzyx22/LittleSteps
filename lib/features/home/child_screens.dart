import 'package:flutter/material.dart';
import '../../app/di/app_view_model.dart';
import '../../app/router.dart';
import '../../core/widgets/learning_widgets.dart';
import '../../domain/models/models.dart';

class ChildHome extends StatelessWidget {
  const ChildHome({super.key, required this.model});
  final AppViewModel model;
  @override
  Widget build(BuildContext context) {
    final child = model.child!;
    void open(String route) => Navigator.pushNamed(context, route);
    return LearningPage(
      title: '${child.symbol} Hello, ${child.nickname}!',
      actions: [
        TextButton(
          onPressed: () => open(AppRoutes.parent),
          child: const Text('Parents'),
        ),
      ],
      children: [
        Text(
          child.isPreschool
              ? 'Let’s play and discover!'
              : 'What will you discover today?',
          style: const TextStyle(fontSize: 28),
        ),
        LearningCard(
          title: 'Today’s Adventure',
          symbol: '☀',
          large: child.isPreschool,
          onTap: () => open(AppRoutes.journey),
        ),
        if (model.continueLesson case final Lesson lesson)
          LearningCard(
            title: 'Continue Learning',
            subtitle: lesson.title,
            symbol: '▶',
            large: child.isPreschool,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.lesson,
              arguments: lesson.id,
            ),
          ),
        LearningCard(
          title: 'Explore Subjects',
          symbol: '▦',
          large: child.isPreschool,
          onTap: () => open(AppRoutes.subjects),
        ),
        LearningCard(
          title: 'Games',
          symbol: '☆',
          large: child.isPreschool,
          onTap: () => open(AppRoutes.games),
        ),
        LearningCard(
          title: 'My discoveries',
          symbol: '✦',
          subtitle: '${model.progress.activityCount} activities completed',
          large: child.isPreschool,
          onTap: () => open(AppRoutes.progress),
        ),
        TextButton(
          onPressed: () {
            model.leaveChild();
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.profiles,
              (_) => false,
            );
          },
          child: const Text('Switch explorer'),
        ),
      ],
    );
  }
}

class ContentBrowser extends StatelessWidget {
  const ContentBrowser({
    super.key,
    required this.model,
    this.subjectId,
    this.topicId,
    this.gamesOnly = false,
    this.journey = false,
  });
  final AppViewModel model;
  final String? subjectId, topicId;
  final bool gamesOnly, journey;
  @override
  Widget build(BuildContext context) {
    final lessons = model.lessons;
    if (subjectId == null && !gamesOnly && !journey) {
      return LearningPage(
        title: 'Explore subjects',
        children: [
          for (final s in model.content.catalog.subjects.where(
            (s) => model.settings.enabledSubjects.contains(s.id),
          ))
            LearningCard(
              title: s.title,
              symbol: s.symbol,
              large: model.child!.isPreschool,
              subtitle:
                  '${lessons.where((l) => l.subjectId == s.id).length} adventures',
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.subject,
                arguments: s.id,
              ),
            ),
          if (model.settings.enabledSubjects.isEmpty)
            const Text('An adult can enable subjects in Parent settings.'),
        ],
      );
    }
    if (subjectId != null && topicId == null) {
      final subject = model.content.catalog.subjects
          .where((s) => s.id == subjectId)
          .firstOrNull;
      final topics = model.content.catalog.topics.where(
        (t) =>
            t.subjectId == subjectId && lessons.any((l) => l.topicId == t.id),
      );
      return LearningPage(
        title: subject?.title ?? 'Subject unavailable',
        children: [
          for (final t in topics)
            LearningCard(
              title: t.title,
              symbol: subject?.symbol ?? '☆',
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.topic,
                arguments: t.id,
              ),
            ),
          if (topics.isEmpty) const Text('New discoveries will be added here.'),
        ],
      );
    }
    final nodes = journey ? model.journey.nodes : <JourneyNode>[];
    final selected = journey
        ? nodes.map((n) => n.lesson).toList()
        : lessons
              .where(
                (l) => topicId != null
                    ? l.topicId == topicId
                    : l.steps.any(
                        (s) => [
                          ActivityType.matching,
                          ActivityType.dragDrop,
                          ActivityType.tracing,
                          ActivityType.coloring,
                        ].contains(s.type),
                      ),
              )
              .toList();
    return LearningPage(
      title: journey
          ? 'Today’s Journey'
          : gamesOnly
          ? 'Play and create'
          : 'Choose an adventure',
      children: [
        if (journey)
          const Text(
            'A short, gentle adventure. Stop whenever you need a break.',
          ),
        for (final l in selected)
          LearningCard(
            title: l.title,
            symbol: '✦',
            subtitle: journey
                ? nodes.firstWhere((n) => n.lesson.id == l.id).reason
                : '${l.estimatedMinutes} min · ${l.steps.length} activities',
            large: model.child!.isPreschool,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.lesson, arguments: l.id),
          ),
        if (selected.isEmpty)
          const Text('No activities here yet. Try another subject.'),
      ],
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.model});
  final AppViewModel model;
  @override
  Widget build(BuildContext context) => LearningPage(
    title: 'My discoveries',
    children: [
      Text(
        '${model.progress.activityCount} learning steps explored',
        style: const TextStyle(fontSize: 28),
      ),
      for (final l in model.lessons.where(
        (l) => model.progress.steps.containsKey(l.id),
      ))
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.title),
                LinearProgressIndicator(
                  value: ((model.progress.steps[l.id] ?? 0) / l.steps.length)
                      .clamp(0, 1),
                ),
                Text(
                  '${model.progress.steps[l.id]} of ${l.steps.length} steps',
                ),
              ],
            ),
          ),
        ),
      if (model.progress.activityCount == 0)
        const Text('Your first discovery is waiting!'),
    ],
  );
}
