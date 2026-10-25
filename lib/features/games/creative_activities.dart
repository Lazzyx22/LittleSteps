import 'package:flutter/material.dart';
import '../../domain/use_cases/learning.dart';

class TracingActivity extends StatefulWidget {
  const TracingActivity({
    super.key,
    required this.kind,
    required this.prompt,
    required this.onComplete,
    this.tolerance = .09,
    this.saving = false,
  });
  final String kind, prompt;
  final VoidCallback onComplete;
  final double tolerance;
  final bool saving;
  @override
  State<TracingActivity> createState() => _TracingActivityState();
}

class _TracingActivityState extends State<TracingActivity> {
  final List<TracePoint> input = [];
  double get completion => TracingEvaluator.completion(
    TracingEvaluator.path(widget.kind),
    input,
    tolerance: widget.tolerance,
  );
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(widget.prompt),
      const Text('Start at the dot. Follow the path with your finger.'),
      AspectRatio(
        aspectRatio: 1.2,
        child: LayoutBuilder(
          builder: (context, constraints) => Semantics(
            label:
                'Tracing canvas, ${(completion * 100).round()} percent explored',
            child: GestureDetector(
              onPanStart: (details) => add(details.localPosition, constraints),
              onPanUpdate: (details) => add(details.localPosition, constraints),
              child: CustomPaint(
                size: Size.infinite,
                painter: _TracePainter(
                  TracingEvaluator.path(widget.kind),
                  input,
                ),
              ),
            ),
          ),
        ),
      ),
      Text('${(completion * 100).round()}% explored'),
      TextButton(
        onPressed: () => setState(input.clear),
        child: const Text('Start again'),
      ),
      FilledButton(
        onPressed: completion >= .7 && !widget.saving
            ? widget.onComplete
            : null,
        child: Text(widget.saving ? 'Saving…' : 'I traced it'),
      ),
    ],
  );
  void add(Offset offset, BoxConstraints constraints) => setState(() {
    input.add(
      TracePoint(
        (offset.dx / constraints.maxWidth).clamp(0, 1),
        (offset.dy / constraints.maxHeight).clamp(0, 1),
      ),
    );
  });
}

class _TracePainter extends CustomPainter {
  _TracePainter(this.path, this.input);
  final List<TracePoint> path, input;
  Offset position(TracePoint p, Size size) =>
      Offset(p.x * size.width, p.y * size.height);
  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = Colors.blueGrey.shade200
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < path.length; i++) {
      canvas.drawLine(
        position(path[i - 1], size),
        position(path[i], size),
        guide,
      );
    }
    canvas.drawCircle(
      position(path.first, size),
      14,
      Paint()..color = Colors.deepOrange,
    );
    final ink = Paint()
      ..color = Colors.teal
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (final p in input) {
      canvas.drawCircle(position(p, size), 5, ink);
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) => true;
}

class ColoringActivity extends StatefulWidget {
  const ColoringActivity({
    super.key,
    required this.prompt,
    required this.onComplete,
    this.saving = false,
  });
  final String prompt;
  final VoidCallback onComplete;
  final bool saving;
  @override
  State<ColoringActivity> createState() => _ColoringActivityState();
}

class _ColoringActivityState extends State<ColoringActivity> {
  final List<Color> history = [Colors.white];
  Color selected = Colors.red;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(widget.prompt),
      const Text('Choose a color. Tap the balloon to fill it.'),
      Wrap(
        spacing: 12,
        children: [
          for (final entry in {
            'Red': Colors.red,
            'Blue': Colors.blue,
            'Yellow': Colors.yellow,
            'Green': Colors.green,
            'Purple': Colors.purple,
          }.entries)
            Semantics(
              selected: selected == entry.value,
              child: OutlinedButton(
                onPressed: () => setState(() => selected = entry.value),
                child: Text(entry.key),
              ),
            ),
        ],
      ),
      const SizedBox(height: 20),
      Semantics(
        button: true,
        label: 'Fill balloon with selected color',
        child: InkWell(
          onTap: () => setState(() => history.add(selected)),
          child: Container(
            width: 210,
            height: 230,
            decoration: BoxDecoration(
              color: history.last,
              border: Border.all(width: 4),
              borderRadius: BorderRadius.circular(110),
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, size: 56, color: Colors.black),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 16,
        children: [
          TextButton(
            onPressed: history.length > 1
                ? () => setState(() => history.removeLast())
                : null,
            child: const Text('Undo'),
          ),
          TextButton(
            onPressed: () => setState(() => history.add(Colors.white)),
            child: const Text('Reset'),
          ),
        ],
      ),
      FilledButton(
        onPressed:
            history.any((color) => color != Colors.white) && !widget.saving
            ? widget.onComplete
            : null,
        child: Text(widget.saving ? 'Saving…' : 'My picture is ready'),
      ),
    ],
  );
}
