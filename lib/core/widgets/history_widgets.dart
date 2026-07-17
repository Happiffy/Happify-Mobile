import 'package:flutter/material.dart';

class LoadMoreSentinel extends StatefulWidget {
  const LoadMoreSentinel({
    required this.enabled,
    required this.onLoadMore,
    required this.child,
    this.loading = false,
    this.threshold = 200,
    super.key,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onLoadMore;
  final Widget child;
  final double threshold;

  @override
  State<LoadMoreSentinel> createState() => _LoadMoreSentinelState();
}

class _LoadMoreSentinelState extends State<LoadMoreSentinel> {
  var _requested = false;

  bool _onScroll(ScrollNotification notification) {
    if (!widget.enabled || widget.loading) {
      _requested = false;
      return false;
    }
    if (notification.metrics.extentAfter > widget.threshold) {
      _requested = false;
      return false;
    }
    if (!_requested) {
      _requested = true;
      widget.onLoadMore();
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant LoadMoreSentinel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loading && !widget.loading) _requested = false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    );
  }
}

class HistoryDateRangeFilter extends StatelessWidget {
  const HistoryDateRangeFilter({
    required this.startDate,
    required this.endDate,
    required this.onApply,
    super.key,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final Future<void> Function(DateTime? startDate, DateTime? endDate) onApply;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        side: const BorderSide(color: Color(0xFFE5E5E5), width: 2),
      ),
      onPressed: () async {
        final dates = await showHistoryDateRangePicker(
          context,
          startDate: startDate,
          endDate: endDate,
        );
        if (dates == null || !context.mounted) return;
        await onApply(dates.$1, dates.$2);
      },
      icon: const Icon(Icons.calendar_month_outlined),
      label: Text(_label(startDate, endDate)),
    );
  }

  static String _label(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) return 'Filter dates';
    return 'Dates: ${_formatDate(startDate)} – ${_formatDate(endDate)}';
  }
}

Future<(DateTime? startDate, DateTime? endDate)?> showHistoryDateRangePicker(
  BuildContext context, {
  DateTime? startDate,
  DateTime? endDate,
}) => showModalBottomSheet<_HistoryDateRange>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) =>
      _HistoryDateRangeSheet(startDate: startDate, endDate: endDate),
).then((dates) => dates == null ? null : (dates.startDate, dates.endDate));

class _HistoryDateRange {
  const _HistoryDateRange(this.startDate, this.endDate);

  final DateTime? startDate;
  final DateTime? endDate;
}

class _HistoryDateRangeSheet extends StatefulWidget {
  const _HistoryDateRangeSheet({
    required this.startDate,
    required this.endDate,
  });

  final DateTime? startDate;
  final DateTime? endDate;

  @override
  State<_HistoryDateRangeSheet> createState() => _HistoryDateRangeSheetState();
}

class _HistoryDateRangeSheetState extends State<_HistoryDateRangeSheet> {
  late DateTime? _startDate = _selectedDate(widget.startDate);
  late DateTime? _endDate = _selectedDate(widget.endDate);
  late DateTime _displayedMonth = _monthOf(
    _selectedDate(widget.startDate) ?? _selectedDate(widget.endDate) ?? _today,
  );
  String? _error;

  static DateTime get _today => _dateOnly(DateTime.now());
  DateTime get _firstDate => _today.subtract(const Duration(days: 89));
  DateTime get _lastMonth => _monthOf(_today);
  DateTime get _firstMonth => _monthOf(_firstDate);

  void _selectDate(DateTime value) {
    final date = _dateOnly(value);
    setState(() {
      _error = null;
      if (_startDate == null || _endDate != null) {
        _startDate = date;
        _endDate = null;
        return;
      }
      if (date.isBefore(_startDate!)) {
        _endDate = _startDate;
        _startDate = date;
        return;
      }
      if (date.difference(_startDate!).inDays > 89) {
        _error = 'Choose an end date within 90 days.';
        return;
      }
      _endDate = date;
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
    });
  }

  bool _isSameDate(DateTime? left, DateTime right) =>
      left != null &&
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  bool _isAvailable(DateTime date) =>
      !date.isBefore(_firstDate) && !date.isAfter(_today);

  @override
  Widget build(BuildContext context) {
    final canApply =
        (_startDate == null && _endDate == null) ||
        (_startDate != null && _endDate != null);
    final previousEnabled = _displayedMonth.isAfter(_firstMonth);
    final nextEnabled = _displayedMonth.isBefore(_lastMonth);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D0D0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Filter history',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select a start date, then an end date. Date ranges can be up to 90 days.',
                ),
                const SizedBox(height: 12),
                Text('Start: ${_formatDate(_startDate)}'),
                Text('End: ${_formatDate(_endDate)}'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: previousEnabled
                          ? () => _changeMonth(-1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous month',
                    ),
                    Expanded(
                      child: Text(
                        _monthLabel(_displayedMonth),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: nextEnabled ? () => _changeMonth(1) : null,
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next month',
                    ),
                  ],
                ),
                const _WeekdayLabels(),
                _MonthGrid(
                  month: _displayedMonth,
                  isAvailable: _isAvailable,
                  isSelected: (date) =>
                      _isSameDate(_startDate, date) ||
                      _isSameDate(_endDate, date),
                  onSelect: _selectDate,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (!canApply)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Choose an end date to apply this filter.'),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _startDate = null;
                        _endDate = null;
                        _error = null;
                      }),
                      child: const Text('Clear dates'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: canApply
                          ? () => Navigator.pop(
                              context,
                              _HistoryDateRange(_startDate, _endDate),
                            )
                          : null,
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _WeekdayLabel('Sun'),
        _WeekdayLabel('Mon'),
        _WeekdayLabel('Tue'),
        _WeekdayLabel('Wed'),
        _WeekdayLabel('Thu'),
        _WeekdayLabel('Fri'),
        _WeekdayLabel('Sat'),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.isAvailable,
    required this.isSelected,
    required this.onSelect,
  });

  final DateTime month;
  final bool Function(DateTime date) isAvailable;
  final bool Function(DateTime date) isSelected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final leadingDays = DateTime(month.year, month.month).weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = leadingDays + daysInMonth;
    final rows = (cells / 7).ceil();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.15,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        final day = index - leadingDays + 1;
        if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
        final date = DateTime(month.year, month.month, day);
        final available = isAvailable(date);
        final selected = isSelected(date);
        return Padding(
          padding: const EdgeInsets.all(2),
          child: Semantics(
            button: available,
            selected: selected,
            label: _formatDate(date),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: available ? () => onSelect(date) : null,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : available
                          ? null
                          : Theme.of(context).disabledColor,
                      fontWeight: selected ? FontWeight.w700 : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

DateTime? _selectedDate(DateTime? value) =>
    value == null ? null : _dateOnly(value);

DateTime _dateOnly(DateTime value) {
  final date = value.toLocal();
  return DateTime(date.year, date.month, date.day);
}

DateTime _monthOf(DateTime value) => DateTime(value.year, value.month);

String _formatDate(DateTime? date) {
  if (date == null) return 'Not selected';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _monthLabel(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
