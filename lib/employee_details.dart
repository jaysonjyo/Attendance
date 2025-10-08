import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeDetails extends StatefulWidget {
  final String employeeId;
  const EmployeeDetails({super.key, required this.employeeId});

  @override
  State<EmployeeDetails> createState() => _EmployeeDetailsState();
}

class _EmployeeDetailsState extends State<EmployeeDetails> {
  List<Map<String, dynamic>> _attendanceList = [];
  List<String> presentDates = [];
  List<String> absentDates = [];
  String employeeName = 'Loading...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      final response = await Supabase.instance.client
          .schema('hr')
          .from('attendance')
          .select('date_att, check_in, check_out, eml_id, eml(name)')
          .eq('eml_id', widget.employeeId)
          .gte('date_att', firstDay.toIso8601String())
          .lte('date_att', lastDay.toIso8601String());

      final data = List<Map<String, dynamic>>.from(response);

      final name = data.isNotEmpty ? data.first['eml']['name'] ?? 'N/A' : 'N/A';

      final presentSet = <String>{};
      for (var row in data) {
        final date = row['date_att']?.substring(0, 10);
        if (date != null) presentSet.add(date);
      }
      final allDatesThisMonth = List.generate(
        now.day, // only up to today
            (index) => DateTime(now.year, now.month, index + 1),
      );

      // final allDatesThisMonth = List.generate(
      //   lastDay.day,
      //       (index) => DateTime(now.year, now.month, index + 1),
      // );



      final List<String> _presentDates = [];
      final List<String> _absentDates = [];

      for (var date in allDatesThisMonth) {
        final dateStr = date.toIso8601String().substring(0, 10);
        if (presentSet.contains(dateStr)) {
          _presentDates.add(dateStr);
        } else {
          _absentDates.add(dateStr);
        }
      }

      setState(() {
        _attendanceList = data;
        employeeName = name;
        presentDates = _presentDates;
        absentDates = _absentDates;
      });
    } catch (e) {
      print("Error fetching data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int get presentCount => presentDates.length;
  int get leaveCount => absentDates.length;
  int get totalCount => presentCount + leaveCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Header icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 16),
                      Icon(Icons.filter_list),
                    ],
                  ),
                ],
              ),
            ),

            // Employee name
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                employeeName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            // Stat boxes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statBox('Present', presentCount, Colors.green),
                  _statBox('Leave', leaveCount, Colors.orange),
                  _statBox('Total', totalCount, Colors.blue),
                ],
              ),
            ),

            // Attendance list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  const SizedBox(height: 8),
                  const Text('✔ Present Days:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...presentDates.map((date) => _listCard(date, true)),
                  const SizedBox(height: 12),
                  const Text('❌ Absent Days:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...absentDates.map((date) => _listCard(date, false)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      width: 90,
      child: Column(
        children: [
          Text(
            '($count)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _listCard(String date, bool isPresent) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          isPresent ? Icons.check_circle : Icons.cancel,
          color: isPresent ? Colors.green : Colors.red,
        ),
        title: Text(date),
        subtitle: Text(isPresent ? 'Present' : 'Absent'),
      ),
    );
  }
}
