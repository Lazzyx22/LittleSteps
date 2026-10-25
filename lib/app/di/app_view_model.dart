import 'package:flutter/foundation.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/media_service.dart';
import '../../domain/models/models.dart';
import '../../domain/use_cases/learning.dart';

class AppViewModel extends ChangeNotifier {
  AppViewModel(
    this.content,
    this.profiles,
    this.progressRepository,
    this.settingsRepository,
  );
  final ContentRepository content;
  final ProfileRepository profiles;
  final ProgressRepository progressRepository;
  final SettingsRepository settingsRepository;
  final MediaService media = const MediaService();
  ChildProfile? child;
  ParentSettings settings = ParentSettings();
  Progress progress = Progress();
  bool parentUnlocked = false;
  String? error;
  DateTime sessionStarted = DateTime.now();
  List<Lesson> get lessons =>
      child == null ? [] : content.forProfile(child!, settings);
  Journey get journey => BuildDailyJourneyUseCase()(
    lessons,
    child!,
    settings,
    progress,
    DateTime.now(),
  );
  Lesson? get continueLesson => lessons
      .where(
        (l) =>
            (progress.steps[l.id] ?? 0) > 0 &&
            (progress.steps[l.id] ?? 0) < l.steps.length,
      )
      .firstOrNull;
  bool get sessionLimitReached =>
      DateTime.now().difference(sessionStarted).inMinutes >=
      settings.maxSessionLength;
  Future<void> initialize() async {
    settings = await settingsRepository.load();
    notifyListeners();
  }

  Future<void> selectChild(ChildProfile profile) async {
    final saved = await progressRepository.load(profile.id);
    child = profile;
    progress = saved;
    parentUnlocked = false;
    sessionStarted = DateTime.now();
    error = null;
    notifyListeners();
  }

  void leaveChild() {
    child = null;
    parentUnlocked = false;
    notifyListeners();
  }

  void lockParent() {
    parentUnlocked = false;
    notifyListeners();
  }

  void unlockParent() {
    parentUnlocked = true;
    notifyListeners();
  }

  Future<bool> saveSettings(ParentSettings value) async {
    try {
      await settingsRepository.save(value);
      settings = value;
      error = null;
      notifyListeners();
      return true;
    } catch (_) {
      error = 'Settings could not be saved. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordStep(
    Lesson lesson,
    int completed, {
    required bool evaluated,
    required int mistakes,
    required int seconds,
  }) async {
    final id = child!.id;
    var mastery = progress.mastery[lesson.id] ?? const ConceptMastery();
    if (evaluated) {
      for (var i = 0; i < mistakes; i++) {
        mastery = mastery.record(
          correct: false,
          first: false,
          now: DateTime.now(),
        );
      }
      mastery = mastery.record(
        correct: true,
        first: mistakes == 0,
        now: DateTime.now(),
      );
    } else if (mastery.attemptCount == 0) {
      mastery = ConceptMastery(attemptCount: 1, lastPracticed: DateTime.now());
    }
    final savedStep = progress.steps[lesson.id] ?? 0;
    final next = Progress(
      steps: {
        ...progress.steps,
        lesson.id: completed > savedStep ? completed : savedStep,
      },
      mastery: {...progress.mastery, lesson.id: mastery},
      seconds: {
        ...progress.seconds,
        lesson.id: (progress.seconds[lesson.id] ?? 0) + seconds,
      },
    );
    try {
      await progressRepository.save(id, next);
      progress = next;
      error = null;
      notifyListeners();
      return true;
    } catch (_) {
      error = 'Your progress could not be saved. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
