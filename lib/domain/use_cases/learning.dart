import 'dart:math';
import '../models/models.dart';

class BuildDailyJourneyUseCase {
  Journey call(
    List<Lesson> lessons,
    ChildProfile profile,
    ParentSettings settings,
    Progress progress,
    DateTime now,
  ) {
    final available = lessons
        .where(
          (l) =>
              l.ageBands.contains(profile.ageBand) &&
              settings.enabledSubjects.contains(l.subjectId),
        )
        .toList();
    final nodes = <JourneyNode>[];
    void add(String reason, bool Function(Lesson) predicate) {
      for (final lesson in available) {
        if (!nodes.any((n) => n.lesson.id == lesson.id) && predicate(lesson)) {
          nodes.add(JourneyNode(lesson, reason));
          break;
        }
      }
    }

    add('Discover', (l) => (progress.steps[l.id] ?? 0) == 0);
    final recent =
        available
            .where((l) => progress.mastery[l.id]?.lastPracticed != null)
            .toList()
          ..sort(
            (a, b) => progress.mastery[b.id]!.lastPracticed!.compareTo(
              progress.mastery[a.id]!.lastPracticed!,
            ),
          );
    if (recent.isNotEmpty)
      add('Practice again', (l) => l.id == recent.first.id);
    add(
      'Review',
      (l) => progress.mastery[l.id]?.state(now) == MasteryState.needsReview,
    );
    add(
      'Play',
      (l) => l.steps.any(
        (s) =>
            s.type == ActivityType.matching || s.type == ActivityType.dragDrop,
      ),
    );
    add(
      'Imagine',
      (l) => l.steps.any(
        (s) => s.type == ActivityType.coloring || s.type == ActivityType.story,
      ),
    );
    return Journey(nodes.take(5).toList());
  }
}

class QuizEvaluation {
  int incorrectAttempts = 0;
  bool solved = false;
  bool answer(QuizQuestion question, String answerId) {
    if (solved) return true;
    solved = question.correctId == answerId;
    if (!solved) incorrectAttempts++;
    return solved;
  }

  int get score => solved ? (incorrectAttempts == 0 ? 2 : 1) : 0;
  bool get showExplanation => incorrectAttempts >= 2;
}

class TracePoint {
  const TracePoint(this.x, this.y);
  final double x, y;
  double distance(TracePoint other) =>
      sqrt(pow(x - other.x, 2) + pow(y - other.y, 2));
}

class TracingEvaluator {
  static List<TracePoint> path(String kind) => List.generate(60, (i) {
    final t = i / 59;
    if (kind == 'circle')
      return TracePoint(.5 + .32 * cos(t * 2 * pi), .5 + .32 * sin(t * 2 * pi));
    if (kind == 'letter')
      return t < .5
          ? TracePoint(.2 + .6 * t, .8 - 1.2 * t)
          : TracePoint(.5 + .6 * (t - .5), .2 + 1.2 * (t - .5));
    return TracePoint(.15 + .7 * t, .5);
  });
  static double completion(
    List<TracePoint> path,
    List<TracePoint> input, {
    double tolerance = .09,
  }) => path.isEmpty
      ? 0
      : path
                .where(
                  (point) => input.any((p) => point.distance(p) <= tolerance),
                )
                .length /
            path.length;
}
