import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/di/app_view_model.dart';
import '../../core/widgets/learning_widgets.dart';
import '../../domain/models/models.dart';

class ParentArea extends StatefulWidget {
  const ParentArea({
    super.key,
    required this.model,
    this.settingsFirst = false,
  });
  final AppViewModel model;
  final bool settingsFirst;
  @override
  State<ParentArea> createState() => _ParentAreaState();
}

class _ParentAreaState extends State<ParentArea> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.model.parentUnlocked = false;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) widget.model.lockParent();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) => !widget.model.parentUnlocked
        ? ParentGate(onUnlocked: widget.model.unlockParent)
        : Theme(
            data: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
              textTheme: Theme.of(context).textTheme,
            ),
            child: widget.settingsFirst
                ? ParentSettingsScreen(model: widget.model)
                : ParentDashboard(model: widget.model),
          ),
  );
}

class ParentGate extends StatefulWidget {
  const ParentGate({super.key, required this.onUnlocked});
  final VoidCallback onUnlocked;
  @override
  State<ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<ParentGate> {
  final answer = TextEditingController();
  late final int a = 12 + Random().nextInt(12), b = 7 + Random().nextInt(9);
  Timer? hold;
  bool held = false;
  String feedback = '';
  @override
  void dispose() {
    hold?.cancel();
    answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LearningPage(
    title: 'Grown-ups only',
    children: [
      const Text('Please ask a grown-up to open this area.'),
      Semantics(
        label: 'Hold for two seconds to begin adult check',
        button: true,
        child: Listener(
          onPointerDown: (_) {
            hold?.cancel();
            hold = Timer(const Duration(seconds: 2), () {
              if (mounted) setState(() => held = true);
            });
          },
          onPointerUp: (_) => hold?.cancel(),
          onPointerCancel: (_) => hold?.cancel(),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.indigo.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(held ? 'Adult check ready' : 'Hold here for 2 seconds'),
          ),
        ),
      ),
      if (held) ...[
        Text('What is $a + $b?'),
        TextField(
          controller: answer,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Adult answer'),
        ),
        FilledButton(
          onPressed: () {
            if (int.tryParse(answer.text.trim()) == a + b) {
              widget.onUnlocked();
            } else {
              setState(() => feedback = 'Please try that sum again.');
            }
          },
          child: const Text('Open parent area'),
        ),
      ],
      if (feedback.isNotEmpty)
        Semantics(liveRegion: true, child: Text(feedback)),
    ],
  );
}

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key, required this.model});
  final AppViewModel model;
  @override
  Widget build(BuildContext context) {
    final practiced = model.content.catalog.lessons
        .where((l) => model.progress.steps.containsKey(l.id))
        .toList();
    final completed = practiced
        .where((l) => (model.progress.steps[l.id] ?? 0) >= l.steps.length)
        .length;
    final review = practiced.where(
      (l) =>
          model.progress.mastery[l.id]?.state(DateTime.now()) ==
          MasteryState.needsReview,
    );
    return LearningPage(
      title: 'Parent dashboard',
      children: [
        Text(
          'Explorer: ${model.child!.nickname}',
          style: const TextStyle(fontSize: 28),
        ),
        Text(
          '${model.progress.minutes} active minutes · ${model.progress.activityCount} unique activities · $completed completed lessons',
        ),
        Text(
          'Daily goal: ${model.settings.dailyTimeGoal} minutes. A guide, never a requirement.',
        ),
        const Text('Recently practiced subjects'),
        for (final id in practiced.map((l) => l.subjectId).toSet())
          Text(
            model.content.catalog.subjects.firstWhere((s) => s.id == id).title,
          ),
        const Text('Concepts to revisit'),
        for (final l in review) Text(l.title),
        if (review.isEmpty) const Text('No review suggestions yet.'),
        const Text(
          'Mastery is a simple demo heuristic, not a validated assessment.',
        ),
        FilledButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ParentArea(model: model, settingsFirst: true),
            ),
          ),
          child: const Text('Parent settings'),
        ),
        OutlinedButton(
          onPressed: () {
            model.lockParent();
            Navigator.pop(context);
          },
          child: const Text('Return to child mode'),
        ),
      ],
    );
  }
}

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key, required this.model});
  final AppViewModel model;
  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  late int daily = widget.model.settings.dailyTimeGoal,
      session = widget.model.settings.maxSessionLength;
  late Set<String> enabled = {...widget.model.settings.enabledSubjects};
  late String language = widget.model.settings.language;
  late bool sound = widget.model.settings.soundEffects,
      motion = widget.model.settings.reducedMotion;
  bool saving = false;
  @override
  Widget build(BuildContext context) => LearningPage(
    title: 'Parent settings',
    children: [
      Text('Daily time goal: $daily minutes'),
      Slider(
        value: daily.toDouble(),
        min: 5,
        max: 60,
        divisions: 11,
        label: '$daily minutes',
        onChanged: (v) => setState(() => daily = v.round()),
      ),
      Text('Maximum session: $session minutes'),
      Slider(
        value: session.toDouble(),
        min: 5,
        max: 60,
        divisions: 11,
        label: '$session minutes',
        onChanged: (v) => setState(() => session = v.round()),
      ),
      const Text('Enabled subjects'),
      for (final s in widget.model.content.catalog.subjects)
        CheckboxListTile(
          title: Text(s.title),
          value: enabled.contains(s.id),
          onChanged: (v) =>
              setState(() => v! ? enabled.add(s.id) : enabled.remove(s.id)),
        ),
      DropdownButtonFormField<String>(
        initialValue: language,
        decoration: const InputDecoration(labelText: 'Language preference'),
        items: const [
          DropdownMenuItem(value: 'English', child: Text('English')),
          DropdownMenuItem(value: 'Hindi', child: Text('हिन्दी')),
        ],
        onChanged: (v) => setState(() => language = v!),
      ),
      const Text(
        'Language preference is saved. Demo lessons include Hindi entries; the full interface and audio are not translated yet.',
      ),
      SwitchListTile(
        title: const Text('Sound effects'),
        subtitle: const Text(
          'Saved for future recorded sounds; this demo is silent.',
        ),
        value: sound,
        onChanged: (v) => setState(() => sound = v),
      ),
      SwitchListTile(
        title: const Text('Reduced motion'),
        value: motion,
        onChanged: (v) => setState(() => motion = v),
      ),
      if (widget.model.error != null) Text(widget.model.error!),
      FilledButton(
        onPressed: saving
            ? null
            : () async {
                setState(() => saving = true);
                final ok = await widget.model.saveSettings(
                  ParentSettings(
                    dailyTimeGoal: daily,
                    maxSessionLength: session,
                    enabledSubjects: enabled,
                    language: language,
                    soundEffects: sound,
                    reducedMotion: motion,
                  ),
                );
                if (context.mounted) {
                  setState(() => saving = false);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved locally')),
                    );
                  }
                }
              },
        child: Text(saving ? 'Saving…' : 'Save settings'),
      ),
    ],
  );
}
