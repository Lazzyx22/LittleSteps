import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/models/models.dart';
import '../dto/content_parser.dart';
import '../services/local_store.dart';

class ContentRepository {
  ContentRepository(this.catalog);
  final ContentCatalog catalog;
  static Future<ContentRepository> load() async {
    try {
      final catalog = ContentParser().parse(
        await rootBundle.loadString('assets/content/catalog.json'),
      );
      for (final error in catalog.errors) {
        debugPrint(error);
      }
      return ContentRepository(catalog);
    } catch (error) {
      debugPrint('Content could not be loaded: $error');
      return ContentRepository(
        ContentCatalog([], [], [], [
          'Content is unavailable. Please ask an adult to restart.',
        ]),
      );
    }
  }

  List<Lesson> forProfile(ChildProfile profile, ParentSettings settings) =>
      catalog.lessons
          .where(
            (l) =>
                l.ageBands.contains(profile.ageBand) &&
                settings.enabledSubjects.contains(l.subjectId),
          )
          .toList();
}

class ProfileRepository {
  final List<ChildProfile> profiles = const [
    ChildProfile('mia', 'Mia', AgeBand.preschool3, '☀'),
    ChildProfile('arjun', 'Arjun', AgeBand.grade2, '🚀'),
  ];
}

class ProgressRepository {
  ProgressRepository(this.store);
  final LocalStore store;
  final Map<String, Progress> _cache = {};
  Future<Progress> load(String child) async {
    if (_cache.containsKey(child)) return _cache[child]!;
    try {
      final raw = await store.read('progress.$child');
      if (raw == null) return _cache[child] = Progress();
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final steps = Map<String, int>.from(j['steps'] as Map);
      final seconds = Map<String, int>.from(j['seconds'] as Map? ?? {});
      if (steps.values.any((n) => n < 0) || seconds.values.any((n) => n < 0))
        throw const FormatException('Negative progress');
      return _cache[child] = Progress(
        steps: steps,
        seconds: seconds,
        mastery: (j['mastery'] as Map<String, dynamic>).map(
          (k, v) =>
              MapEntry(k, ConceptMastery.fromJson(v as Map<String, dynamic>)),
        ),
      );
    } catch (error) {
      debugPrint('Saved progress unavailable for $child: $error');
      return _cache[child] = Progress();
    }
  }

  Future<void> save(String child, Progress progress) async {
    await store.write(
      'progress.$child',
      jsonEncode({
        'steps': progress.steps,
        'seconds': progress.seconds,
        'mastery': progress.mastery.map((k, v) => MapEntry(k, v.toJson())),
      }),
    );
    _cache[child] = progress;
  }
}

class SettingsRepository {
  SettingsRepository(this.store);
  final LocalStore store;
  Future<ParentSettings> load() async {
    try {
      final raw = await store.read('settings');
      return raw == null
          ? ParentSettings()
          : ParentSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error) {
      debugPrint('Settings reset: $error');
      return ParentSettings();
    }
  }

  Future<void> save(ParentSettings settings) =>
      store.write('settings', jsonEncode(settings.toJson()));
}
