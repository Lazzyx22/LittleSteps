import 'parent_gate_view_model.dart';
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
    // Notify any parent route underneath after navigation finishes disposing us.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.model.lockParent(),
    );
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
  late final model = ParentGateViewModel(widget.onUnlocked);
  @override
  void dispose() {
    model.dispose();
    answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => LearningPage(
      title: 'Grown-ups only',
      children: [
        const Text('Please ask a grown-up to open this area.'),
        Semantics(
          label: 'Hold for two seconds to begin adult check',
          button: true,
          child: Listener(
            onPointerDown: (_) => model.startHold(),
            onPointerUp: (_) => model.cancelHold(),
            onPointerCancel: (_) => model.cancelHold(),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                model.held ? 'Adult check ready' : 'Hold here for 2 seconds',
              ),
            ),
          ),
        ),
        if (model.held) ...[
          Text('What is ${model.a} + ${model.b}?'),
          TextField(
            controller: answer,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Adult answer'),
          ),
          FilledButton(
            onPressed: () => model.submit(answer.text),
            child: const Text('Open parent area'),
          ),
        ],
        if (model.feedback.isNotEmpty)
          Semantics(liveRegion: true, child: Text(model.feedback)),
      ],
    ),
  );
}

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key, required this.model});
  final AppViewModel model;
  @override
  Widget build(BuildContext context) {
    final completed = model.completedLessonCount;
    final review = model.reviewLessons;
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
        for (final subject in model.practicedSubjects) Text(subject.title),
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
