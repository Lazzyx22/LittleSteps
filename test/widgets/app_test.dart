import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_steps/app/app.dart';
import 'package:little_steps/app/router.dart';
import 'package:little_steps/core/widgets/learning_widgets.dart';
import 'package:little_steps/features/home/child_screens.dart';
import 'package:little_steps/features/lessons/lesson_runner.dart';
import 'package:little_steps/features/parent/parent_screens.dart';
import '../helpers.dart';

void main() {
  testWidgets('missing image renders safe placeholder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SafeIllustration(asset: 'assets/missing.png')),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('leaving nested parent settings relocks underlying dashboard', (
    tester,
  ) async {
    final app = demoModel();
    await app.selectChild(app.profiles.profiles.first);
    app.unlockParent();
    await tester.pumpWidget(MaterialApp(home: ParentArea(model: app)));
    await tester.ensureVisible(find.text('Parent settings'));
    await tester.tap(find.text('Parent settings'));
    await tester.pumpAndSettle();
    expect(find.byType(ParentSettingsScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Grown-ups only'), findsOneWidget);
    expect(find.byType(ParentDashboard), findsNothing);
  });
  testWidgets('profile picker renders and selects preschool home', (
    tester,
  ) async {
    final app = demoModel();
    await tester.pumpWidget(LittleStepsApp(model: app));
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Arjun'), findsOneWidget);
    await tester.tap(find.text('Mia'));
    await tester.pumpAndSettle();
    expect(find.text('☀ Hello, Mia!'), findsOneWidget);
  });
  testWidgets('preschool home uses large cards', (tester) async {
    final app = demoModel();
    await app.selectChild(app.profiles.profiles.first);
    await tester.pumpWidget(MaterialApp(home: ChildHome(model: app)));
    final cards = tester.widgetList<LearningCard>(find.byType(LearningCard));
    expect(cards, isNotEmpty);
    expect(cards.every((c) => c.large), isTrue);
  });
  testWidgets('lesson runner advances after activity and quiz shows choices', (
    tester,
  ) async {
    final app = demoModel();
    await app.selectChild(app.profiles.profiles.first);
    await tester.pumpWidget(
      MaterialApp(
        home: LessonRunner(app: app, lesson: app.lessons.first),
      ),
    );
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Which one is red?'), findsOneWidget);
    expect(find.text('🔴 Red'), findsOneWidget);
    expect(find.text('🔵 Blue'), findsOneWidget);
    await tester.ensureVisible(find.text('🔴 Red'));
    await tester.tap(find.text('🔴 Red'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose a color. Tap the balloon to fill it.'),
      findsOneWidget,
    );
  });
  testWidgets('parent route blocks dashboard and settings', (tester) async {
    final app = demoModel();
    await app.selectChild(app.profiles.profiles.first);
    final router = AppRouter(app);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: router.generate,
        initialRoute: AppRoutes.settings,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Grown-ups only'), findsOneWidget);
    expect(find.byType(ParentSettingsScreen), findsNothing);
    expect(find.byType(ParentDashboard), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });
  testWidgets('parent hold and arithmetic unlock then background relocks', (
    tester,
  ) async {
    final app = demoModel();
    await app.selectChild(app.profiles.profiles.first);
    await tester.pumpWidget(MaterialApp(home: ParentArea(model: app)));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Hold here for 2 seconds')),
    );
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();
    final sum = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((s) => s.startsWith('What is'));
    final numbers = RegExp(
      r'\d+',
    ).allMatches(sum).map((m) => int.parse(m.group(0)!)).toList();
    await tester.enterText(
      find.byType(TextField),
      '${numbers[0] + numbers[1]}',
    );
    await tester.ensureVisible(find.text('Open parent area'));
    await tester.tap(find.text('Open parent area'));
    await tester.pumpAndSettle();
    expect(find.text('Parent dashboard'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(app.parentUnlocked, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Grown-ups only'), findsOneWidget);
  });
  testWidgets('missing lesson is safe and does not expose another age band', (
    tester,
  ) async {
    final app = demoModel();
    await app.selectChild(app.profiles.profiles.first);
    final router = AppRouter(app);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              router.generate(
                const RouteSettings(name: AppRoutes.lesson, arguments: 'nouns'),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Adventure unavailable'), findsOneWidget);
  });
}
