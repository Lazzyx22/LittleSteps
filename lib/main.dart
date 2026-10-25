import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'app/di/app_view_model.dart';
import 'data/repositories/repositories.dart';
import 'data/services/local_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LittleStepsBootstrap());
}

class LittleStepsBootstrap extends StatefulWidget {
  const LittleStepsBootstrap({super.key});
  @override
  State<LittleStepsBootstrap> createState() => _LittleStepsBootstrapState();
}

class _LittleStepsBootstrapState extends State<LittleStepsBootstrap> {
  late Future<AppViewModel> loading = initialize();
  Future<AppViewModel> initialize() async {
    final store = PreferencesStore(await SharedPreferences.getInstance());
    final model = AppViewModel(
      await ContentRepository.load(),
      ProfileRepository(),
      ProgressRepository(store),
      SettingsRepository(store),
    );
    await model.initialize();
    return model;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppViewModel>(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) return LittleStepsApp(model: snapshot.data!);
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Local storage could not start. Please try again.',
                        ),
                        FilledButton(
                          onPressed: () =>
                              setState(() => loading = initialize()),
                          child: const Text('Try again'),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 96),
                        Text('LittleSteps', style: TextStyle(fontSize: 36)),
                        Text('Getting your adventures ready…'),
                        SizedBox(height: 24),
                        CircularProgressIndicator(),
                      ],
                    ),
            ),
          ),
        ),
      );
    },
  );
}
