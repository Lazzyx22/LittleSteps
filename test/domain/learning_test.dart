import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_steps/data/dto/content_parser.dart';
import 'package:little_steps/data/repositories/repositories.dart';
import 'package:little_steps/data/services/local_store.dart';
import 'package:little_steps/domain/models/models.dart';
import 'package:little_steps/domain/use_cases/learning.dart';
import 'package:little_steps/features/lessons/lesson_view_model.dart';
import '../helpers.dart';

class FailingStore extends MemoryStore {
  bool fail = true;
  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('Simulated disk failure');
    await super.write(key, value);
  }
}

void main() {
  test('failed writes preserve progress and allow retry', () async {
    final store = FailingStore();
    final app = demoModel(localStore: store);
    await app.selectChild(app.profiles.profiles.first);
    final runner = LessonViewModel(app, app.lessons.first);
    await runner.complete();
    expect(runner.index, 0);
    expect(app.progress.steps, isEmpty);
    expect(runner.feedback, contains('could not be saved'));
    expect(await app.saveSettings(ParentSettings(dailyTimeGoal: 30)), isFalse);
    expect(app.settings.dailyTimeGoal, 15);
    store.fail = false;
    await runner.complete();
    expect(runner.index, 1);
    runner.dispose();
  });
  test('parent settings reload all household preferences', () async {
    final store = MemoryStore();
    final repo = SettingsRepository(store);
    await repo.save(
      ParentSettings(
        dailyTimeGoal: 25,
        maxSessionLength: 10,
        enabledSubjects: {'maths'},
        language: 'Hindi',
        soundEffects: false,
        reducedMotion: true,
      ),
    );
    final loaded = await SettingsRepository(store).load();
    expect(loaded.dailyTimeGoal, 25);
    expect(loaded.maxSessionLength, 10);
    expect(loaded.enabledSubjects, {'maths'});
    expect(loaded.language, 'Hindi');
    expect(loaded.soundEffects, isFalse);
    expect(loaded.reducedMotion, isTrue);
  });
  test('all original content parses and references valid topics', () {
    final app = demoModel();
    expect(app.content.catalog.errors, isEmpty);
    expect(app.content.catalog.lessons, hasLength(26));
    expect(app.content.catalog.subjects, hasLength(8));
  });
  test('preschool profile never receives Grade-2-only lessons', () async {
    final app = demoModel();
    await app.selectChild(app.profiles.profiles.first);
    expect(app.lessons, hasLength(10));
    expect(
      app.lessons.every((l) => l.ageBands.contains(AgeBand.preschool3)),
      isTrue,
    );
  });
  test('Grade 2 never receives preschool-only lessons', () async {
    final app = demoModel();
    await app.selectChild(app.profiles.profiles.last);
    expect(app.lessons, hasLength(16));
    expect(
      app.lessons.every((l) => l.ageBands.contains(AgeBand.grade2)),
      isTrue,
    );
  });
  test('explicitly shared lessons are available to both age bands', () {
    final app = demoModel();
    final source = app.content.catalog.lessons.first;
    final shared = Lesson(
      id: 'shared',
      subjectId: 'maths',
      topicId: 'counting',
      title: 'Shared',
      ageBands: [AgeBand.preschool3, AgeBand.grade2],
      steps: source.steps,
    );
    final repo = ContentRepository(ContentCatalog([], [], [shared], []));
    for (final child in app.profiles.profiles) {
      expect(repo.forProfile(child, ParentSettings()), [shared]);
    }
  });
  test('journey is bounded, unique and excludes disabled subjects', () async {
    final app = demoModel();
    await app.selectChild(app.profiles.profiles.first);
    app.settings = ParentSettings(enabledSubjects: {'maths', 'art'});
    final journey = app.journey;
    expect(journey.nodes.length, inInclusiveRange(1, 5));
    expect(
      journey.nodes.map((n) => n.lesson.id).toSet().length,
      journey.nodes.length,
    );
    expect(
      journey.nodes.every(
        (n) => app.settings.enabledSubjects.contains(n.lesson.subjectId),
      ),
      isTrue,
    );
    expect(
      app.lessons.every(
        (l) => app.settings.enabledSubjects.contains(l.subjectId),
      ),
      isTrue,
    );
    app.settings = ParentSettings(enabledSubjects: {});
    expect(app.journey.nodes, isEmpty);
  });
  test(
    'journey includes review and recently practiced concepts when available',
    () async {
      final app = demoModel();
      await app.selectChild(app.profiles.profiles.last);
      final now = DateTime.now();
      app.progress = Progress(
        steps: {'place': 1, 'water': 1},
        mastery: {
          'place': ConceptMastery(attemptCount: 1, lastPracticed: now),
          'water': ConceptMastery(
            attemptCount: 1,
            lastPracticed: now.subtract(const Duration(days: 8)),
          ),
        },
      );
      final journey = app.journey;
      expect(
        journey.nodes.any(
          (n) => n.reason == 'Practice again' && n.lesson.id == 'place',
        ),
        isTrue,
      );
      expect(
        journey.nodes.any(
          (n) => n.reason == 'Review' && n.lesson.id == 'water',
        ),
        isTrue,
      );
    },
  );
  const question = QuizQuestion(
    '1 ? 3',
    [QuizAnswer('2', '2'), QuizAnswer('4', '4')],
    '2',
    'Count one, two, three.',
  );
  test('quiz awards first-attempt score and ignores repeated submissions', () {
    final quiz = QuizEvaluation();
    expect(quiz.answer(question, '2'), isTrue);
    expect(quiz.score, 2);
    quiz.answer(question, '4');
    expect(quiz.incorrectAttempts, 0);
  });
  test('quiz retries gently, offers explanation and gives retry score', () {
    final quiz = QuizEvaluation();
    expect(quiz.answer(question, '4'), isFalse);
    quiz.answer(question, '4');
    expect(quiz.showExplanation, isTrue);
    expect(quiz.answer(question, '2'), isTrue);
    expect(quiz.score, 1);
  });
  test('mastery moves deterministically through learning and review', () {
    final now = DateTime(2026, 10, 25);
    var mastery = const ConceptMastery();
    expect(mastery.state(now), MasteryState.notStarted);
    mastery = mastery.record(correct: false, first: true, now: now);
    expect(mastery.state(now), MasteryState.introduced);
    mastery = mastery.record(correct: true, first: false, now: now);
    expect(mastery.state(now), MasteryState.learning);
    mastery = mastery.record(correct: true, first: true, now: now);
    expect(mastery.state(now), MasteryState.practicing);
    mastery = mastery
        .record(correct: true, first: true, now: now)
        .record(correct: true, first: true, now: now);
    expect(mastery.state(now), MasteryState.mastered);
    expect(
      mastery.state(now.add(const Duration(days: 8))),
      MasteryState.needsReview,
    );
    expect(mastery.correctAfterHint, 1);
    expect(mastery.incorrectAttempts, 1);
  });
  test('matching recognizes configured pairs', () {
    const game = MatchingGameDefinition('animals', {
      'Dog': 'Puppy',
      'Cat': 'Kitten',
    });
    expect(game.matches('Dog', 'Puppy'), isTrue);
    expect(game.matches('Dog', 'Kitten'), isFalse);
    expect(game.matches('Unknown', 'Puppy'), isFalse);
  });
  test('drag drop evaluates categories independently of subject', () {
    const game = DragDropGameDefinition('words', {
      'Run': 'Verb',
      'Garden': 'Noun',
    });
    expect(game.accepts('Run', 'Verb'), isTrue);
    expect(game.accepts('Run', 'Noun'), isFalse);
  });
  test(
    'tracing accepts approximate complete paths and rejects tiny scribble',
    () {
      for (final kind in ['line', 'circle', 'letter']) {
        final path = TracingEvaluator.path(kind);
        expect(TracingEvaluator.completion(path, path), 1);
        expect(TracingEvaluator.completion(path, [path.first]), lessThan(.7));
        expect(TracingEvaluator.completion(path, []), 0);
      }
    },
  );
  test('progress persists completion and remains isolated by child', () async {
    final store = MemoryStore();
    final repo = ProgressRepository(store);
    await repo.save(
      'mia',
      Progress(
        steps: {'colors': 4},
        mastery: {'colors': const ConceptMastery(attemptCount: 1)},
        seconds: {'colors': 120},
      ),
    );
    final loaded = await ProgressRepository(store).load('mia');
    expect(loaded.steps['colors'], 4);
    expect(loaded.minutes, 2);
    expect((await repo.load('arjun')).steps, isEmpty);
  });
  test('corrupt progress and settings recover safely', () async {
    final store = MemoryStore();
    await store.write('progress.mia', 'broken');
    await store.write('settings', '[]');
    expect((await ProgressRepository(store).load('mia')).steps, isEmpty);
    expect((await SettingsRepository(store).load()).dailyTimeGoal, 15);
  });
  test('malformed lessons are skipped while valid lessons remain', () {
    final root =
        jsonDecode(File('assets/content/catalog.json').readAsStringSync())
            as Map<String, dynamic>;
    (root['lessons'] as List).add({'id': 'broken'});
    final catalog = ContentParser().parse(jsonEncode(root));
    expect(catalog.errors, hasLength(1));
    expect(catalog.lessons, hasLength(26));
    expect(() => ContentParser().parse('{'), throwsFormatException);
  });
  test('unknown step becomes safe fallback', () {
    final root =
        jsonDecode(File('assets/content/catalog.json').readAsStringSync())
            as Map<String, dynamic>;
    root['lessons'][0]['steps'][0]['type'] = 'futureActivity';
    expect(
      ContentParser().parse(jsonEncode(root)).lessons.first.steps.first.type,
      ActivityType.unknown,
    );
  });
  test('lesson saves each meaningful step and resumes at next step', () async {
    final app = demoModel();
    await app.selectChild(app.profiles.profiles.first);
    final lesson = app.lessons.first;
    final model = LessonViewModel(app, lesson);
    await model.complete();
    expect(model.index, 1);
    expect(app.progress.steps[lesson.id], 1);
    final resumed = LessonViewModel(app, lesson);
    expect(resumed.index, 1);
    resumed.answer(resumed.step.question!.answers.last.id);
    resumed.answer(resumed.step.question!.correctId);
    await resumed.complete();
    expect(app.progress.mastery[lesson.id]!.correctAfterHint, 1);
    expect(app.progress.mastery[lesson.id]!.incorrectAttempts, 1);
    model.dispose();
    resumed.dispose();
  });
}
