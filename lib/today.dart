import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class Today extends StatefulWidget {
  const Today({super.key});

  @override
  State<Today> createState() => _TodayState();
}

class _TodayState extends State<Today> {
  List<Map<String, dynamic>> _employeeList_att = [];
  bool _isLoading = false;
  Set<int> _expandedIndices = {};
  Future<void> _fetchToday() async {
    setState(() => _isLoading = true);
    try {
      final today = DateTime.now();
      final todayString = "${today.year.toString().padLeft(4, '0')}-"
          "${today.month.toString().padLeft(2, '0')}-"
          "${today.day.toString().padLeft(2, '0')}";
      final response = await Supabase.instance.client
          .schema('hr')
          .from('attendance')
          .select('id, date_att, eml_id, check_in, check_out, dt, ot')
          .eq('date_att', todayString)
          .order('id', ascending: true);

      setState(() {
        _employeeList_att = List<Map<String, dynamic>>.from(response);
        print(_employeeList_att);
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
  @override
  void initState() {
    super.initState();
    _fetchToday();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Attendance'),
      ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _employeeList_att.isEmpty
        ? const Center(child: Text('No attendance records found for today.')):
    ListView.builder(
      itemCount: _employeeList_att.length,
      itemBuilder: (context, index) {
        final item = _employeeList_att[index];
        final isExpanded = _expandedIndices.contains(index);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Slidable(
                key: ValueKey(item['id']),
                startActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) async {
                        final newCheckIn = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            DateTime.tryParse(item['check_in'] ?? '') ?? DateTime.now(),
                          ),
                        );

                        if (newCheckIn != null) {
                          final now = DateTime.now();
                          final updatedCheckIn = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            newCheckIn.hour,
                            newCheckIn.minute,
                          ).toIso8601String();

                          await Supabase.instance.client
                              .schema('hr')
                              .from('attendance')
                              .update({'check_in': updatedCheckIn})
                              .eq('id', item['id']);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Check-in updated')),
                          );

                          _fetchToday(); // Call your updated fetch method
                        }
                      },
                      backgroundColor: Colors.blue,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),

                  ],
                ),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) async {
                        await Supabase.instance.client
                            .schema('hr')
                            .from('attendance')
                            .delete()
                            .eq('id', item['id']);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Record deleted')),
                        );

                        _fetchToday();
                      },
                      backgroundColor: Colors.red,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedIndices.remove(index);
                      } else {
                        _expandedIndices.add(index);
                      }
                    });
                  },
                  leading: CircleAvatar(
                    child: Text(item['eml_id']?.toString().substring(0, 1) ?? '?'),
                  ),
                  title: Text('Employee ID: ${item['eml_id'] ?? 'N/A'}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Check-in: ${_formatTime(item['check_in'])}'),
                      Text('Check-out: ${_formatTime(item['check_out'])}'),
                    ],
                  ),
                  trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                ),
              ),

              // Expanded section
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(color: Colors.grey[300]),
                      Text('DT: ${item['dt'] ?? 'N/A'}'),
                      Text('OT: ${item['ot'] ?? 'N/A'}'),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    )

      //     : ListView.builder(
    //   itemCount: _employeeList_att.length,
    //   itemBuilder: (context, index) {
    //     final item = _employeeList_att[index];
    //      return Card(
    //       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    //       child: Slidable(
    //         key: ValueKey(item['id']), // unique key
    //         startActionPane: ActionPane(
    //           motion: const DrawerMotion(),
    //           children: [
    //             SlidableAction(
    //               onPressed: (_) async {
    //                 final newCheckIn = await showTimePicker(
    //                   context: context,
    //                   initialTime: TimeOfDay.fromDateTime(DateTime.tryParse(item['check_in'] ?? '') ?? DateTime.now()),
    //                 );
    //                 if (newCheckIn != null) {
    //                   final now = DateTime.now();
    //                   final updatedCheckIn = DateTime(
    //                     now.year,
    //                     now.month,
    //                     now.day,
    //                     newCheckIn.hour,
    //                     newCheckIn.minute,
    //                   ).toIso8601String();
    //
    //                   final response = await Supabase.instance.client
    //                       .schema('hr')
    //                       .from('attendance')
    //                       .update({'check_in': updatedCheckIn})
    //                       .eq('id', item['id']);
    //
    //                   ScaffoldMessenger.of(context).showSnackBar(
    //                     const SnackBar(content: Text('Check-in updated')),
    //                   );
    //
    //                   _fetchToday(); // Refresh list
    //                 }
    //               },
    //               // onPressed: (context) {
    //               //   // Add your edit logic here
    //               //   ScaffoldMessenger.of(context).showSnackBar(
    //               //     const SnackBar(content: Text('Edit action tapped')),
    //               //   );
    //               // },
    //               backgroundColor: Colors.blue,
    //               icon: Icons.edit,
    //               label: 'Edit',
    //             ),
    //           ],
    //         ),
    //         endActionPane: ActionPane(
    //           motion: const DrawerMotion(),
    //           children: [
    //             SlidableAction(
    //               onPressed: (_) async {
    //                 await Supabase.instance.client
    //                     .schema('hr')
    //                     .from('attendance')
    //                     .delete()
    //                     .eq('id', item['id']);
    //
    //                 ScaffoldMessenger.of(context).showSnackBar(
    //                   const SnackBar(content: Text('Record deleted')),
    //                 );
    //
    //                 _fetchToday(); // Refresh list
    //               },
    //               // onPressed: (context) {
    //               //   // Add your delete logic here
    //               //   ScaffoldMessenger.of(context).showSnackBar(
    //               //     const SnackBar(content: Text('Delete action tapped')),
    //               //   );
    //               // },
    //               backgroundColor: Colors.red,
    //               icon: Icons.delete,
    //               label: 'Delete',
    //             ),
    //           ],
    //         ),
    //         child: ListTile(
    //           onTap: () {
    //             showModalBottomSheet(
    //               context: context,
    //               shape: const RoundedRectangleBorder(
    //                 borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    //               ),
    //               builder: (_) {
    //                 return Padding(
    //                   padding: const EdgeInsets.all(16),
    //                   child: Column(
    //                     mainAxisSize: MainAxisSize.min,
    //                     crossAxisAlignment: CrossAxisAlignment.start,
    //                     children: [
    //                       Text(
    //                         'Details for Employee ID: ${item['eml_id']}',
    //                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    //                       ),
    //                       const SizedBox(height: 12),
    //                       Text('DT: ${item['dt'] ?? 'N/A'}'),
    //                       Text('OT: ${item['ot'] ?? 'N/A'}'),
    //                     ],
    //                   ),
    //                 );
    //               },
    //             );
    //           },
    //           leading: CircleAvatar(
    //             child: Text(item['eml_id']?.toString() ?? '?'),
    //           ),
    //           title: Text('Employee ID: ${item['eml_id'] ?? 'N/A'}'),
    //           subtitle: Column(
    //             crossAxisAlignment: CrossAxisAlignment.start,
    //             children: [
    //               Text('Check-in: ${item['check_in'] ?? 'N/A'}'),
    //               Text('Check-out: ${item['check_out'] ?? 'N/A'}'),
    //             ],
    //           ),
    //         ),
    //       ),
    //     );
    //
    //     //   Card(
    //     //   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    //     //   child: ListTile(
    //     //     onTap: () {
    //     //       showModalBottomSheet(
    //     //         context: context,
    //     //         shape: const RoundedRectangleBorder(
    //     //           borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    //     //         ),
    //     //         builder: (_) {
    //     //           return Padding(
    //     //             padding: const EdgeInsets.all(16),
    //     //             child: Column(
    //     //               mainAxisSize: MainAxisSize.min,
    //     //               crossAxisAlignment: CrossAxisAlignment.start,
    //     //               children: [
    //     //                 Text(
    //     //                   'Details for Employee ID: ${item['eml_id']}',
    //     //                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    //     //                 ),
    //     //                 const SizedBox(height: 12),
    //     //                 Text('DT: ${item['dt'] ?? 'N/A'}'),
    //     //                 Text('OT: ${item['ot'] ?? 'N/A'}'),
    //     //               ],
    //     //             ),
    //     //           );
    //     //         },
    //     //       );
    //     //     },
    //     //     leading: CircleAvatar(
    //     //       child: Text(item['eml_id']?.toString() ?? '?'),
    //     //     ),
    //     //     title: Text('Employee ID: ${item['eml_id'] ?? 'N/A'}'),
    //     //     subtitle: Column(
    //     //       crossAxisAlignment: CrossAxisAlignment.start,
    //     //       children: [
    //     //         Text('Check-in: ${item['check_in'] ?? 'N/A'}'),
    //     //         Text('Check-out: ${item['check_out'] ?? 'N/A'}'),
    //     //       ],
    //     //     ),
    //     //   ),
    //     // );
    //   },
    // ),
    );
  }
}
