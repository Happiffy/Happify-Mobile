import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_happify/core/theme/happify_theme.dart';
import 'package:mobile_happify/core/widgets/common_widgets.dart';
import 'package:mobile_happify/core/widgets/happify_button.dart';

void main() {
  testWidgets('icon action does not require an overlay', (tester) async {
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: HappifyIconButton(
            label: 'Dismiss notification',
            icon: Icons.close,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Dismiss notification'), findsOneWidget);
  });

  testWidgets('toast uses the root messenger without tooltip errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: buildHappifyTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showSuccessToast(context, 'Saved'),
              child: const Text('Show toast'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show toast'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('quiet feature cards do not add an elevated shadow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHappifyTheme(),
        home: const Scaffold(body: FeatureCard(child: Text('Content'))),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.boxShadow, isNull);
    expect(decoration.border, isA<Border>());
  });

  testWidgets('long tactile button reflows at two times text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildHappifyTheme(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: HappifyButton(
                label: 'Continue with a very long accessible action label',
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Continue with a very long accessible action label'),
      findsOneWidget,
    );
  });
}
