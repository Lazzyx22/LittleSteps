import 'package:flutter/material.dart';
import '../lessons/lesson_view_model.dart';

class MatchingActivity extends StatelessWidget {
  const MatchingActivity({super.key, required this.model});
  final LessonViewModel model;
  @override
  Widget build(BuildContext context) {
    final game = model.step.matching!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(model.step.text, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final left in game.pairs.keys)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OutlinedButton(
                        onPressed: model.matched.contains(left)
                            ? null
                            : () => model.selectPair(left),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            '${model.matched.contains(left)
                                ? '✓ '
                                : model.selectedLeft == left
                                ? '→ '
                                : ''}$left',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final right in game.pairs.values.toList().reversed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FilledButton.tonal(
                        onPressed:
                            model.selectedLeft == null ||
                                model.matched.any(
                                  (left) => game.pairs[left] == right,
                                )
                            ? null
                            : () => model.match(right),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(right),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DragDropActivity extends StatelessWidget {
  const DragDropActivity({super.key, required this.model});
  final LessonViewModel model;
  Widget item(String text) => Material(
    color: Colors.transparent,
    child: Chip(label: Text(text, style: const TextStyle(fontSize: 24))),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(model.step.text, style: const TextStyle(fontSize: 26)),
      const Text('Drag an item, or tap it and then tap its home.'),
      const SizedBox(height: 20),
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final text in model.step.dragDrop!.categories.keys.where(
            (k) => !model.dropped.contains(k),
          ))
            Draggable<String>(
              data: text,
              feedback: item(text),
              childWhenDragging: Opacity(opacity: .4, child: item(text)),
              child: OutlinedButton(
                onPressed: () => model.selectDragItem(text),
                child: Text('${model.selectedItem == text ? '→ ' : ''}$text'),
              ),
            ),
        ],
      ),
      const SizedBox(height: 24),
      for (final target in model.step.dragDrop!.categories.values.toSet())
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DragTarget<String>(
            onAcceptWithDetails: (details) => model.drop(details.data, target),
            builder: (context, candidates, rejected) => SizedBox(
              height: 104,
              child: FilledButton.tonal(
                onPressed: model.selectedItem == null
                    ? null
                    : () => model.drop(model.selectedItem!, target),
                child: Text(
                  '$target (${model.dropped.where((k) => model.step.dragDrop!.categories[k] == target).length})',
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
