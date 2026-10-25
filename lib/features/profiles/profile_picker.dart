import 'package:flutter/material.dart';
import '../../app/di/app_view_model.dart';
import '../../core/widgets/learning_widgets.dart';

class ProfilePicker extends StatelessWidget {
  const ProfilePicker({
    super.key,
    required this.model,
    required this.onSelected,
  });
  final AppViewModel model;
  final VoidCallback onSelected;
  @override
  Widget build(BuildContext context) => LearningPage(
    title: 'LittleSteps',
    children: [
      const Text(
        'Who is ready to explore?',
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      ),
      const Text('Small discoveries. Big smiles.'),
      for (final child in model.profiles.profiles)
        LearningCard(
          title: child.nickname,
          symbol: child.symbol,
          large: true,
          subtitle: child.isPreschool
              ? 'Play, notice, discover · Age 3'
              : 'Read, reason, create · Grade 2',
          onTap: () async {
            await model.selectChild(child);
            if (context.mounted) onSelected();
          },
        ),
      if (model.content.catalog.errors.isNotEmpty)
        const Text(
          'Some demo content is unavailable. Other activities can still be explored.',
        ),
    ],
  );
}
