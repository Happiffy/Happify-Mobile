import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/happify_colors.dart';
import '../theme/happify_theme.dart';
import 'happify_emoji.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class _ToastData {
  const _ToastData({
    required this.title,
    required this.message,
    required this.type,
  });

  final String title;
  final String? message;
  final HappifyToastType type;
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.data, required this.onDismiss});

  final _ToastData data;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isError = data.type == HappifyToastType.error;
    final color = isError ? HappifyColors.red : HappifyColors.green;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(HappifyRadii.field),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HappifyRadii.field),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(HappifyRadii.field),
            boxShadow: HappifyShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 11, 6, 10),
                child: Row(
                  children: [
                    isError
                        ? HappifyEmoji.warning(size: 26)
                        : HappifyEmoji.check(size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (data.message case final message?
                              when message.trim().isNotEmpty)
                            Text(
                              message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Dismiss notification',
                      child: SizedBox.square(
                        dimension: 48,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: onDismiss,
                            child: Center(child: HappifyEmoji.close(size: 18)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ColoredBox(
                color: color,
                child: const SizedBox(width: double.infinity, height: 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HappifyPage extends StatelessWidget {
  const HappifyPage({
    required this.children,
    this.title,
    this.actions,
    this.refresh,
    this.bottomPadding = 32,
    super.key,
  });

  final String? title;
  final List<Widget> children;
  final List<Widget>? actions;
  final Future<void> Function()? refresh;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 22, 20, bottomPadding),
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
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: refresh == null
                ? content
                : RefreshIndicator(onRefresh: refresh!, child: content),
          ),
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
    final radius = BorderRadius.circular(HappifyRadii.card);
    final body = Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.surface,
          borderRadius: radius,
          boxShadow: HappifyShadows.soft,
        ),
        child: child,
      ),
    );
    if (onTap == null) return body;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(borderRadius: radius, onTap: onTap, child: body),
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
    this.emptyVisual,
    super.key,
  });

  final bool loading;
  final String? error;
  final bool isEmpty;
  final VoidCallback onRetry;
  final Widget child;
  final String emptyMessage;
  final Widget? emptyVisual;

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
            HappifyEmoji.warning(size: 34),
            const SizedBox(height: 10),
            const Text(
              'We could not load this yet. Please try again.',
              textAlign: TextAlign.center,
            ),
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
            emptyVisual ?? HappifyEmoji.records(size: 56),
            const SizedBox(height: 12),
            Text(emptyMessage, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return child;
  }
}

class SignInGuard extends StatelessWidget {
  const SignInGuard({this.child, super.key});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return HappifyPage(
      title: 'Sign in required',
      children: [
        FeatureCard(
          child: Column(
            children: [
              HappifyEmoji.profile(size: 70),
              const SizedBox(height: 14),
              Text(
                'Sign in to securely save and access your personal wellbeing data.',
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

enum HappifyToastType { success, error }

void showToast(
  BuildContext context, {
  required String title,
  String? message,
  HappifyToastType type = HappifyToastType.success,
}) {
  final messenger = scaffoldMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 4),
        content: _ToastCard(
          data: _ToastData(title: title, message: message, type: type),
          onDismiss: messenger.hideCurrentSnackBar,
        ),
      ),
    );
}

void showMessage(BuildContext context, String message) {
  final normalized = message.toLowerCase();
  final isError =
      normalized.contains('could not') ||
      normalized.contains('failed') ||
      normalized.contains('error') ||
      normalized.contains('unable') ||
      normalized.contains('cannot') ||
      normalized.contains('retry') ||
      normalized.contains('expired') ||
      normalized.contains('required') ||
      normalized.contains('invalid') ||
      normalized.contains('not available');
  showToast(
    context,
    title: isError ? 'Something went wrong' : message,
    message: isError ? message : null,
    type: isError ? HappifyToastType.error : HappifyToastType.success,
  );
}

void showSuccessToast(BuildContext context, String title, {String? message}) {
  showToast(
    context,
    title: title,
    message: message,
    type: HappifyToastType.success,
  );
}

void showErrorToast(BuildContext context, String title, {String? message}) {
  showToast(
    context,
    title: title,
    message: message,
    type: HappifyToastType.error,
  );
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
