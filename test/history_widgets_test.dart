import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_happify/core/widgets/history_widgets.dart';

void main() {
  testWidgets('date filters apply only after confirmation', (tester) async {
    DateTime? appliedStart = DateTime(2026, 7, 1);
    DateTime? appliedEnd = DateTime(2026, 7, 7);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryDateRangeFilter(
            startDate: appliedStart,
            endDate: appliedEnd,
            onApply: (startDate, endDate) async {
              appliedStart = startDate;
              appliedEnd = endDate;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dates: 2026-07-01 – 2026-07-07'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Clear dates'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Clear dates'));
    await tester.pump();

    expect(appliedStart, DateTime(2026, 7, 1));
    expect(appliedEnd, DateTime(2026, 7, 7));

    await tester.scrollUntilVisible(
      find.text('Apply'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(appliedStart, isNull);
    expect(appliedEnd, isNull);
  });

  testWidgets('load more sentinel invokes callback near the list bottom', (
    tester,
  ) async {
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoadMoreSentinel(
            enabled: true,
            onLoadMore: () => calls++,
            child: ListView(children: const [SizedBox(height: 1200)]),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pump();

    expect(calls, 1);
  });
}
