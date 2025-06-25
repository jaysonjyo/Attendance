
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum FilterType {
  singleDay,
  dateRange,
  thisWeek,
  thisMonth,
  previousWeek,
  previousMonth,
}

extension FilterLabel on FilterType {
  String get label {
    switch (this) {
      case FilterType.singleDay:
        return 'Single Day';
      case FilterType.dateRange:
        return 'Date Range';
      case FilterType.thisWeek:
        return 'This Week';
      case FilterType.thisMonth:
        return 'This Month';
      case FilterType.previousWeek:
        return 'Previous Week';
      case FilterType.previousMonth:
        return 'Previous Month';
    }
  }
}

class DateCustomize extends StatefulWidget {
  const DateCustomize({super.key});

  @override
  State<DateCustomize> createState() => _DateCustomizeState();
}

class _DateCustomizeState extends State<DateCustomize> {
  final Set<FilterType> _selectedFilters = {};
  DateTime? selectedDate;
  DateTimeRange? selectedRange;
  List<Map<String, dynamic>> _employeeListAtt = [];
  bool _isLoading = false;
  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
  }

  Future<void> _applyFilters() async {
    setState(() => _isLoading = true);
    _employeeListAtt.clear();

    try {
      final List<DateTimeRange> ranges = [];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
//
      for (final filter in _selectedFilters) {
        switch (filter) {
          case FilterType.singleDay:
            if (selectedDate == null) {
              selectedDate = await showDatePicker(
                context: context,
                initialDate: today,
                firstDate: DateTime(today.year - 1),
                lastDate: DateTime(today.year + 1),
              );
            }
            if (selectedDate != null) {
              ranges.add(DateTimeRange(start: selectedDate!, end: selectedDate!));
            }
            break;
          case FilterType.dateRange:
            if (selectedRange == null) {
              selectedRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(today.year - 1),
                lastDate: DateTime(today.year + 1),
              );
            }
            if (selectedRange != null) {
              ranges.add(selectedRange!);
            }
            break;

          case FilterType.thisWeek:
            final start = today.subtract(Duration(days: today.weekday - 1));
            final end = start.add(const Duration(days: 6));
            ranges.add(DateTimeRange(start: start, end: end));
            break;
          case FilterType.previousWeek:
            final end = today.subtract(Duration(days: today.weekday));
            final start = end.subtract(const Duration(days: 6));
            ranges.add(DateTimeRange(start: start, end: end));
            break;
          case FilterType.thisMonth:
            final start = DateTime(today.year, today.month, 1);
            final end = DateTime(today.year, today.month + 1, 0);
            ranges.add(DateTimeRange(start: start, end: end));
            break;
          case FilterType.previousMonth:
            final start = DateTime(today.year, today.month - 1, 1);
            final end = DateTime(today.year, today.month, 0);
            ranges.add(DateTimeRange(start: start, end: end));
            break;
        }
      }

      if (ranges.isEmpty) return;

      final Set<String> seenIds = {};
      for (final range in ranges) {
        final response = await Supabase.instance.client
            .schema('hr')
            .from('attendance')
            .select('id, date_att, eml_id, check_in, check_out, dt, ot')
            .gte('date_att', DateFormat('yyyy-MM-dd').format(range.start))
            .lte('date_att', DateFormat('yyyy-MM-dd').format(range.end))
            .order('date_att', ascending: true);

        for (final item in response) {
          final key = "${item['id']}_${item['date_att']}";
          if (!seenIds.contains(key)) {
            seenIds.add(key);
            _employeeListAtt.add(Map<String, dynamic>.from(item));
          }
        }
      }

      setState(() => _employeeListAtt);
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd MMM yyyy - hh:mm a').format(dt);
    } catch (_) {
      return 'Invalid';
    }
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: FilterType.values.map((filter) {
        final selected = _selectedFilters.contains(filter);
        return FilterChip(
          label: Text(filter.label),
          selected: selected,
          onSelected: (bool value) async {
            setState(() {
              if (value) {
                _selectedFilters.add(filter);
              } else {
                _selectedFilters.remove(filter);
                if (filter == FilterType.singleDay) selectedDate = null;
                if (filter == FilterType.dateRange) selectedRange = null;
              }
            });
            await _applyFilters();
          },

          // onSelected: (bool value) async {
          //   setState(() {
          //     if (value) {
          //       _selectedFilters.add(filter);
          //     } else {
          //       _selectedFilters.remove(filter);
          //     }
          //   });
          //   await _applyFilters();
          // },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Attendance'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filters:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFilterChips(),
              ],
            ),
          ),
          Expanded(
            child: _employeeListAtt.isEmpty
                ? const Center(child: Text('No records found.'))
                : ListView.builder(
              itemCount: _employeeListAtt.length,
              itemBuilder: (context, index) {
                final item = _employeeListAtt[index];
                final isExpanded = _expandedIndices.contains(index);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded ? _expandedIndices.remove(index) : _expandedIndices.add(index);
                    });
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: isExpanded ? 6 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                child: Text(item['eml_id']?.toString().substring(0, 1) ?? '?'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Employee ID: ${item['eml_id'] ?? 'N/A'}',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Check-in: ${_formatTime(item['check_in'])}'),
                                    Text('Check-out: ${_formatTime(item['check_out'])}'),
                                  ],
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 12),
                            Divider(color: Colors.grey.shade300),
                            Text('DT: ${item['dt'] ?? 'N/A'}'),
                            Text('OT: ${item['ot'] ?? 'N/A'}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


