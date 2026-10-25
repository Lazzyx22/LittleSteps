import 'package:flutter/material.dart';
import '../../app/di/app_view_model.dart';
import '../../core/widgets/learning_widgets.dart';
import '../../domain/models/models.dart';
import '../games/creative_activities.dart';
import '../games/configured_games.dart';
import 'lesson_view_model.dart';

class LessonRunner extends StatefulWidget {
  const LessonRunner({super.key, required this.app, required this.lesson});
  final AppViewModel app;
  final Lesson lesson;
  @override
  State<LessonRunner> createState() => _LessonRunnerState();
}

class _LessonRunnerState extends State<LessonRunner> {
  late final LessonViewModel model = LessonViewModel(widget.app, widget.lesson);
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      if (model.finished) {
        return LearningPage(
          title: 'A lovely discovery!',
          children: [
            Text(
              model.reward.sticker,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 96),
            ),
            Text(
              '${model.reward.stars} learning star · ${model.reward.achievement}',
            ),
            Text('You explored ${widget.lesson.title}.'),
            const Text(
              'You kept trying and made a discovery. Now is a good time to stretch or play away from the screen.',
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to adventures'),
            ),
          ],
        );
      }
      if (widget.app.sessionLimitReached) {
        return LearningPage(
          title: 'Time for a little break',
          children: [
            const Text(
              'Your adventure is saved. Stretch, rest your eyes, and ask a grown-up when to return.',
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Finish for now'),
            ),
          ],
        );
      }
      return LearningPage(
        title: widget.lesson.title,
        children: [
          Text('Step ${model.index + 1} of ${widget.lesson.steps.length}'),
          LinearProgressIndicator(
            value: model.index / widget.lesson.steps.length,
            semanticsLabel: 'Lesson progress',
          ),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.app.media.audioUnavailable)),
            ),
            icon: const Icon(Icons.volume_up),
            label: const Text('Listen with a grown-up'),
          ),
          StepRenderer(key: ValueKey(model.index), model: model),
          if (model.feedback.isNotEmpty)
            Semantics(
              liveRegion: true,
              child: Text(model.feedback, style: const TextStyle(fontSize: 24)),
            ),
          if (![
            ActivityType.tracing,
            ActivityType.coloring,
          ].contains(model.step.type))
            FilledButton(
              onPressed: model.ready && !model.busy ? model.complete : null,
              child: Text(
                model.busy
                    ? 'Saving…'
                    : model.step.type == ActivityType.offlineActivity
                    ? 'Done'
                    : 'Next',
              ),
            ),
        ],
      );
    },
  );
}

class StepRenderer extends StatelessWidget {
  const StepRenderer({super.key, required this.model});
  final LessonViewModel model;
  @override
  Widget build(BuildContext context) {
    final step = model.step;
    return switch (step.type) {
      ActivityType.mcq ||
      ActivityType.imageChoice => QuizActivity(model: model),
      ActivityType.matching => MatchingActivity(model: model),
      ActivityType.dragDrop => DragDropActivity(model: model),
      ActivityType.tracing => TracingActivity(
        kind: step.path,
        prompt: step.text,
        onComplete: model.complete,
        saving: model.busy,
      ),
      ActivityType.coloring => ColoringActivity(
        prompt: step.text,
        onComplete: model.complete,
        saving: model.busy,
      ),
      ActivityType.video || ActivityType.animation => Column(
        children: [
          const Icon(Icons.auto_awesome, size: 100),
          const SizedBox(height: 24),
          Text(step.text, style: const TextStyle(fontSize: 26)),
          if (step.type == ActivityType.video)
            Text(model.app.media.videoUnavailable),
        ],
      ),
      ActivityType.story || ActivityType.offlineActivity => Column(
        children: [
          Icon(
            step.type == ActivityType.story ? Icons.menu_book : Icons.park,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(step.text, style: const TextStyle(fontSize: 26)),
        ],
      ),
      _ => const Text(
        'This activity is not available yet. You can continue to the next discovery.',
      ),
    };
  }
}

class QuizActivity extends StatelessWidget {
  const QuizActivity({super.key, required this.model});
  final LessonViewModel model;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        model.step.question!.prompt,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 24),
      for (final answer in model.step.question!.answers)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            height: model.app.child!.isPreschool ? 104 : 72,
            child: FilledButton.tonal(
              onPressed: model.quiz.solved
                  ? null
                  : () => model.answer(answer.id),
              child: Text(answer.text, style: const TextStyle(fontSize: 26)),
            ),
          ),
        ),
    ],
  );
}
