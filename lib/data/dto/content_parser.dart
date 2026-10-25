import 'dart:convert';
import '../../domain/models/models.dart';

class ContentCatalog {
  ContentCatalog(this.subjects, this.topics, this.lessons, this.errors);
  final List<Subject> subjects;
  final List<Topic> topics;
  final List<Lesson> lessons;
  final List<String> errors;
}

class ContentParser {
  ContentCatalog parse(String source) {
    final errors = <String>[];
    final root = jsonDecode(source) as Map<String, dynamic>;
    final subjects = (root['subjects'] as List)
        .map(
          (s) => Subject(
            s['id'] as String,
            s['title'] as String,
            s['symbol'] as String,
          ),
        )
        .toList();
    final topics = (root['topics'] as List)
        .map(
          (t) => Topic(
            t['id'] as String,
            t['subjectId'] as String,
            t['title'] as String,
          ),
        )
        .toList();
    final lessons = <Lesson>[];
    for (final raw in root['lessons'] as List) {
      try {
        final j = raw as Map<String, dynamic>;
        final id = j['id'] as String;
        final bands = (j['ageBands'] as List)
            .map((v) => AgeBand.values.byName(v as String))
            .toList();
        final steps = (j['steps'] as List)
            .map((s) => _step(s as Map<String, dynamic>))
            .toList();
        if (steps.isEmpty ||
            bands.isEmpty ||
            lessons.any((l) => l.id == id) ||
            !topics.any(
              (t) => t.id == j['topicId'] && t.subjectId == j['subjectId'],
            ))
          throw const FormatException(
            'Invalid references, duplicate ID, or empty content',
          );
        lessons.add(
          Lesson(
            id: id,
            subjectId: j['subjectId'] as String,
            topicId: j['topicId'] as String,
            title: j['title'] as String,
            ageBands: bands,
            steps: steps,
            objectives: (j['objectives'] as List? ?? []).cast<String>(),
            difficulty: j['difficulty'] as int? ?? 1,
            estimatedMinutes: j['estimatedMinutes'] as int? ?? 3,
          ),
        );
      } catch (error) {
        errors.add(
          'Skipped lesson ${raw is Map ? raw['id'] : '(unknown)'}: $error',
        );
      }
    }
    return ContentCatalog(
      List.unmodifiable(subjects),
      List.unmodifiable(topics),
      List.unmodifiable(lessons),
      List.unmodifiable(errors),
    );
  }

  LessonStep _step(Map<String, dynamic> j) {
    final type =
        ActivityType.values.where((v) => v.name == j['type']).firstOrNull ??
        ActivityType.unknown;
    QuizQuestion? question;
    if (type == ActivityType.mcq || type == ActivityType.imageChoice) {
      final q = j['question'] as Map<String, dynamic>;
      final answers = (q['answers'] as List)
          .map((a) => QuizAnswer(a['id'] as String, a['text'] as String))
          .toList();
      if (answers.length < 2 ||
          answers.map((a) => a.id).toSet().length != answers.length ||
          !answers.any((a) => a.id == q['correctId']))
        throw const FormatException('Invalid quiz answers');
      question = QuizQuestion(
        q['prompt'] as String,
        List.unmodifiable(answers),
        q['correctId'] as String,
        q['explanation'] as String,
      );
    }
    final pairs = j['pairs'] == null
        ? null
        : Map<String, String>.from(j['pairs'] as Map);
    final categories = j['categories'] == null
        ? null
        : Map<String, String>.from(j['categories'] as Map);
    if (type == ActivityType.matching &&
        (pairs == null ||
            pairs.isEmpty ||
            pairs.values.toSet().length != pairs.length))
      throw const FormatException('Matching needs distinct pairs');
    if (type == ActivityType.dragDrop &&
        (categories == null || categories.isEmpty))
      throw const FormatException('Drag/drop needs items');
    return LessonStep(
      type: type,
      text: j['text'] as String? ?? '',
      question: question,
      matching: pairs == null
          ? null
          : MatchingGameDefinition('inline', Map.unmodifiable(pairs)),
      dragDrop: categories == null
          ? null
          : DragDropGameDefinition('inline', Map.unmodifiable(categories)),
      path: j['path'] as String? ?? 'line',
    );
  }
}
