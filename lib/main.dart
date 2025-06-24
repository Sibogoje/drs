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
  static const String baseUrl = 'https://grinpath.com/rds/api';
  
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor On-Call Scheduler'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date Selector
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showDoctorList(context),
                          child: const Text('Manage Doctors'),
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
      return const Center(
        child: Text(
          'No schedules for this date.\nTap "Generate Schedule" to create one.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(schedule.doctor.name.substring(0, 2)),
            ),
            title: Text(schedule.doctor.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schedule.doctor.specialty),
                Text(
                  'On-Call: ${schedule.startTime.format(context)} - ${schedule.endTime.format(context)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadSchedulesForDate();
    }
  }

  Future<void> _loadSchedulesForDate() async {
    try {
      final schedulesData = await ApiService.getSchedules(
        date: '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'
      );
      
      setState(() {
        schedules = schedulesData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading schedules: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateSchedule() async {
    setState(() {
      isLoading = true;
    });

    try {
      final availableDoctors = _getAvailableDoctors(selectedDate);
      
      if (availableDoctors.isNotEmpty) {
        Doctor? selectedDoctor = _selectOnCallDoctor(availableDoctors, selectedDate);
        
        if (selectedDoctor != null) {
          // Create schedule via API
          final scheduleData = {
            'doctor_id': selectedDoctor.id,
            'schedule_date': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
            'start_time': '${selectedDoctor.shiftEnd.hour.toString().padLeft(2, '0')}:${selectedDoctor.shiftEnd.minute.toString().padLeft(2, '0')}:00',
            'end_time': '${selectedDoctor.shiftStart.hour.toString().padLeft(2, '0')}:${selectedDoctor.shiftStart.minute.toString().padLeft(2, '0')}:00',
          };

          final success = await ApiService.createSchedule(scheduleData);
          
          if (success) {
            // Update doctor status
            final doctorUpdateData = {
              'id': selectedDoctor.id,
              'last_on_call_date': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
              'is_on_mandatory_rest': true,
            };
            
            await ApiService.updateDoctor(doctorUpdateData);
            
            // Reload data
            await _loadData();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Schedule created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            throw Exception('Failed to create schedule');
          }
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No available doctors for on-call duty on this date.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating schedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  void _showDoctorList(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Doctor List'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return ListTile(
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
                trailing: doctor.isOnMandatoryRest ? IconButton(
                  icon: const Icon(Icons.clear),
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
                ) : null,
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

  String _getDayName(int day) {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day];
  }
}
