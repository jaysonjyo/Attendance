import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final TextEditingController _idController = TextEditingController();
  final CalendarController _calendarController = CalendarController();

  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _employeeList = [];
  bool _isLoading = false;

  List<String> _monthList = List.generate(12, (index) {
    final month = DateTime(0, index + 1);
    return DateFormat.MMMM().format(month);
  });

  @override
  void initState() {
    super.initState();
    _calendarController.displayDate = _selectedMonth;
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .schema('hr')
          .from('attendance')
          .select('id, date_att, eml_id, check_in, check_out, dt, ot')
          .order('id', ascending: true);

      setState(() {
        _employeeList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching employees: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMonthChanged(String? selectedMonth) {
    if (selectedMonth == null) return;

    int monthIndex = _monthList.indexOf(selectedMonth) + 1;
    setState(() {
      _selectedMonth = DateTime(DateTime.now().year, monthIndex);
      _calendarController.displayDate = _selectedMonth;
    });
  }

  void _handleCalendarTap(CalendarTapDetails details) {
    if (details.date != null) {
      setState(() {
        _selectedDate = details.date!;
      });
    }
  }

  List<Map<String, dynamic>> _getAttendanceForSelectedDate() {
    final enteredId = _idController.text.trim();
    if (enteredId.isEmpty) return [];

    return _employeeList.where((record) {
      final recordDate = DateTime.tryParse(record['date_att'] ?? '');
      return record['eml_id'].toString() == enteredId &&
          recordDate != null &&
          recordDate.year == _selectedDate.year &&
          recordDate.month == _selectedDate.month &&
          recordDate.day == _selectedDate.day;
    }).toList();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    _idController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final attendanceRecords = _getAttendanceForSelectedDate();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Calendar with Attendance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Employee ID',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: DateFormat.MMMM().format(_selectedMonth),
                    decoration: const InputDecoration(
                      labelText: 'Select Month',
                      border: OutlineInputBorder(),
                    ),
                    items: _monthList.map((month) {
                      return DropdownMenuItem(value: month, child: Text(month));
                    }).toList(),
                    onChanged: _onMonthChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Compact Calendar
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                height: 320,
                child: SfCalendar(
                  controller: _calendarController,
                  view: CalendarView.month,
                  onTap: _handleCalendarTap,
                  monthViewSettings: const MonthViewSettings(showAgenda: false),
                  monthCellBuilder: _monthCellBuilder,
                ),
              ),

            const SizedBox(height: 8),

            // Fixed Attendance Section
            Text(
              'Attendance: ${DateFormat.yMMMMd().format(_selectedDate)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),

            if (_idController.text.trim().isEmpty)
              const Text('Please enter an Employee ID.')
            else if (attendanceRecords.isEmpty)
              Card(child: ListTile(title: const Text('Absent', style: TextStyle(color: Colors.red))))
            else
              ...attendanceRecords.map((record) => GestureDetector(onTap: (){
                print("${record['dt'] ?? '-'} | OT: ${record['ot'] ?? '-'}");
              },
                child: Card(color:Color(0xFF05D10F) ,
                  child: ListTile(
                    dense: true,
                    title: Text(
                      'IN: ${_formatTimeFromTimestamp(record['check_in'])}  |  OUT: ${_formatTimeFromTimestamp(record['check_out'])}',
                   style: TextStyle(color: Colors.white), ),

                    subtitle: Text(  'DT: ${_formatDuration(record['dt'])} | OT: ${_formatDuration(record['ot'])}', style: TextStyle(color: Colors.black),),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  String _formatDuration(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '-';
    try {
      final parts = timeString.split('.');
      return parts.first; // returns only HH:mm:ss
    } catch (e) {
      return '-';
    }
  }

  String _formatTimeFromTimestamp(String? isoString) {
    if (isoString == null || isoString.trim().isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('h:mm a').format(dateTime); // e.g. 3:05 PM
    } catch (e) {
      return '-';
    }
  }

  Widget _monthCellBuilder(BuildContext context, MonthCellDetails details) {
    final date = details.date;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final enteredId = _idController.text.trim();

    final isInCurrentMonth = date.month == _selectedMonth.month &&
        date.year == _selectedMonth.year;

    if (enteredId.isEmpty || date.isAfter(today) || !isInCurrentMonth) {
      return Center(
        child: Text(
          '${date.day}',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final isPresent = _employeeList.any((record) {
      final recordDate = DateTime.tryParse(record['date_att'] ?? '');
      return record['eml_id'].toString() == enteredId &&
          recordDate != null &&
          recordDate.year == date.year &&
          recordDate.month == date.month &&
          recordDate.day == date.day;
    });

    final bgColor = isPresent ? const Color(0xFF05D10F) : const Color(0xFFC50B00);
    final textColor = Colors.white;

    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${date.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:syncfusion_flutter_calendar/calendar.dart';
// import 'package:intl/intl.dart';
//
// class CalendarPage extends StatefulWidget {
//   const CalendarPage({Key? key}) : super(key: key);
//
//   @override
//   State<CalendarPage> createState() => _CalendarPageState();
// }
//
// class _CalendarPageState extends State<CalendarPage> {
//   final TextEditingController _idController = TextEditingController();
//   final CalendarController _calendarController = CalendarController();
//
//   DateTime _selectedMonth = DateTime.now();
//   List<Map<String, dynamic>> _employeeList = [];
//   bool _isLoading = false;
//
//   List<String> _monthList = List.generate(12, (index) {
//     final month = DateTime(0, index + 1);
//     return DateFormat.MMMM().format(month);
//   });
//
//   @override
//   void initState() {
//     super.initState();
//     _calendarController.displayDate = _selectedMonth;
//     _fetchEmployees();
//   }
//
//   Future<void> _fetchEmployees() async {
//     setState(() => _isLoading = true);
//     try {
//       final response = await Supabase.instance.client
//           .schema('hr')
//           .from('attendance')
//           .select('id, date_att, eml_id, check_in, check_out, dt, ot')
//           .order('id', ascending: true);
//
//       setState(() {
//         _employeeList = List<Map<String, dynamic>>.from(response);
//       });
//     } catch (e) {
//       if (mounted) {
//         print("Error fetching employees: $e");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching employees: $e')),
//         );
//       }
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   void _onMonthChanged(String? selectedMonth) {
//     if (selectedMonth == null) return;
//
//     int monthIndex = _monthList.indexOf(selectedMonth) + 1;
//     setState(() {
//       _selectedMonth = DateTime(DateTime.now().year, monthIndex);
//       _calendarController.displayDate = _selectedMonth;
//     });
//   }
// //   List<Appointment> _generateAppointments() {
// //     final enteredId = _idController.text.trim();
// //     if (enteredId.isEmpty) return [];
// //
// //     final now = DateTime.now();
// //     final today = DateTime(now.year, now.month, now.day);
// //
// //     final attendanceRecords = _employeeList.where((record) {
// //       final idMatch = record['eml_id'].toString() == enteredId;
// //       final date = DateTime.tryParse(record['date_att'] ?? '');
// //       final monthMatch = date != null &&
// //           date.year == _selectedMonth.year &&
// //           date.month == _selectedMonth.month;
// //       return idMatch && monthMatch;
// //     }).toList();
// //
// //     // Group records by day
// //     final Map<int, List<Map<String, dynamic>>> groupedByDay = {};
// //     for (var record in attendanceRecords) {
// //       final date = DateTime.tryParse(record['date_att'] ?? '');
// //       if (date != null) {
// //         groupedByDay.putIfAbsent(date.day, () => []).add(record);
// //       }
// //     }
// //
// //     final totalDays = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
// //     final appointments = <Appointment>[];
// //
// //     for (int day = 1; day <= totalDays; day++) {
// //       final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
// //       if (date.isAfter(today)) continue;
// //
// //       final records = groupedByDay[day];
// //
// //       if (records != null && records.isNotEmpty) {
// //         for (var record in records) {
// //           final checkIn = _parseTime(record['check_in'] ?? '', date);
// //           final checkOut = (record['check_out']?.toString().trim().isNotEmpty ?? false)
// //               ? _parseTime(record['check_out'].toString(), date)
// //               : null;
// //
// //           final effectiveCheckOut = checkOut ?? DateTime(date.year, date.month, date.day, 0, 0);
// //           appointments.add(
// //             Appointment(
// //               startTime: checkIn!,
// //               endTime: checkOut ?? DateTime(date.year, date.month, date.day, 0, 0),
// //               subject: checkOut == null
// //                   ? 'In: ${_formatTime(checkIn)}\nOut: -\n(No check-out recorded)'
// //                   : 'In: ${_formatTime(checkIn)}\nOut: ${_formatTime(checkOut)}',
// //               color: checkOut == null ? Colors.orange : Colors.green,
// //               isAllDay: false,
// //             ),);
// //
// //           print('Check-in: ${_formatTime(checkIn)}, Check-out: ${_formatTime(checkOut)}');
// // print("checkOut =$checkOut");
// //           print("_formatTime(checkOut) =${_formatTime(checkOut)}");
// //           print("checkOut =$checkOut");
// //           print("effectiveCheckOut$effectiveCheckOut");
// //
// //
// //         }
// //       } else {
// //         appointments.add(
// //           Appointment(
// //             startTime: date,
// //             endTime: date,
// //             subject: 'Absent',
// //             color: const Color(0xFFC50B00),
// //             isAllDay: true,
// //           ),
// //         );
// //
// //       }
// //     }
// //
// //     return appointments;
// //   }
//
// // Converts 24-hour time to 12-hour time with AM/PM
//   String _formatTime(DateTime? time) {
//     if (time == null) return '-';
//     final hour = time.hour.toString().padLeft(2, '0');
//     final minute = time.minute.toString().padLeft(2, '0');
//     return '$hour:$minute';
//   }
//
//
//
// // Safely parse time from various formats like "2025-06-25T15" or "2025-06-25T15:30"
//   DateTime _parseTime(String timeStr, DateTime baseDate) {
//     try {
//       if (timeStr.isEmpty) {
//         return DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 0);
//       }
//
//       if (timeStr.length == 13 && timeStr.contains('T')) {
//         // e.g., "2025-06-25T15" → add ":00"
//         timeStr += ':00';
//       }
//
//       final fullTime = DateTime.parse(timeStr);
//       // Truncate to remove seconds and milliseconds
//       return DateTime(fullTime.year, fullTime.month, fullTime.day, fullTime.hour, fullTime.minute);
//     } catch (e) {
//       return DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 0);
//     }
//   }
//
//
//   // CalendarDataSource _getCalendarDataSource() {
//   //   return AppointmentDataSource(_generateAppointments());
//   // }
//
//   @override
//   void dispose() {
//     _calendarController.dispose();
//     _idController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       appBar: AppBar(title: const Text('Calendar with Attendance')),
//       body: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     keyboardType: TextInputType.number,
//                     controller: _idController,
//                     decoration: const InputDecoration(
//                       labelText: 'Enter Employee ID',
//                       border: OutlineInputBorder(),
//                     ),
//                     onChanged: (value) {
//                       setState(() {}); // Refresh calendar
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     value: DateFormat.MMMM().format(_selectedMonth),
//                     decoration: const InputDecoration(
//                       labelText: 'Select Month',
//                       border: OutlineInputBorder(),
//                     ),
//                     items: _monthList.map((month) {
//                       return DropdownMenuItem(value: month, child: Text(month));
//                     }).toList(),
//                     onChanged: _onMonthChanged,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             if (_isLoading)
//               const Expanded(child: Center(child: CircularProgressIndicator()))
//             else
//               Expanded(
//                 child:
//                 SfCalendar(
//                   controller: _calendarController,
//                   view: CalendarView.month,
//                   monthViewSettings: const MonthViewSettings(showAgenda: true),
//                //   dataSource: _getCalendarDataSource(),
//                   monthCellBuilder: _monthCellBuilder,
//                 ),
//
//
//                 // SfCalendar(
//                 //   controller: _calendarController,
//                 //   view: CalendarView.month,
//                 //   monthViewSettings: const MonthViewSettings(showAgenda: true),
//                 //   dataSource: _getCalendarDataSource(),
//                 // ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//   Widget _monthCellBuilder(BuildContext context, MonthCellDetails details) {
//     final date = details.date;
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final enteredId = _idController.text.trim();
//
//     final isInCurrentMonth = date.month == _selectedMonth.month &&
//         date.year == _selectedMonth.year;
//
//     // Skip if no ID or future date or not in selected month
//     if (enteredId.isEmpty || date.isAfter(today) || !isInCurrentMonth) {
//       return Center(
//         child: Text(
//           '${date.day}',
//           style: const TextStyle(color: Colors.grey),
//         ),
//       );
//     }
//
//     // Check if this date has attendance
//     final isPresent = _employeeList.any((record) {
//       final recordDate = DateTime.tryParse(record['date_att'] ?? '');
//       return record['eml_id'].toString() == enteredId &&
//           recordDate != null &&
//           recordDate.year == date.year &&
//           recordDate.month == date.month &&
//           recordDate.day == date.day;
//     });
//
//     final bgColor = isPresent ? Color(0xFF05D10F) :  Color(0xFFC50B00);
//     final textColor = Colors.white;
//
//     return Center(
//       child: Container(
//         width: 36,
//         height: 36,
//         decoration: BoxDecoration(
//           color: bgColor,
//           shape: BoxShape.circle,
//         ),
//         alignment: Alignment.center,
//         child: Text(
//           '${date.day}',
//           style: TextStyle(
//             color: textColor,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
//
// }
//
// class AppointmentDataSource extends CalendarDataSource {
//   AppointmentDataSource(List<Appointment> appointments) {
//     this.appointments = appointments;
//   }
// }
