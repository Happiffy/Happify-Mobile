import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/happify_colors.dart';
import 'quokka_badge.dart';

class HappifyPage extends StatelessWidget {
  const HappifyPage({
    required this.children,
    this.title,
    this.actions,
    this.refresh,
    super.key,
  });

  final String? title;
  final List<Widget> children;
  final List<Widget>? actions;
  final Future<void> Function()? refresh;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
      children: [
        if (title != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              ...?actions,
            ],
          ),
        if (title != null) const SizedBox(height: 18),
        ...children,
      ],
    );
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: refresh == null
              ? content
              : RefreshIndicator(onRefresh: refresh!, child: content),
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    required this.child,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD9D9D9), offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: body,
      ),
    );
  }
}

class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    required this.loading,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.child,
    this.emptyMessage = 'Nothing here yet.',
    super.key,
  });

  final bool loading;
  final String? error;
  final bool isEmpty;
  final VoidCallback onRetry;
  final Widget child;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return FeatureCard(
        child: Column(
          children: [
            Icon(
              PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
              color: Theme.of(context).colorScheme.error,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (isEmpty) {
      return FeatureCard(
        child: Column(
          children: [
            const QuokkaBadge(size: 70, calm: true),
            const SizedBox(height: 10),
            Text(emptyMessage, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return child;
  }
}

class GuestGuard extends StatelessWidget {
  const GuestGuard({this.child, super.key});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return HappifyPage(
      title: 'Sign in required',
      children: [
        FeatureCard(
          child: Column(
            children: [
              const QuokkaBadge(size: 96, calm: true),
              const SizedBox(height: 14),
              Text(
                'This feature securely stores personal wellbeing data and is unavailable in guest mode.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (child != null) ...[const SizedBox(height: 12), child!],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign in to continue'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<String?> showTextPrompt(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  int maxLines = 1,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: maxLines,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String prettyEnum(Object? value) {
  final text = value?.toString() ?? '';
  if (text.isEmpty) return 'Not available';
  return text
      .toLowerCase()
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

String shortDate(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

const moodOptions = <(String, String, String)>[
  ('HAPPY', 'Happy', '😊'),
  ('CALM', 'Calm', '😌'),
  ('NEUTRAL', 'Neutral', '🙂'),
  ('ANXIOUS', 'Anxious', '😟'),
  ('SAD', 'Sad', '😢'),
  ('DISTRESSED', 'Distressed', '😣'),
];

Color moodColor(String mood) => switch (mood) {
  'HAPPY' => HappifyColors.gold,
  'CALM' => HappifyColors.green,
  'ANXIOUS' => HappifyColors.purple,
  'SAD' => HappifyColors.blue,
  'DISTRESSED' => HappifyColors.red,
  _ => const Color(0xFFCFCFCF),
};
