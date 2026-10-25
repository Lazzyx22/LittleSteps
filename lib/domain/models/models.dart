enum AgeBand { preschool3, preschool4To5, grade1, grade2 }

enum ActivityType {
  video,
  animation,
  story,
  mcq,
  imageChoice,
  matching,
  dragDrop,
  tracing,
  coloring,
  connectDots,
  balloon,
  sequencing,
  offlineActivity,
  unknown,
}

enum MasteryState {
  notStarted,
  introduced,
  learning,
  practicing,
  mastered,
  needsReview,
}

class ChildProfile {
  const ChildProfile(
    this.id,
    this.nickname,
    this.ageBand,
    this.symbol, {
    this.languages = const ['English', 'Hindi'],
  });
  final String id, nickname, symbol;
  final AgeBand ageBand;
  final List<String> languages;
  bool get isPreschool =>
      ageBand == AgeBand.preschool3 || ageBand == AgeBand.preschool4To5;
}

class Subject {
  const Subject(this.id, this.title, this.symbol);
  final String id, title, symbol;
}

class Topic {
  const Topic(this.id, this.subjectId, this.title);
  final String id, subjectId, title;
}

class QuizAnswer {
  const QuizAnswer(this.id, this.text);
  final String id, text;
}

class QuizQuestion {
  const QuizQuestion(
    this.prompt,
    this.answers,
    this.correctId,
    this.explanation,
  );
  final String prompt, correctId, explanation;
  final List<QuizAnswer> answers;
}

class GameDefinition {
  const GameDefinition(this.id);
  final String id;
}

class MatchingGameDefinition extends GameDefinition {
  const MatchingGameDefinition(super.id, this.pairs);
  final Map<String, String> pairs;
  bool matches(String left, String right) => pairs[left] == right;
}

class DragDropGameDefinition extends GameDefinition {
  const DragDropGameDefinition(super.id, this.categories);
  final Map<String, String> categories;
  bool accepts(String item, String target) => categories[item] == target;
}

class LessonStep {
  const LessonStep({
    required this.type,
    required this.text,
    this.question,
    this.matching,
    this.dragDrop,
    this.path = 'line',
  });
  final ActivityType type;
  final String text, path;
  final QuizQuestion? question;
  final MatchingGameDefinition? matching;
  final DragDropGameDefinition? dragDrop;
}

class Lesson {
  Lesson({
    required this.id,
    required this.subjectId,
    required this.topicId,
    required this.title,
    required List<AgeBand> ageBands,
    required List<LessonStep> steps,
    List<String> objectives = const [],
    this.difficulty = 1,
    this.estimatedMinutes = 3,
  }) : ageBands = List.unmodifiable(ageBands),
       steps = List.unmodifiable(steps),
       objectives = List.unmodifiable(objectives);
  final String id, subjectId, topicId, title;
  final List<AgeBand> ageBands;
  final List<LessonStep> steps;
  final List<String> objectives;
  final int difficulty, estimatedMinutes;
}

class ConceptMastery {
  const ConceptMastery({
    this.attemptCount = 0,
    this.correctFirstAttempt = 0,
    this.correctAfterHint = 0,
    this.incorrectAttempts = 0,
    this.lastPracticed,
  });
  final int attemptCount,
      correctFirstAttempt,
      correctAfterHint,
      incorrectAttempts;
  final DateTime? lastPracticed;
  MasteryState state(DateTime now) {
    if (attemptCount == 0) return MasteryState.notStarted;
    if (lastPracticed != null && now.difference(lastPracticed!).inDays >= 7)
      return MasteryState.needsReview;
    if (correctFirstAttempt >= 3) return MasteryState.mastered;
    if (correctFirstAttempt + correctAfterHint >= 2)
      return MasteryState.practicing;
    if (correctFirstAttempt + correctAfterHint > 0)
      return MasteryState.learning;
    return MasteryState.introduced;
  }

  ConceptMastery record({
    required bool correct,
    required bool first,
    required DateTime now,
  }) => ConceptMastery(
    attemptCount: attemptCount + 1,
    correctFirstAttempt: correctFirstAttempt + (correct && first ? 1 : 0),
    correctAfterHint: correctAfterHint + (correct && !first ? 1 : 0),
    incorrectAttempts: incorrectAttempts + (!correct ? 1 : 0),
    lastPracticed: now,
  );
  Map<String, dynamic> toJson() => {
    'attempts': attemptCount,
    'first': correctFirstAttempt,
    'hint': correctAfterHint,
    'wrong': incorrectAttempts,
    'last': lastPracticed?.toIso8601String(),
  };
  factory ConceptMastery.fromJson(Map<String, dynamic> j) => ConceptMastery(
    attemptCount: j['attempts'] as int,
    correctFirstAttempt: j['first'] as int,
    correctAfterHint: j['hint'] as int,
    incorrectAttempts: j['wrong'] as int,
    lastPracticed: j['last'] == null
        ? null
        : DateTime.parse(j['last'] as String),
  );
}

class Progress {
  Progress({
    Map<String, int> steps = const {},
    Map<String, ConceptMastery> mastery = const {},
    Map<String, int> seconds = const {},
  }) : steps = Map.unmodifiable(steps),
       mastery = Map.unmodifiable(mastery),
       seconds = Map.unmodifiable(seconds);
  final Map<String, int> steps, seconds;
  final Map<String, ConceptMastery> mastery;
  int get activityCount => steps.values.fold(0, (a, b) => a + b);
  int get minutes => seconds.values.fold(0, (a, b) => a + b) ~/ 60;
}

class JourneyNode {
  const JourneyNode(this.lesson, this.reason);
  final Lesson lesson;
  final String reason;
}

class Journey {
  Journey(List<JourneyNode> nodes) : nodes = List.unmodifiable(nodes);
  final List<JourneyNode> nodes;
}

class ParentSettings {
  ParentSettings({
    this.dailyTimeGoal = 15,
    this.maxSessionLength = 20,
    Set<String> enabledSubjects = const {
      'english',
      'maths',
      'hindi',
      'science',
      'world',
      'life',
      'stories',
      'art',
    },
    this.language = 'English',
    this.soundEffects = true,
    this.reducedMotion = false,
  }) : enabledSubjects = Set.unmodifiable(enabledSubjects);
  final int dailyTimeGoal, maxSessionLength;
  final Set<String> enabledSubjects;
  final String language;
  final bool soundEffects, reducedMotion;
  Map<String, dynamic> toJson() => {
    'daily': dailyTimeGoal,
    'session': maxSessionLength,
    'subjects': enabledSubjects.toList(),
    'language': language,
    'sound': soundEffects,
    'motion': reducedMotion,
  };
  factory ParentSettings.fromJson(Map<String, dynamic> j) => ParentSettings(
    dailyTimeGoal: (j['daily'] as int).clamp(5, 60),
    maxSessionLength: (j['session'] as int).clamp(5, 60),
    enabledSubjects: (j['subjects'] as List).cast<String>().toSet(),
    language: j['language'] as String,
    soundEffects: j['sound'] as bool,
    reducedMotion: j['motion'] as bool,
  );
}

class LearningReward {
  const LearningReward(this.stars, this.sticker, this.achievement);
  final int stars;
  final String sticker, achievement;
}
