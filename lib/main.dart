// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// void main()  async {
//   await Supabase.initialize(
//       url: 'https://thftmoghwfgztcdmbrho.supabase.co',
//       anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoZnRtb2dod2ZnenRjZG1icmhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM3NjAxOTksImV4cCI6MjA1OTMzNjE5OX0.rKy8P6BoyADmMVp9MrR1EzFJNvnoIoGwvKYU2Leyn-M');
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: Field(),
//     );
//   }
// }
//
// // class Field extends StatefulWidget {
// //   const Field({super.key});
// //
// //   @override
// //   State<Field> createState() => _FieldState();
// // }
// //
// // class _FieldState extends State<Field> {
// //   final TextEditingController _controller = TextEditingController();
// //
// //   void _checkInput(String value) async {
// //     if (value.length == 4) {
// //       try {
// //         final response = await Supabase.instance.client
// //             .from('attendance') // ✅ Use table name only
// //             .insert({'eml_id': int.parse(value)}) // ✅ Convert to int
// //             .select();
// //
// //         _controller.clear();
// //         print("response$response");
// //
// //         if (context.mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(content: Text('Inserted successfully')),
// //           );
// //         }
// //       } catch (e) {
// //         print("response$e");
// //         if (context.mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(content: Text('Error: $e')),
// //           );
// //         }
// //       }
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Center(
// //         child: Padding(
// //           padding: const EdgeInsets.all(16.0),
// //           child: TextField(
// //             controller: _controller,
// //             maxLength: 4,
// //             keyboardType: TextInputType.number,
// //             decoration: InputDecoration(
// //               labelText: 'Enter 4-digit code',
// //               border: OutlineInputBorder(),
// //             ),
// //             onChanged: _checkInput,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// class Field extends StatefulWidget {
//   const Field({super.key});
//
//   @override
//   State<Field> createState() => _FieldState();
// }
//
// class _FieldState extends State<Field> {
//   final TextEditingController _controller = TextEditingController();
//   List<dynamic> _messageList = [];
//
//   // Function to insert 4-digit code
//   _checkInput(String value) async {
//     if (value.length == 4) {
//       try {
//         print('👉 Checking input: $value');
//
//         // Fetch all records (you can optimize this if data is large)
//         final allRecords = await _fetchMessages();
//
//         // Find the record with matching 'id'
//         final matched = allRecords.firstWhere(
//               (record) => record['id'].toString() == value,
//           orElse: () => {},
//         );
//
//         if (matched.isEmpty) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('No matching ID found')),
//             );
//           }
//           return;
//         }
//
//         final emlId = matched['eml_id'];
//         final now = DateTime.now();
//         await Supabase.instance.client
//             .schema('hr')
//             .from('attendance')
//             .insert({
//           'date_att': now.toIso8601String().split('T')[0],
//           'emi_id': emlId,
//           'check_in': now.toIso8601String(),
//           'check_out': now.add(const Duration(hours: 1)).toIso8601String(),
//           'dt': '01:00:00', // Optional: format as per schema
//           'ot': '00:00:00', // Optional: format as per schema
//           'in': now.toIso8601String(),
//           'out': now.add(const Duration(hours: 1)).toIso8601String(),
//         });
//
//         _controller.clear();
//         print('✅ Inserted attendance successfully');
//
//         final fetched = await _fetchMessages();
//         print('📥 Total fetched records after insert: ${fetched.length}');
//
//         if (mounted) {
//           setState(() {
//             _messageList = fetched;
//           });
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Inserted and fetched successfully')),
//           );
//         }
//       } catch (e) {
//         print('❌ Insert error: $e');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Error: $e')),
//           );
//         }
//       }
//     }
//   }
//
//   // Function to fetch data from another table
//   Future<List<Map<String, dynamic>>> _fetchMessages() async {
//     try {
//       final client = Supabase.instance.client;
//       int chunkSize = 1000;
//       int start = 0;
//       List<Map<String, dynamic>> allData = [];
//
//       while (true) {
//
//         final chunk = await client
//             .schema('hr')
//             .from('eml') // specify schema
//             .select('"id", "id"')
//             .order('id', ascending: true)
//             .range(start, start + chunkSize - 1);
//         allData.addAll(List<Map<String, dynamic>>.from(chunk));
//
//         if (chunk.length < chunkSize) {
//           break;
//         }
//         start += chunkSize;
//       }
//       print('📦 employe Fetched ${allData.length} records total');
//       return allData;
//     } on PostgrestException catch (e) {
//       print('🚨 Supabase error: ${e.message}');
//       rethrow; // Optionally rethrow the exception if you want it to propagate
//     } on Exception catch (e) {
//       print('🚨 General error: $e');
//       rethrow; // Optionally rethrow the exception if you want it to propagate
//     }
//   }
//   @override
//   void initState() {
//     super.initState();
//     _fetchMessages(); // Fetch on load
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Supabase Insert & Fetch')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _controller,
//               maxLength: 4,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: 'Enter 4-digit code',
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: _checkInput,
//             ),
//             const SizedBox(height: 20),
//             const Text('Fetched Data:', style: TextStyle(fontWeight: FontWeight.bold)),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _messageList.length,
//                 itemBuilder: (context, index) {
//                   final item = _messageList[index];
//                   return Card(
//                     child: ListTile(
//                       title: Text(item['name'] ?? 'No name'),
//                       subtitle: Text('Department: ${item['department'] ?? 'Unknown'}'),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const TodayAttendancePage(),
              //   ),
              // );
            } else if (value == 'custom') {

              // showDialog(
              //     context: context,
              //     builder: (context) => AlertDialog(
              //   title: const Text('Select Date Range'),
              //   content: SizedBox(
              //     width: MediaQuery.of(context).size.width * 0.9,
              //     height: MediaQuery.of(context).size.height * 0.6,
              //     child: SfCalendar(
              //       view: CalendarView.month,
              //       selectionDecoration: BoxDecoration(
              //         color: Colors.transparent,
              //         border: Border.all(
              //           color: Theme.of(context).primaryColor,
              //           width: 2,
              //         ),
              //         borderRadius: const BorderRadius.all(Radius.circular(4))),
              //         onSelectionChanged: (CalendarSelectionDetails details) {
              //           if (details.date != null) {
              //             Navigator.pop(context);
              //             Navigator.push(
              //               context,
              //               MaterialPageRoute(
              //                 builder: (context) => CustomAttendancePage(
              //                   selectedDate: details.date!,
              //                 ),
              //               ),
              //             );
              //           }
              //         },
              //         monthViewSettings: const MonthViewSettings(
              //           showAgenda: true,
              //         ),
              //       ),
              //     ),
              //     actions: [
              //       TextButton(
              //         onPressed: () => Navigator.pop(context),
              //         child: const Text('Cancel'),
              //       ),
              //     ],
              //   ),
              // );
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


// class TodayAttendancePage extends StatelessWidget {
//   const TodayAttendancePage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Today's Attendance"),
//       ),
//       body: Column(
//         children: [
//           SizedBox(
//             height: 300,
//             child: SfCalendar(
//               view: CalendarView.day,
//               initialDisplayDate: DateTime.now(),
//               dataSource: _getCalendarDataSource(),
//             ),
//           ),
//           const Expanded(
//             child: Center(
//               child: Text("Today's attendance details"),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class CustomAttendancePage extends StatelessWidget {
//   final DateTime selectedDate;
//
//   const CustomAttendancePage({
//     super.key,
//     required this.selectedDate,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Attendance for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
//       ),
//       body: Column(
//         children: [
//           SizedBox(
//             height: 300,
//             child: SfCalendar(
//               view: CalendarView.month,
//               initialSelectedDate: selectedDate,
//               dataSource: _getCalendarDataSource(),
//               monthViewSettings: const MonthViewSettings(
//                 showAgenda: true,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Center(
//               child: Text('Custom attendance for ${selectedDate.toString().split(' ')[0]}'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Sample data source for calendar
// class _AppointmentDataSource extends CalendarDataSource {
//   _AppointmentDataSource(List<Appointment> source) {
//     appointments = source;
//   }
// }
//
// CalendarDataSource _getCalendarDataSource() {
//   List<Appointment> appointments = <Appointment>[];
//
//   // Add sample data - replace with your actual attendance data
//   appointments.add(Appointment(
//     startTime: DateTime.now(),
//     endTime: DateTime.now().add(const Duration(hours: 1)),
//     subject: 'Present',
//     color: Colors.green,
//   ));
//
//   return _AppointmentDataSource(appointments);
// }