import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Date_Customize extends StatefulWidget {
  const Date_Customize({super.key});

  @override
  State<Date_Customize> createState() => _Date_CustomizeState();
}

class _Date_CustomizeState extends State<Date_Customize> {
  DateTime? selectedDate;
  List<Map<String, dynamic>> _employeeList_att = [];
  bool _isLoading = false;
  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickDate();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });

      await _fetchAttendanceByDate(); // ⬅️ Fetch after picking date
    }
  }

  Future<void> _fetchAttendanceByDate() async {
    if (selectedDate == null) return;

    setState(() => _isLoading = true);
    try {
      final formattedDate = "${selectedDate!.year.toString().padLeft(4, '0')}-"
          "${selectedDate!.month.toString().padLeft(2, '0')}-"
          "${selectedDate!.day.toString().padLeft(2, '0')}";

      final response = await Supabase.instance.client
          .schema('hr')
          .from('attendance')
          .select('id, date_att, eml_id, check_in, check_out, dt, ot')
          .eq('date_att', formattedDate)
          .order('id', ascending: true);

      setState(() {
        _employeeList_att = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        print("Error fetching employees: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching attendance: $e')),
        );
      }
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
      return 'Invalid time';
    }
  }
  @override
  Widget build(BuildContext context) {
    final dateText = selectedDate != null
        ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
        : 'No date selected';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Attendance'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(' $dateText', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('Change Date'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _employeeList_att.isEmpty
                ? const Center(child: Text('No attendance records found.'))
                : ListView.builder(
              itemCount: _employeeList_att.length,
              itemBuilder: (context, index) {
                final item = _employeeList_att[index];
                final isExpanded = _expandedIndices.contains(index);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedIndices.remove(index);
                      } else {
                        _expandedIndices.add(index);
                      }
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
