
import 'package:flutter/material.dart';
import 'package:hr_at/Date%20customize.dart';
import 'package:hr_at/today.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://thftmoghwfgztcdmbrho.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoZnRtb2dod2ZnenRjZG1icmhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM3NjAxOTksImV4cCI6MjA1OTMzNjE5OX0.rKy8P6BoyADmMVp9MrR1EzFJNvnoIoGwvKYU2Leyn-M',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AttendanceScreen(),
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _employeeList = [];
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .schema('hr')
          .from('eml')
          .select('id, name, department')
          .order('id', ascending: true);

      setState(() {
        _employeeList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        print("Error fetching employees:$e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching employees: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkInput(String value) async {
    if (value.length != 4) return;

    setState(() => _isLoading = true);
    _controller.clear();

    try {
      final employee = _employeeList.firstWhere(
            (emp) => emp['id'].toString() == value,
        orElse: () => {},
      );

      if (employee.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee ID not found')),
          );
        }
        return;
      }

      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];

      final records = await Supabase.instance.client
          .schema('hr')
          .from('attendance')
          .select()
          .eq('eml_id', employee['id'])
          .filter('check_out', 'is', null)
          .order('check_in', ascending: false)
          .limit(1);

      if (records.isEmpty) {
        // ✅ First time check-in
        await _createCheckIn(employee, now, today);
        if (mounted) _showSnackBar('✅ First check-in for ${employee['name']}');
      } else {
        final latest = records.first;
        final checkIn = DateTime.parse(latest['check_in']);
        final diffInDays = now.difference(checkIn).inDays;
        final diffInMinutes = now.difference(checkIn).inMinutes;

        if (diffInDays > 2) {
          // ⚠️ Record older than 2 days - force new check-in
          await _createCheckIn(employee, now, today);
          if (mounted) _showSnackBar('✅ New check-in for ${employee['name']} (previous record expired)');
        } else {
          // Handle normal check-out
          if (diffInMinutes < 2) {
            if (mounted) _showSnackBar('⏳ Please wait ${2 - diffInMinutes} more minute(s) to check out');
          } else {
            await _performCheckOut(latest['id'], now);
            if (mounted) _showSnackBar('✅ Check-out recorded for ${employee['name']}');
          }
        }
      }

      await _fetchEmployees();
    } catch (e) {
      if (mounted) _showSnackBar('❌ Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// Helper functions
  Future<void> _createCheckIn(Map<String, dynamic> employee, DateTime now, String today) async {
    await Supabase.instance.client
        .schema('hr')
        .from('attendance')
        .insert({
      'date_att': today,
      'eml_id': employee['id'],
      'check_in': now.toIso8601String(),
    });
  }

  Future<void> _performCheckOut(int recordId, DateTime now) async {
    await Supabase.instance.client
        .schema('hr')
        .from('attendance')
        .update({'check_out': now.toIso8601String()})
        .eq('id', recordId);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Future<void> _checkInput(String value) async {
  //   if (value.length != 4) return;
  //
  //   setState(() => _isLoading = true);
  //   _controller.clear();
  //
  //   try {
  //     final employee = _employeeList.firstWhere(
  //           (emp) => emp['id'].toString() == value,
  //       orElse: () => {},
  //     );
  //
  //     if (employee.isEmpty) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Employee ID not found')),
  //         );
  //       }
  //       return;
  //     }
  //
  //     final now = DateTime.now();
  //     final today = now.toIso8601String().split('T')[0];
  //
  //     final records = await Supabase.instance.client
  //         .schema('hr')
  //         .from('attendance')
  //         .select()
  //         .eq('eml_id', employee['id'])
  //         .filter('check_out', 'is', null)
  //         .order('check_in', ascending: false)
  //         .limit(1);
  //
  //
  //     if (records.isEmpty) {
  //       // ✅ First time check-in
  //       await Supabase.instance.client
  //           .schema('hr')
  //           .from('attendance')
  //           .insert({
  //         'date_att': today,
  //         'eml_id': employee['id'],
  //         'check_in': now.toIso8601String(),
  //       });
  //
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('✅ First check-in for ${employee['name']}')),
  //         );
  //       }
  //     } else {
  //       final latest = records.first;
  //       final checkIn = DateTime.parse(latest['check_in']);
  //       final checkOut = latest['check_out'];
  //
  //       final diffInDays = now.difference(checkIn).inDays;
  //       final diffInMinutes = now.difference(checkIn).inMinutes;
  //
  //       if (checkOut == null) {
  //         // 👇 Checkout conditions
  //         if (diffInDays <= 2) {
  //           if (diffInMinutes < 2) {
  //             // ❌ Too early to check out
  //             if (mounted) {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(content: Text('⏳ Please wait at least 2 minutes before checking out')),
  //               );
  //             }
  //             return;
  //           } else {
  //             // ✅ Valid check-out
  //             await Supabase.instance.client
  //                 .schema('hr')
  //                 .from('attendance')
  //                 .update({'check_out': now.toIso8601String()})
  //                 .eq('id', latest['id']);
  //
  //             if (mounted) {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(content: Text('✅ Check-out recorded for ${employee['name']}')),
  //               );
  //             }
  //           }
  //         } else {
  //           // ❌ Too late to check-out (more than 2 days)
  //           if (mounted) {
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               const SnackBar(content: Text('⚠️ Last check-in is older than 2 days. No valid checkout.')),
  //             );
  //           }
  //         }
  //       } else {
  //         // ✅ Already checked out — allow new check-in
  //         await Supabase.instance.client
  //             .schema('hr')
  //             .from('attendance')
  //             .insert({
  //           'date_att': today,
  //           'eml_id': employee['id'],
  //           'check_in': now.toIso8601String(),
  //         });
  //
  //         if (mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text('✅ New check-in for ${employee['name']}')),
  //           );
  //         }
  //       }
  //     }
  //
  //     await _fetchEmployees();
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('❌ Error: $e')),
  //       );
  //     }
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }



  @override


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [PopupMenuButton<String>(
          icon: const Icon(Icons.calendar_month),
          onSelected: (String value) {
            if (value == 'today') {
Navigator.of(context).push(MaterialPageRoute(builder: (_)=>Today()));
            } else if (value == 'custom') {
              Navigator.of(context).push(MaterialPageRoute(builder: (_)=>Date_Customize()));
              // Navigator.pushNamed(context, '/custom');
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'today',
              child: ListTile(
                leading: Icon(Icons.today),
                title: Text("Today's Attendance"),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'custom',
              child: ListTile(
                leading: Icon(Icons.date_range),
                title: Text('Custom Attendance'),
              ),
            ),
          ],
        ),],
        title: const Text('Employee Attendance'),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Employee ID',
                border: OutlineInputBorder(),
                hintText: '4-digit code',
              ),
              onChanged: _checkInput,
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            const Text('Employee List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: _employeeList.isEmpty
                  ? const Center(child: Text('No employees found'))
                  : ListView.builder(
                itemCount: _employeeList.length,
                itemBuilder: (context, index) {
                  final employee = _employeeList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(employee['name'] ?? 'Unknown'),
                      subtitle: Text('ID: ${employee['id']} - ${employee['department'] ?? 'No department'}'),
                      leading: CircleAvatar(
                        child: Text(employee['id'].toString()),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}