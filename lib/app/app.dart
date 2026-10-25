import 'package:flutter/material.dart';
import 'di/app_view_model.dart';
import 'router.dart';
import 'theme/tokens.dart';

class LittleStepsApp extends StatelessWidget {
  const LittleStepsApp({super.key, required this.model});
  final AppViewModel model;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => MaterialApp(
      title: 'LittleSteps',
      debugShowCheckedModeBanner: false,
      theme: Tokens.theme(),
      initialRoute: AppRoutes.profiles,
      onGenerateRoute: AppRouter(model).generate,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations:
              model.settings.reducedMotion ||
              MediaQuery.of(context).disableAnimations,
        ),
        child: child!,
      ),
    ),
  );
}
