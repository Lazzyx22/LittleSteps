import 'package:flutter/foundation.dart';
import '../../app/di/app_view_model.dart';
import '../../domain/models/models.dart';
import '../../domain/use_cases/learning.dart';

class LessonViewModel extends ChangeNotifier {
  LessonViewModel(this.app, this.lesson) {
    final saved = app.progress.steps[lesson.id] ?? 0;
    index = saved >= lesson.steps.length ? 0 : saved;
  }
  final AppViewModel app;
  final Lesson lesson;
  int index = 0;
  bool busy = false, finished = false;
  String feedback = '';
  QuizEvaluation quiz = QuizEvaluation();
  final Set<String> matched = {}, dropped = {};
  String? selectedLeft, selectedItem;
  int mistakes = 0;
  DateTime stepStarted = DateTime.now();
  LessonStep get step => lesson.steps[index];
  bool get evaluated => [
    ActivityType.mcq,
    ActivityType.imageChoice,
    ActivityType.matching,
    ActivityType.dragDrop,
    ActivityType.tracing,
  ].contains(step.type);
  bool get ready => switch (step.type) {
    ActivityType.mcq || ActivityType.imageChoice => quiz.solved,
    ActivityType.matching => matched.length == step.matching!.pairs.length,
    ActivityType.dragDrop => dropped.length == step.dragDrop!.categories.length,
    _ => true,
  };
  LearningReward get reward => const LearningReward(1, '✦', 'Curious explorer');
  void answer(String id) {
    final first = quiz.incorrectAttempts;
    final correct = quiz.answer(step.question!, id);
    mistakes += quiz.incorrectAttempts - first;
    feedback = correct
        ? 'You found it! Well explored.'
        : quiz.showExplanation
        ? step.question!.explanation
        : 'Let’s look again. You can try another.';
    notifyListeners();
  }

  void selectPair(String left) {
    selectedLeft = left;
    feedback = 'Now choose its partner.';
    notifyListeners();
  }

  void match(String right) {
    if (selectedLeft == null) return;
    if (step.matching!.matches(selectedLeft!, right)) {
      matched.add(selectedLeft!);
      feedback = 'A pair!';
      selectedLeft = null;
    } else {
      mistakes++;
      feedback = 'Try another partner.';
    }
    notifyListeners();
  }

  void selectDragItem(String item) {
    selectedItem = item;
    feedback = 'Now choose a category.';
    notifyListeners();
  }

  void drop(String item, String target) {
    if (dropped.contains(item)) return;
    if (step.dragDrop!.accepts(item, target)) {
      dropped.add(item);
      selectedItem = null;
      feedback = 'That belongs here!';
    } else {
      mistakes++;
      feedback = 'Try a different home for this one.';
    }
    notifyListeners();
  }

  Future<void> complete() async {
    if (busy || !ready) return;
    busy = true;
    notifyListeners();
    final saved = await app.recordStep(
      lesson,
      index + 1,
      evaluated: evaluated,
      mistakes: mistakes,
      seconds: DateTime.now().difference(stepStarted).inSeconds.clamp(0, 300),
    );
    busy = false;
    if (!saved) {
      feedback = app.error!;
      notifyListeners();
      return;
    }
    if (index + 1 == lesson.steps.length) {
      finished = true;
    } else {
      index++;
      quiz = QuizEvaluation();
      matched.clear();
      dropped.clear();
      selectedLeft = null;
      selectedItem = null;
      mistakes = 0;
      feedback = '';
      stepStarted = DateTime.now();
    }
    notifyListeners();
  }
}
