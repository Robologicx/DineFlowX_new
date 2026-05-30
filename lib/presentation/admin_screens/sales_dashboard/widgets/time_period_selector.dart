import 'package:flutter/material.dart';
import 'package:hotel_management_system/data/models/sales_model_and_management.dart';

typedef PeriodSelected = void Function(ReportPeriod period);
typedef CustomRangeSelected =
    Future<void> Function(DateTime start, DateTime end);

class TimePeriodSelector extends StatefulWidget {
  final PeriodSelected onPeriodSelected;
  final CustomRangeSelected? onCustomRangeSelected;

  const TimePeriodSelector({
    super.key,
    required this.onPeriodSelected,
    this.onCustomRangeSelected,
  });

  @override
  State<TimePeriodSelector> createState() => _TimePeriodSelectorState();
}

class _TimePeriodSelectorState extends State<TimePeriodSelector> {
  ReportPeriod _selectedPeriod = ReportPeriod.today;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _isLoading = false;

  String _format(DateTime? d) {
    if (d == null) return 'Not set';
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _selectPreset(ReportPeriod p) async {
    setState(() {
      _selectedPeriod = p;
      _isLoading = true;
      if (p != ReportPeriod.custom) {
        _customStart = null;
        _customEnd = null;
      }
    });
    widget.onPeriodSelected(p);

    // Simulate report generation delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Report generating for ${p.toString().split('.').last}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customStart ?? now,
      firstDate: DateTime(2000),
      lastDate: _customEnd ?? now,
    );
    if (picked != null) {
      setState(() {
        _customStart = picked;
        if (_customEnd != null && _customEnd!.isBefore(_customStart!)) {
          _customEnd = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customEnd ?? _customStart ?? now,
      firstDate: _customStart ?? DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _customEnd = picked;
        if (_customStart != null && _customStart!.isAfter(_customEnd!)) {
          final tmp = _customStart!;
          _customStart = _customEnd;
          _customEnd = tmp;
        }
      });
    }
  }

  bool get _customValid {
    return _customStart != null &&
        _customEnd != null &&
        !_customStart!.isAfter(_customEnd!);
  }

  Future<void> _applyCustom() async {
    if (!_customValid) return;

    setState(() {
      _selectedPeriod = ReportPeriod.custom;
      _isLoading = true;
    });

    try {
      if (widget.onCustomRangeSelected != null) {
        await widget.onCustomRangeSelected!(_customStart!, _customEnd!);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Report generating for : ${_format(_customStart)} to ${_format(_customEnd)}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _clearCustom() {
    setState(() {
      _customStart = null;
      _customEnd = null;
    });
  }

  Widget _periodChip(ReportPeriod period, String label, IconData icon) {
    final selected = _selectedPeriod == period;
    return FilterChip(
      selected: selected,
      onSelected: (s) => s ? _selectPreset(period) : null,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Time Period',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _periodChip(ReportPeriod.today, 'Today', Icons.today),
                _periodChip(ReportPeriod.week, 'This Week', Icons.date_range),
                _periodChip(
                  ReportPeriod.month,
                  'This Month',
                  Icons.calendar_month,
                ),
                _periodChip(
                  ReportPeriod.sixMonths,
                  '6 Months',
                  Icons.calendar_view_month,
                ),
                _periodChip(
                  ReportPeriod.year,
                  'This Year',
                  Icons.calendar_view_week,
                ),
                _periodChip(
                  ReportPeriod.allTime,
                  'All Time',
                  Icons.all_inclusive,
                ),
                FilterChip(
                  selected: _selectedPeriod == ReportPeriod.custom,
                  onSelected: (s) {
                    if (s) {
                      setState(() => _selectedPeriod = ReportPeriod.custom);
                    } else {
                      _selectPreset(ReportPeriod.today);
                    }
                  },
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_calendar, size: 16),
                      SizedBox(width: 6),
                      Text('Custom'),
                    ],
                  ),
                ),
              ],
            ),
            if (_selectedPeriod == ReportPeriod.custom) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Date Range',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _pickStartDate,
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text('Start: ${_format(_customStart)}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _pickEndDate,
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text('End: ${_format(_customEnd)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: (_customValid && !_isLoading)
                              ? _applyCustom
                              : null,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Apply'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _isLoading ? null : _clearCustom,
                          child: const Text('Clear'),
                        ),
                        const Spacer(),
                        if (!_customValid &&
                            (_customStart != null || _customEnd != null))
                          const Text(
                            'Select valid start & end dates',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
