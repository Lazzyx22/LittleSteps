import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';

class LearningPage extends StatelessWidget {
  const LearningPage({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
  });
  final String title;
  final List<Widget> children, actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView(
            padding: const EdgeInsets.all(Tokens.spacing),
            children: children
                .expand((w) => [w, const SizedBox(height: Tokens.spacing)])
                .toList(),
          ),
        ),
      ),
    ),
  );
}

class LearningCard extends StatelessWidget {
  const LearningCard({
    super.key,
    required this.title,
    required this.symbol,
    required this.onTap,
    this.large = false,
    this.subtitle,
  });
  final String title, symbol;
  final String? subtitle;
  final VoidCallback onTap;
  final bool large;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: title,
    child: Card(
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radius),
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: large ? 144 : 96),
          child: Padding(
            padding: const EdgeInsets.all(Tokens.spacing),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Text(
                    symbol,
                    style: TextStyle(fontSize: large ? 52 : 36),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (subtitle != null) Text(subtitle!),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class SafeIllustration extends StatelessWidget {
  const SafeIllustration({
    super.key,
    required this.asset,
    this.label = 'Learning illustration',
  });
  final String asset, label;
  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    semanticLabel: label,
    errorBuilder: (_, error, stack) => Semantics(
      label: label,
      child: const Icon(Icons.auto_awesome, size: 96),
    ),
  );
}
