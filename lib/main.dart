import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const DoctorScheduleApp());
}

class DoctorScheduleApp extends StatelessWidget {
  const DoctorScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor On-Call Scheduler',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ScheduleHomePage(),
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://grinpath.com/drs/api';
  
  static Future<List<Doctor>> getDoctors() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/doctors.php'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<Doctor> doctors = [];
          for (var doctorData in data['data']) {
            doctors.add(Doctor.fromJson(doctorData));
          }
          return doctors;
        }
      }
      throw Exception('Failed to load doctors');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<List<OnCallSchedule>> getSchedules({String? date}) async {
    try {
      String url = '$baseUrl/schedules.php';
      if (date != null) {
        url += '?date=$date';
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<OnCallSchedule> schedules = [];
          for (var scheduleData in data['data']) {
            schedules.add(OnCallSchedule.fromJson(scheduleData));
          }
          return schedules;
        }
      }
      throw Exception('Failed to load schedules');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<bool> createSchedule(Map<String, dynamic> scheduleData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/schedules.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(scheduleData),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> updateDoctor(Map<String, dynamic> doctorData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/doctors.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(doctorData),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> updateSchedule(Map<String, dynamic> scheduleData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/schedules.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(scheduleData),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  static Future<List<OnCallSchedule>> getAllSchedules() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/schedules.php'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<OnCallSchedule> schedules = [];
          for (var scheduleData in data['data']) {
            schedules.add(OnCallSchedule.fromJson(scheduleData));
          }
          return schedules;
        }
      }
      throw Exception('Failed to load all schedules');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<bool> deleteSchedule(int scheduleId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/schedules.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': scheduleId}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

class Doctor {
  final int id;
  final String name;
  final String specialty;
  final List<int> workDays;
  final TimeOfDay shiftStart;
  final TimeOfDay shiftEnd;
  final List<DateTime> leaveDays;
  final List<DateTime> offDays;
  DateTime? lastOnCallDate;
  bool isOnMandatoryRest;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.workDays,
    required this.shiftStart,
    required this.shiftEnd,
    required this.leaveDays,
    required this.offDays,
    this.lastOnCallDate,
    this.isOnMandatoryRest = false,
  });
  
  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      specialty: json['specialty'],
      workDays: List<int>.from(json['work_days']),
      shiftStart: _timeFromString(json['shift_start']),
      shiftEnd: _timeFromString(json['shift_end']),
      leaveDays: _datesFromJsonArray(json['leave_days']),
      offDays: _datesFromJsonArray(json['off_days']),
      lastOnCallDate: json['last_on_call_date'] != null 
          ? DateTime.parse(json['last_on_call_date']) 
          : null,
      isOnMandatoryRest: json['is_on_mandatory_rest'] == '1' || json['is_on_mandatory_rest'] == true,
    );
  }
  
  static TimeOfDay _timeFromString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
  
  static List<DateTime> _datesFromJsonArray(dynamic jsonArray) {
    if (jsonArray == null) return [];
    List<DateTime> dates = [];
    for (String dateStr in List<String>.from(jsonArray)) {
      dates.add(DateTime.parse(dateStr));
    }
    return dates;
  }
}

class OnCallSchedule {
  final int id;
  final DateTime date;
  final Doctor doctor;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  OnCallSchedule({
    required this.id,
    required this.date,
    required this.doctor,
    required this.startTime,
    required this.endTime,
  });
  
  factory OnCallSchedule.fromJson(Map<String, dynamic> json) {
    return OnCallSchedule(
      id: int.parse(json['id'].toString()),
      date: DateTime.parse(json['schedule_date']),
      doctor: Doctor(
        id: int.parse(json['doctor_id'].toString()),
        name: json['doctor_name'],
        specialty: json['specialty'],
        workDays: [], // Not needed for display
        shiftStart: const TimeOfDay(hour: 0, minute: 0),
        shiftEnd: const TimeOfDay(hour: 0, minute: 0),
        leaveDays: [],
        offDays: [],
      ),
      startTime: Doctor._timeFromString(json['start_time']),
      endTime: Doctor._timeFromString(json['end_time']),
    );
  }
}

class ScheduleHomePage extends StatefulWidget {
  const ScheduleHomePage({super.key});

  @override
  State<ScheduleHomePage> createState() => _ScheduleHomePageState();
}

class _ScheduleHomePageState extends State<ScheduleHomePage> {
  List<Doctor> doctors = [];
  List<OnCallSchedule> schedules = [];
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  
  // Public holidays - you can customize this list
  final List<DateTime> publicHolidays = [
    DateTime(2024, 1, 1),   // New Year's Day
    DateTime(2024, 12, 25), // Christmas Day
    // Add more public holidays as needed
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final doctorsData = await ApiService.getDoctors();
      final schedulesData = await ApiService.getSchedules(
        date: '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'
      );
      
      setState(() {
        doctors = doctorsData;
        schedules = schedulesData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isWeekendOrHoliday(DateTime date) {
    // Check if it's weekend (Saturday = 6, Sunday = 7)
    if (date.weekday == 6 || date.weekday == 7) {
      return true;
    }
    
    // Check if it's a public holiday
    return publicHolidays.any((holiday) => 
      holiday.day == date.day && 
      holiday.month == date.month && 
      holiday.year == date.year
    );
  }

  Map<String, String> _getOnCallTimes(DateTime date) {
    if (_isWeekendOrHoliday(date)) {
      // Weekend/Holiday: 24 hours (8am to 8am next day)
      return {
        'start_time': '08:00:00',
        'end_time': '08:00:00',
      };
    } else {
      // Weekday: 16 hours (4pm to 8am next day)
      return {
        'start_time': '16:00:00',
        'end_time': '08:00:00',
      };
    }
  }

  String _getOnCallDescription(DateTime date) {
    if (_isWeekendOrHoliday(date)) {
      return '24-hour on-call (Weekend/Holiday): 8:00 AM - 8:00 AM next day';
    } else {
      return '16-hour on-call (Weekday): 4:00 PM - 8:00 AM next day';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor On-Call Scheduler'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: _showScheduleReport,
            tooltip: 'View Schedule Report',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date Selector with On-Call Info
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Selected Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            ElevatedButton(
                              onPressed: () => _selectDate(context),
                              child: const Text('Select Date'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isWeekendOrHoliday(selectedDate) 
                                ? Colors.orange.withOpacity(0.1) 
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isWeekendOrHoliday(selectedDate) 
                                  ? Colors.orange 
                                  : Colors.blue,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getOnCallDescription(selectedDate),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isWeekendOrHoliday(selectedDate) 
                                  ? Colors.orange[800] 
                                  : Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _generateSchedule,
                          child: const Text('Generate Schedule'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showDoctorList(context),
                          child: const Text('Manage Doctors'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showScheduleReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('View Schedule'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Schedule Display
                Expanded(
                  child: _buildScheduleList(),
                ),
              ],
            ),
    );
  }

  Widget _buildScheduleList() {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No schedules for this date.',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _getOnCallDescription(selectedDate),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap "Generate Schedule" to create one.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final isWeekendHoliday = _isWeekendOrHoliday(schedule.date);
        
        return Card(
          elevation: 3,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isWeekendHoliday ? Colors.orange : Colors.blue,
              child: Text(
                schedule.doctor.name.substring(0, 2),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              schedule.doctor.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schedule.doctor.specialty),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isWeekendHoliday ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isWeekendHoliday ? '24-hr Weekend/Holiday' : '16-hr Weekday',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isWeekendHoliday ? Colors.orange[800] : Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'On-Call: ${schedule.startTime.format(context)} - ${schedule.endTime.format(context)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditScheduleDialog(schedule),
                  tooltip: 'Change Doctor',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteSchedule(schedule),
                  tooltip: 'Delete Schedule',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditScheduleDialog(OnCallSchedule schedule) {
    final availableDoctors = _getAvailableDoctors(schedule.date);
    
    // Add the currently assigned doctor to the list if not already there
    final currentDoctor = doctors.firstWhere((d) => d.id == schedule.doctor.id);
    if (!availableDoctors.any((d) => d.id == currentDoctor.id)) {
      availableDoctors.add(currentDoctor);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Doctor for ${_formatDate(schedule.date)}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: availableDoctors.isEmpty
              ? const Center(
                  child: Text('No available doctors for this date'),
                )
              : ListView.builder(
                  itemCount: availableDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = availableDoctors[index];
                    final isCurrentlyAssigned = doctor.id == schedule.doctor.id;
                    
                    return Card(
                      color: isCurrentlyAssigned ? Colors.blue[50] : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrentlyAssigned ? Colors.blue : Colors.grey,
                          child: Text(
                            doctor.name.substring(0, 2),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          doctor.name,
                          style: TextStyle(
                            fontWeight: isCurrentlyAssigned ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doctor.specialty),
                            if (isCurrentlyAssigned)
                              const Text(
                                'Currently Assigned',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (doctor.isOnMandatoryRest)
                              const Text(
                                'On Mandatory Rest',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: isCurrentlyAssigned
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: isCurrentlyAssigned
                            ? null
                            : () => _reassignSchedule(schedule, doctor),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _reassignSchedule(OnCallSchedule schedule, Doctor newDoctor) async {
    Navigator.pop(context); // Close dialog first

    setState(() {
      isLoading = true;
    });

    try {
      // Get on-call times based on weekday/weekend
      final onCallTimes = _getOnCallTimes(schedule.date);
      
      // Update schedule with new doctor
      final updateData = {
        'id': schedule.id,
        'doctor_id': newDoctor.id,
        'start_time': onCallTimes['start_time']!,
        'end_time': onCallTimes['end_time']!,
      };

      final success = await ApiService.updateSchedule(updateData);
      
      if (success) {
        // Clear old doctor's mandatory rest if this was their only recent assignment
        final oldDoctor = doctors.firstWhere((d) => d.id == schedule.doctor.id);
        await ApiService.updateDoctor({
          'id': oldDoctor.id,
          'is_on_mandatory_rest': false,
        });

        // Update new doctor status
        await ApiService.updateDoctor({
          'id': newDoctor.id,
          'last_on_call_date': '${schedule.date.year}-${schedule.date.month.toString().padLeft(2, '0')}-${schedule.date.day.toString().padLeft(2, '0')}',
          'is_on_mandatory_rest': true,
        });

        // Reload data
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule reassigned to ${newDoctor.name} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to update schedule');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reassigning schedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _confirmDeleteSchedule(OnCallSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text(
          'Are you sure you want to delete the schedule for ${schedule.doctor.name} on ${_formatDate(schedule.date)}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSchedule(schedule);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSchedule(OnCallSchedule schedule) async {
    setState(() {
      isLoading = true;
    });

    try {
      final success = await ApiService.deleteSchedule(schedule.id);
      
      if (success) {
        // Clear doctor's mandatory rest status
        await ApiService.updateDoctor({
          'id': schedule.doctor.id,
          'is_on_mandatory_rest': false,
        });

        // Reload data
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule for ${schedule.doctor.name} deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to delete schedule');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting schedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Doctor> _getAvailableDoctors(DateTime date) {
    final weekday = date.weekday;
    
    return doctors.where((doctor) {
      // Check if doctor works on this day
      if (!doctor.workDays.contains(weekday)) return false;
      
      // Check if doctor is on leave
      if (doctor.leaveDays.any((leave) => 
          leave.day == date.day && 
          leave.month == date.month && 
          leave.year == date.year)) return false;
      
      // Check if doctor is on off day
      if (doctor.offDays.any((off) => 
          off.day == date.day && 
          off.month == date.month && 
          off.year == date.year)) return false;
      
      // Check if doctor needs mandatory rest
      if (doctor.lastOnCallDate != null) {
        final daysSinceLastOnCall = date.difference(doctor.lastOnCallDate!).inDays;
        if (daysSinceLastOnCall < 1) return false;
      }
      
      return true;
    }).toList();
  }

  Doctor? _selectOnCallDoctor(List<Doctor> availableDoctors, DateTime date) {
    // Priority logic: select doctor who hasn't been on call recently
    availableDoctors.sort((a, b) {
      if (a.lastOnCallDate == null && b.lastOnCallDate == null) return 0;
      if (a.lastOnCallDate == null) return -1;
      if (b.lastOnCallDate == null) return 1;
      return a.lastOnCallDate!.compareTo(b.lastOnCallDate!);
    });
    
    return availableDoctors.isNotEmpty ? availableDoctors.first : null;
  }

  Future<void> _generateSchedule() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get available doctors for the selected date
      final availableDoctors = _getAvailableDoctors(selectedDate);

      if (availableDoctors.isEmpty) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No available doctors for the selected date.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Select the doctor who hasn't been on call recently
      final selectedDoctor = _selectOnCallDoctor(availableDoctors, selectedDate);

      if (selectedDoctor == null) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No suitable doctor found for the selected date.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Get on-call times based on weekday/weekend/holiday
      final onCallTimes = _getOnCallTimes(selectedDate);

      // Prepare schedule data
      final scheduleData = {
        'doctor_id': selectedDoctor.id,
        'schedule_date': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
        'start_time': onCallTimes['start_time']!,
        'end_time': onCallTimes['end_time']!,
      };

      // Create schedule via API
      final success = await ApiService.createSchedule(scheduleData);

      if (success) {
        // Update doctor's last on-call date and mandatory rest status
        await ApiService.updateDoctor({
          'id': selectedDoctor.id,
          'last_on_call_date': scheduleData['schedule_date'],
          'is_on_mandatory_rest': true,
        });

        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule generated for ${selectedDoctor.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to generate schedule');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating schedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDoctorList(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Doctor Management'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(doctor.name.substring(0, 2)),
                  ),
                  title: Text(doctor.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.specialty),
                      Text('Work Days: ${doctor.workDays.map((d) => _getDayName(d)).join(', ')}'),
                      Text('Shift: ${doctor.shiftStart.format(context)} - ${doctor.shiftEnd.format(context)}'),
                      if (doctor.isOnMandatoryRest)
                        const Text(
                          'Status: Mandatory Rest Required',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditDoctorDialog(doctor);
                        },
                        tooltip: 'Edit Doctor',
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month, color: Colors.green),
                        onPressed: () {
                          Navigator.pop(context);
                          _showAvailabilityCalendar(doctor);
                        },
                        tooltip: 'Manage Availability',
                      ),
                      if (doctor.isOnMandatoryRest)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.orange),
                          onPressed: () async {
                            final success = await ApiService.updateDoctor({
                              'id': doctor.id,
                              'is_on_mandatory_rest': false,
                            });
                            
                            if (success) {
                              Navigator.pop(context);
                              _loadData();
                            }
                          },
                          tooltip: 'Clear Rest Status',
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditDoctorDialog(Doctor doctor) {
    final nameController = TextEditingController(text: doctor.name);
    final specialtyController = TextEditingController(text: doctor.specialty);
    List<int> selectedWorkDays = List.from(doctor.workDays);
    TimeOfDay selectedShiftStart = doctor.shiftStart;
    TimeOfDay selectedShiftEnd = doctor.shiftEnd;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Doctor Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: specialtyController,
                  decoration: const InputDecoration(
                    labelText: 'Specialty',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Work Days:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  children: [
                    for (int day = 1; day <= 7; day++)
                      FilterChip(
                        label: Text(_getDayName(day)),
                        selected: selectedWorkDays.contains(day),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedWorkDays.add(day);
                            } else {
                              selectedWorkDays.remove(day);
                            }
                            selectedWorkDays.sort();
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Shift Start'),
                        subtitle: Text(selectedShiftStart.format(context)),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedShiftStart,
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedShiftStart = time;
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('Shift End'),
                        subtitle: Text(selectedShiftEnd.format(context)),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedShiftEnd,
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedShiftEnd = time;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || specialtyController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                if (selectedWorkDays.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one work day')),
                  );
                  return;
                }

                final success = await ApiService.updateDoctor({
                  'id': doctor.id,
                  'name': nameController.text.trim(),
                  'specialty': specialtyController.text.trim(),
                  'work_days': selectedWorkDays,
                  'shift_start': '${selectedShiftStart.hour.toString().padLeft(2, '0')}:${selectedShiftStart.minute.toString().padLeft(2, '0')}:00',
                  'shift_end': '${selectedShiftEnd.hour.toString().padLeft(2, '0')}:${selectedShiftEnd.minute.toString().padLeft(2, '0')}:00',
                });

                if (success) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Doctor information updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update doctor information'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      )

    );
  }

  void _showAvailabilityCalendar(Doctor doctor) {
    DateTime currentMonth = DateTime.now();
    List<DateTime> selectedLeaveDays = List.from(doctor.leaveDays);
    List<DateTime> selectedOffDays = List.from(doctor.offDays);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${doctor.name} - Monthly Availability'),
          content: SizedBox(
            width: 400,
            height: 500,
            child: Column(
              children: [
                // Month navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setDialogState(() {
                          currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
                        });
                      },
                    ),
                    Text(
                      '${_getMonthName(currentMonth.month)} ${currentMonth.year}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setDialogState(() {
                          currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem(Colors.red, 'Leave'),
                    _buildLegendItem(Colors.orange, 'Off Day'),
                    _buildLegendItem(Colors.green, 'Available'),
                  ],
                ),
                const SizedBox(height: 16),
                // Calendar
                Expanded(
                  child: _buildCalendarGrid(
                    currentMonth, 
                    selectedLeaveDays, 
                    selectedOffDays, 
                    doctor.workDays,
                    setDialogState,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await ApiService.updateDoctor({
                  'id': doctor.id,
                  'leave_days': selectedLeaveDays.map((d) => d.toIso8601String().split('T')[0]).toList(),
                  'off_days': selectedOffDays.map((d) => d.toIso8601String().split('T')[0]).toList(),
                });

                if (success) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Availability updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update availability'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildCalendarGrid(
    DateTime month,
    List<DateTime> leaveDays,
    List<DateTime> offDays,
    List<int> workDays,
    StateSetter setDialogState,
  ) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final startDate = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final date = startDate.add(Duration(days: index));
        final isCurrentMonth = date.month == month.month;
        final isWorkDay = workDays.contains(date.weekday);
        final isLeave = leaveDays.any((d) => d.day == date.day && d.month == date.month && d.year == date.year);
        final isOffDay = offDays.any((d) => d.day == date.day && d.month == date.month && d.year == date.year);
        
        Color backgroundColor = Colors.grey[300]!;
        if (isCurrentMonth && isWorkDay) {
          if (isLeave) {
            backgroundColor = Colors.red[300]!;
          } else if (isOffDay) {
            backgroundColor = Colors.orange[300]!;
          } else {
            backgroundColor = Colors.green[300]!;
          }
        }

        return GestureDetector(
          onTap: isCurrentMonth && isWorkDay ? () {
            setDialogState(() {
              if (isLeave) {
                leaveDays.removeWhere((d) => d.day == date.day && d.month == date.month && d.year == date.year);
              } else if (isOffDay) {
                offDays.removeWhere((d) => d.day == date.day && d.month == date.month && d.year == date.year);
                leaveDays.add(date);
              } else {
                offDays.add(date);
              }
            });
          } : null,
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: isCurrentMonth ? Colors.black : Colors.grey,
                  fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  void _showScheduleReport() async {
    setState(() {
      isLoading = true;
    });

    try {
      final allSchedules = await ApiService.getAllSchedules();
      
      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.calendar_view_week, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Generated Schedules'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: allSchedules.isEmpty 
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No schedules generated yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Generate schedules to view them here',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Summary stats
                      Card(
                        color: Colors.green[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Total Schedules', 
                                allSchedules.length.toString(),
                                Icons.assignment,
                                Colors.green,
                              ),
                              _buildStatItem(
                                'Active Doctors', 
                                allSchedules.map((s) => s.doctor.id).toSet().length.toString(),
                                Icons.people,
                                Colors.blue,
                              ),
                              _buildStatItem(
                                'This Month', 
                                allSchedules.where((s) => 
                                  s.date.month == DateTime.now().month && 
                                  s.date.year == DateTime.now().year
                                ).length.toString(),
                                Icons.today,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Header row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Date & Doctor',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Hours',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Time Range',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Schedule list
                      Expanded(
                        child: ListView.builder(
                          itemCount: allSchedules.length,
                          itemBuilder: (context, index) {
                            final schedule = allSchedules[index];
                            final isWeekendHoliday = _isWeekendOrHoliday(schedule.date);
                            final hours = _calculateHours(schedule.startTime, schedule.endTime, isWeekendHoliday);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Date and Doctor info
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatDate(schedule.date),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            schedule.doctor.name,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            schedule.doctor.specialty,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Hours
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isWeekendHoliday 
                                                ? Colors.orange.withOpacity(0.2) 
                                                : Colors.blue.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            '$hours hrs',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isWeekendHoliday 
                                                  ? Colors.orange[800] 
                                                  : Colors.blue[800],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Time Range
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Text(
                                              schedule.startTime.format(context),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              'to',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              schedule.endTime.format(context),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading schedules: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int _calculateHours(TimeOfDay startTime, TimeOfDay endTime, bool isWeekendHoliday) {
    if (isWeekendHoliday) {
      return 24; // Weekend/Holiday is always 24 hours
    } else {
      return 16; // Weekday is always 16 hours
    }
  }

  String _getDayName(int day) {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day];
  }



}