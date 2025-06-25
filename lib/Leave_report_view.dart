// import 'package:flutter/material.dart';
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
//   DateTime _selectedMonth = DateTime.now();
//   late DateTime _visibleDate;
//
//   @override
//   void initState() {
//     super.initState();
//     _visibleDate = DateTime(_selectedMonth.year, _selectedMonth.month);
//   }
//
//   List<String> _monthList = List.generate(12, (index) {
//     final month = DateTime(0, index + 1);
//     return DateFormat.MMMM().format(month); // e.g. January, February
//   });
//
//   void _onMonthChanged(String? selectedMonth) {
//     if (selectedMonth == null) return;
//
//     int monthIndex = _monthList.indexOf(selectedMonth) + 1;
//     setState(() {
//       _selectedMonth = DateTime(_selectedMonth.year, monthIndex);
//       _visibleDate = _selectedMonth;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Calendar View with ID & Month Select'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: TextField(
//                     controller: _idController,
//                     decoration: const InputDecoration(
//                       labelText: 'Enter ID',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   flex: 2,
//                   child: DropdownButtonFormField<String>(
//                     value: DateFormat.MMMM().format(_selectedMonth),
//                     items: _monthList
//                         .map((month) => DropdownMenuItem(
//                       value: month,
//                       child: Text(month),
//                     ))
//                         .toList(),
//                     onChanged: _onMonthChanged,
//                     decoration: const InputDecoration(
//                       labelText: 'Select Month',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: SfCalendar(
//                 view: CalendarView.month,
//                 initialDisplayDate: _visibleDate,
//                 monthViewSettings: const MonthViewSettings(
//                   showAgenda: true,
//                 ),
//                 dataSource: _getCalendarDataSource(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   CalendarDataSource _getCalendarDataSource() {
//     return AppointmentDataSource([
//       Appointment(
//         startTime: DateTime.now(),
//         endTime: DateTime.now().add(const Duration(hours: 2)),
//         subject: 'Initial Meeting',
//         color: Colors.blue,
//       ),
//     ]);
//   }
// }
//
// class AppointmentDataSource extends CalendarDataSource {
//   AppointmentDataSource(List<Appointment> source) {
//     appointments = source;
//   }
// }


import 'package:flutter/material.dart';
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
  List<String> _monthList = List.generate(12, (index) {
    final month = DateTime(0, index + 1);
    return DateFormat.MMMM().format(month);
  });

  @override
  void initState() {
    super.initState();
    _calendarController.displayDate = _selectedMonth;
  }

  void _onMonthChanged(String? selectedMonth) {
    if (selectedMonth == null) return;

    int monthIndex = _monthList.indexOf(selectedMonth) + 1;
    setState(() {
      _selectedMonth = DateTime(DateTime.now().year, monthIndex);
      _calendarController.displayDate = _selectedMonth;
    });
  }

  @override
  void dispose() {
    _calendarController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Responsive Calendar with ID')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'Enter ID',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // You can react to ID input here if needed
                    },
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
            const SizedBox(height: 20),
            Expanded(
              child: SfCalendar(
                controller: _calendarController,
                view: CalendarView.month,
                monthViewSettings: const MonthViewSettings(showAgenda: true),
                dataSource: _getCalendarDataSource(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CalendarDataSource _getCalendarDataSource() {
    return AppointmentDataSource([
      Appointment(
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        subject: 'Sample Event',
        color: Colors.green,
      ),
    ]);
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> appointments) {
    this.appointments = appointments;
  }
}
