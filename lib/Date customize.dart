
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

// Full Flutter implementation of rule-based filter UI similar to the reference image
//
// import 'package:flutter/material.dart';
//
// enum FilterJoinType { and, or }
//
// class FilterRule {
//   String field;
//   String operator;
//   String value;
//
//   FilterRule({required this.field, required this.operator, required this.value});
// }
//
// class FilterGroup {
//   FilterJoinType joinType;
//   List<dynamic> conditions; // can contain FilterRule or FilterGroup
//
//   FilterGroup({required this.joinType, this.conditions = const []});
// }
//
//
//
// class RuleBasedFilterPage extends StatefulWidget {
//   const RuleBasedFilterPage({super.key});
//
//   @override
//   State<RuleBasedFilterPage> createState() => _RuleBasedFilterPageState();
// }
//
// class _RuleBasedFilterPageState extends State<RuleBasedFilterPage> {
//   FilterGroup rootGroup = FilterGroup(joinType: FilterJoinType.and, conditions: []);
//
//   void _addRule(FilterGroup group) {
//     setState(() => group.conditions.add(FilterRule(field: 'Field', operator: 'Equals', value: '')));
//   }
//
//   void _addGroup(FilterGroup group) {
//     setState(() => group.conditions.add(FilterGroup(joinType: FilterJoinType.and, conditions: [])));
//   }
//
//   void _removeCondition(FilterGroup group, dynamic condition) {
//     setState(() => group.conditions.remove(condition));
//   }
//
//   String _buildLogic(FilterGroup group) {
//     List<String> parts = [];
//     for (var condition in group.conditions) {
//       if (condition is FilterRule) {
//         parts.add("${condition.field} ${condition.operator} '${condition.value}'");
//       } else if (condition is FilterGroup) {
//         parts.add("(${_buildLogic(condition)})");
//       }
//     }
//     return parts.join(group.joinType == FilterJoinType.and ? ' AND ' : ' OR ');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Rule-based Filter UI")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 child: FilterGroupWidget(
//                   group: rootGroup,
//                   onChanged: () => setState(() {}),
//                   onAddRule: _addRule,
//                   onAddGroup: _addGroup,
//                   onRemove: _removeCondition,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () {
//                 final logic = _buildLogic(rootGroup);
//                 showDialog(
//                   context: context,
//                   builder: (_) => AlertDialog(
//                     title: const Text("Generated Filter Logic"),
//                     content: Text(logic),
//                     actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
//                   ),
//                 );
//               },
//               child: const Text("Preview Logic"),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class FilterGroupWidget extends StatelessWidget {
//   final FilterGroup group;
//   final VoidCallback onChanged;
//   final Function(FilterGroup) onAddRule;
//   final Function(FilterGroup) onAddGroup;
//   final Function(FilterGroup, dynamic) onRemove;
//
//   const FilterGroupWidget({
//     super.key,
//     required this.group,
//     required this.onChanged,
//     required this.onAddRule,
//     required this.onAddGroup,
//     required this.onRemove,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: Colors.grey[100],
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 DropdownButton<FilterJoinType>(
//                   value: group.joinType,
//                   onChanged: (val) {
//                     if (val != null) {
//                       group.joinType = val;
//                       onChanged();
//                     }
//                   },
//                   items: FilterJoinType.values.map((e) {
//                     return DropdownMenuItem(
//                       value: e,
//                       child: Text(e == FilterJoinType.and ? 'AND' : 'OR'),
//                     );
//                   }).toList(),
//                 ),
//                 const Spacer(),
//                 IconButton(
//                   onPressed: () => onAddRule(group),
//                   icon: const Icon(Icons.add_circle_outline),
//                   tooltip: 'Add Rule',
//                 ),
//                 IconButton(
//                   onPressed: () => onAddGroup(group),
//                   icon: const Icon(Icons.add_box_outlined),
//                   tooltip: 'Add Group',
//                 ),
//               ],
//             ),
//             ...group.conditions.map((cond) {
//               if (cond is FilterRule) {
//                 return FilterRuleWidget(
//                   rule: cond,
//                   onChanged: onChanged,
//                   onRemove: () => onRemove(group, cond),
//                 );
//               } else if (cond is FilterGroup) {
//                 return FilterGroupWidget(
//                   group: cond,
//                   onChanged: onChanged,
//                   onAddRule: onAddRule,
//                   onAddGroup: onAddGroup,
//                   onRemove: onRemove,
//                 );
//               } else {
//                 return const SizedBox.shrink();
//               }
//             })
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class FilterRuleWidget extends StatelessWidget {
//   final FilterRule rule;
//   final VoidCallback onChanged;
//   final VoidCallback onRemove;
//
//   const FilterRuleWidget({
//     super.key,
//     required this.rule,
//     required this.onChanged,
//     required this.onRemove,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         children: [
//           DropdownButton<String>(
//             value: rule.field,
//             onChanged: (val) {
//               if (val != null) {
//                 rule.field = val;
//                 onChanged();
//               }
//             },
//             items: ['Field', 'Expected amount', 'Fiscal year', 'Last modified date']
//                 .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                 .toList(),
//           ),
//           const SizedBox(width: 8),
//           DropdownButton<String>(
//             value: rule.operator,
//             onChanged: (val) {
//               if (val != null) {
//                 rule.operator = val;
//                 onChanged();
//               }
//             },
//             items: ['Equals', 'Is equal to', 'Is bigger than', 'Does not equal']
//                 .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                 .toList(),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: TextFormField(
//               initialValue: rule.value,
//               decoration: const InputDecoration(hintText: 'Value'),
//               onChanged: (val) {
//                 rule.value = val;
//                 onChanged();
//               },
//             ),
//           ),
//           IconButton(
//             onPressed: onRemove,
//             icon: const Icon(Icons.delete, color: Colors.red),
//           )
//         ],
//       ),
//     );
//   }
// }
//


