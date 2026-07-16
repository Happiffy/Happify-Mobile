import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_services.dart';
import '../../core/theme/happify_colors.dart';
import '../../core/theme/happify_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_button.dart';
import '../../core/widgets/happify_emoji.dart';
import '../../core/widgets/quokka_badge.dart';

class AccountOnboardingPage extends StatefulWidget {
  const AccountOnboardingPage({super.key});

  @override
  State<AccountOnboardingPage> createState() => _AccountOnboardingPageState();
}

class _AccountOnboardingPageState extends State<AccountOnboardingPage> {
  static const steps =
      <_PreferenceStep>[
        _PreferenceStep(
          'What brings you here?',
          'Pick what you want Happify to help with first.',
          <String>[
            'Feel calmer day to day',
            'Understand my mood patterns',
            'Build a journaling habit',
            'Find someone safe to talk to',
          ],
        ),
        _PreferenceStep(
          'What usually affects your mood?',
          'Choose anything that feels familiar.',
          <String>[
            'School pressure',
            'Family situation',
            'Social media',
            'Sleep problems',
            'Feeling lonely',
            'Friendship or relationship issues',
          ],
        ),
        _PreferenceStep(
          'How should Happify talk to you?',
          'This shapes the companion tone.',
          <String>[
            'Soft and gentle',
            'Clear and practical',
            'Encouraging',
            'Short and direct',
          ],
        ),
        _PreferenceStep(
          'When things feel heavy, what helps?',
          'We use this for safer support suggestions.',
          <String>[
            'Breathing or grounding',
            'Contact someone I trust',
            'Talk to a professional',
            'Show urgent help options',
          ],
        ),
      ];

  final _selected = List<Set<String>>.generate(steps.length, (_) => <String>{});
  int _step = 0;
  bool _saving = false;

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final services = AppServices.of(context);
      String? answer(int index) => _selected[index].firstOrNull;
      await services.settings.sync(services.auth.api, {
        'primaryGoal': answer(0) ?? 'Understand my mood patterns',
        'triggers': _selected[1].toList(),
        'supportTone': answer(2) ?? 'Soft and gentle',
        'highRiskAction': answer(3) ?? 'Talk to a professional',
        'consentToAi': true,
      });
      if (!mounted) return;
      context.go('/app');
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = steps[_step];
    final selected = _selected[_step];
    return Scaffold(
      backgroundColor: HappifyColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: _step == 0 ? null : () => setState(() => _step--),
                  icon: HappifyEmoji.back(size: 28),
                ),
                const Spacer(),
                Text(
                  '${_step + 1} of ${steps.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: HappifyColors.inkSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(HappifyRadii.pill),
              child: LinearProgressIndicator(
                value: (_step + 1) / steps.length,
                minHeight: 8,
                backgroundColor: HappifyColors.surfaceMuted,
                color: HappifyColors.green,
              ),
            ),
            const SizedBox(height: 28),
            const Center(child: QuokkaBadge(size: 112, calm: true)),
            const SizedBox(height: 24),
            Text(step.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(step.hint, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 22),
            ...step.options.map((option) {
              final isSelected = selected.contains(option);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  selected: isSelected,
                  button: true,
                  label: option,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(HappifyRadii.card),
                    onTap: () => setState(() {
                      if (isSelected) {
                        selected.remove(option);
                      } else {
                        if (_step == 0 || _step == 2 || _step == 3) {
                          selected.clear();
                        }
                        selected.add(option);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? HappifyColors.greenSurface
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(HappifyRadii.card),
                        border: Border.all(
                          color: isSelected
                              ? HappifyColors.green
                              : HappifyColors.line,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: Color(0xFFB7ECA2),
                                  offset: Offset(0, 4),
                                  blurRadius: 0,
                                ),
                              ]
                            : const [],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          isSelected
                              ? HappifyEmoji.check(size: 26)
                              : HappifyEmoji.whiteHeart(size: 26),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            HappifyButton(
              label: _saving
                  ? 'Saving...'
                  : _step == steps.length - 1
                  ? 'Finish setup'
                  : 'Continue',
              leading: _step == steps.length - 1
                  ? HappifyEmoji.check(size: 22)
                  : HappifyEmoji.next(size: 22),
              onPressed: _saving
                  ? null
                  : () {
                      if (_step == steps.length - 1) {
                        _finish();
                      } else {
                        setState(() => _step++);
                      }
                    },
            ),
            TextButton(
              onPressed: _saving ? null : () => context.go('/app'),
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceStep {
  const _PreferenceStep(this.title, this.hint, this.options);

  final String title;
  final String hint;
  final List<String> options;
}
