import 'package:app_tbc/features/obat/screens/add_obat_screen.dart';
import 'package:app_tbc/features/obat/screens/detail_obat_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_screen.dart';
import '../home/profile_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Data dari database
  List<Map<String, dynamic>> _todayMedications = [];
  List<Map<String, dynamic>> _calendarDays = [];

  // State variables
  bool _isLoading = true;
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  // Cache untuk logs per tanggal
  Map<String, List<bool>> _logsCache = {};

  // Colors for medication icons
  final List<Color> _medColors = [
    const Color(0xFFE2C8A0),
    const Color(0xFFA5C4F7),
    const Color(0xFFC8E6C9),
    const Color(0xFFFFCCBC),
    const Color(0xFFE1BEE7),
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchMedicationsForDate(_selectedDate),
      _fetchCalendarData(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchMedicationsForDate(DateTime date) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final dateStr = date.toIso8601String().split('T')[0];

      final medsData = await supabase
          .from('medications')
          .select()
          .eq('user_id', user.id);

      final logsData = await supabase
          .from('medication_logs')
          .select()
          .eq('user_id', user.id)
          .eq('log_date', dateStr);

      List<Map<String, dynamic>> combined = [];

      for (var med in medsData) {
        final logList = (logsData as List)
            .where((l) => l['medication_id'] == med['id'])
            .toList();
        final log = logList.isNotEmpty ? logList.first : null;

        String scheduleTimes =
            med['schedule_times'] ?? med['schedule_time'] ?? '08:00:00';
        List<String> times = scheduleTimes.split(',');

        String timeStart = _formatTimeForDisplay(times.first);
        String timeEnd = times.length > 1
            ? _formatTimeForDisplay(times.last)
            : timeStart;

        // --- PERBAIKAN DI SINI ---
        // Menggunakan ...med untuk menyalin SELURUH kolom dari database
        combined.add({
          ...med,
          'timeStart': timeStart,
          'timeEnd': timeEnd,
          'isTaken': log != null ? log['is_taken'] : false,
          'takenAt': (log != null && log['taken_at'] != null)
              ? DateTime.parse(log['taken_at']).toLocal()
              : null,
          'iconColor': _getColorForMed(med['name'] ?? ''),
        });
      }

      combined.sort((a, b) {
        String timeA =
            a['schedule_times']?.toString().split(',').first ??
                a['schedule_time'] ??
                '00:00';
        String timeB =
            b['schedule_times']?.toString().split(',').first ??
                b['schedule_time'] ??
                '00:00';
        return timeA.compareTo(timeB);
      });

      if (mounted) {
        setState(() {
          _todayMedications = combined;
        });
      }
    } catch (e) {
      print('Error fetching medications: $e');
    }
  }

  Future<void> _fetchCalendarData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Get first and last day of current month
      final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

      final firstDayStr = firstDay.toIso8601String().split('T')[0];
      final lastDayStr = lastDay.toIso8601String().split('T')[0];

      final logsData = await supabase
          .from('medication_logs')
          .select()
          .eq('user_id', user.id)
          .gte('log_date', firstDayStr)
          .lte('log_date', lastDayStr);

      final medsData = await supabase
          .from('medications')
          .select('id')
          .eq('user_id', user.id);

      final int totalMedsPerDay = medsData.length;

      _logsCache = {};
      for (var log in logsData) {
        String date = log['log_date'];
        if (!_logsCache.containsKey(date)) {
          _logsCache[date] = [];
        }
        bool isTaken = log['is_taken'] == true;
        _logsCache[date]!.add(isTaken);
      }

      // Generate calendar days - dengan urutan Senin pertama
      List<Map<String, dynamic>> days = [];

      // Hitung berapa hari kosong di awal bulan (Senin = 1)
      // DateTime.weekday: 1 = Senin, 7 = Minggu
      int startWeekday = firstDay.weekday - 1; // 0 = Senin, 6 = Minggu

      // Add empty days for alignment
      for (int i = 0; i < startWeekday; i++) {
        days.add({'day': '', 'isSelected': false, 'date': null});
      }

      // Add actual days
      for (int day = 1; day <= lastDay.day; day++) {
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);

        final isSelected =
            _selectedDate.year == date.year &&
                _selectedDate.month == date.month &&
                _selectedDate.day == date.day;

        days.add({
          'day': day.toString(),
          'isSelected': isSelected,
          'date': date,
        });
      }

      if (mounted) {
        setState(() {
          _calendarDays = days;
        });
      }
    } catch (e) {
      print('Error fetching calendar: $e');
      if (mounted) {
        setState(() {
          _calendarDays = [];
        });
      }
    }
  }

  Future<List<bool>> _getStatusForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];

    if (_logsCache.containsKey(dateStr)) {
      return _logsCache[dateStr]!;
    }

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final medsData = await supabase
          .from('medications')
          .select('id')
          .eq('user_id', user.id);

      final logsData = await supabase
          .from('medication_logs')
          .select()
          .eq('user_id', user.id)
          .eq('log_date', dateStr);

      List<bool> statuses = [];
      for (var med in medsData) {
        final log = (logsData as List).firstWhere(
              (l) => l['medication_id'] == med['id'],
          orElse: () => null,
        );
        statuses.add(log != null ? log['is_taken'] : false);
      }

      _logsCache[dateStr] = statuses;
      return statuses;
    } catch (e) {
      print('Error fetching status for date: $e');
      return [];
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return months[month - 1];
  }

  String _formatTimeForDisplay(String timeStr) {
    if (timeStr.isEmpty) return '--:--';
    final parts = timeStr.split(':');
    if (parts.length < 2) return timeStr;
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    return '${hour.toString().padLeft(2, '0')}.$minute';
  }

  Color _getColorForMed(String medName) {
    int hash = 0;
    for (int i = 0; i < medName.length; i++) {
      hash = (hash + medName.codeUnitAt(i)) % _medColors.length;
    }
    return _medColors[hash];
  }

  Future<void> _previousMonth() async {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    await _fetchCalendarData();
    await _fetchMedicationsForDate(_selectedDate);
  }

  Future<void> _nextMonth() async {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    await _fetchCalendarData();
    await _fetchMedicationsForDate(_selectedDate);
  }

  Future<void> _selectDate(DateTime date) async {
    if (date == _selectedDate) return;
    setState(() {
      _selectedDate = date;
    });
    await _fetchMedicationsForDate(date);
    await _fetchCalendarData();
  }

  void _navigateToDetail(Map<String, dynamic> medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailObatScreen(
          medication: medication,
          selectedDate: _selectedDate,
        ),
      ),
    ).then((result) {
      _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kalender',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddObatScreen(),
                            ),
                          );
                          if (result == true) {
                            _fetchData();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 20,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // WIDGET KALENDER
                _buildCalendarWidget(),
                const SizedBox(height: 32),

                // TIMELINE HARI INI
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getFormattedDate(_selectedDate),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FutureBuilder<List<bool>>(
                        future: _getStatusForDate(_selectedDate),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final statuses = snapshot.data!;
                          int takenCount = statuses.where((s) => s == true).length;
                          int totalCount = statuses.length;

                          if (takenCount == totalCount && totalCount > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 12, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text('Lengkap', style: GoogleFonts.poppins(fontSize: 10, color: Colors.green)),
                                ],
                              ),
                            );
                          } else if (takenCount > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber, size: 12, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text('$takenCount/$totalCount', style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange)),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Daftar Obat
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_todayMedications.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.medication, size: 50, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Tidak ada jadwal obat', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  )
                else
                  ..._todayMedications.map(
                        (med) => _buildMedicationTimeline(
                      timeStart: med['timeStart'],
                      timeEnd: med['timeEnd'],
                      medName: med['name'],
                      dosage: med['dosage'],
                      iconColor: med['iconColor'],
                      medicationData: med,
                      onTap: () => _navigateToDetail(med),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),

          // BOTTOM NAVIGATION BAR
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24, left: 30, right: 30),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF9),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home_outlined, color: Colors.black54),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: Color(0xFF4A89F3), size: 20),
                        const SizedBox(width: 6),
                        Text('History', style: GoogleFonts.poppins(color: const Color(0xFF4A89F3), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.black54),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildCalendarWidget() {
    if (_isLoading && _calendarDays.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Nama hari dimulai dari Senin
    const weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Navigasi Bulan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _previousMonth,
                  child: const Icon(Icons.chevron_left, color: Color(0xFF1E293B)),
                ),
                Text(
                  '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                GestureDetector(
                  onTap: _nextMonth,
                  child: const Icon(Icons.chevron_right, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nama Hari (Senin - Minggu)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDays.map((day) {
                return SizedBox(
                  width: 40,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Grid Tanggal (7 kolom)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: _calendarDays.length,
            itemBuilder: (context, index) {
              var dayData = _calendarDays[index];
              if (dayData['day'] == '') {
                return Container();
              }

              bool isSelected = dayData['isSelected'];
              DateTime date = dayData['date'];
              int dayNumber = int.parse(dayData['day']);

              return GestureDetector(
                onTap: () => _selectDate(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF5B92F5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayData['day'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Status dot untuk tanggal yang dipilih
                      if (isSelected)
                        FutureBuilder<List<bool>>(
                          future: _getStatusForDate(date),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const SizedBox(height: 4);
                            }
                            final statuses = snapshot.data!;
                            int takenCount = statuses.where((s) => s == true).length;
                            int totalCount = statuses.length;

                            if (takenCount == totalCount && totalCount > 0) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              );
                            } else if (takenCount > 0) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              );
                            } else {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }
                          },
                        )
                      else
                        const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGET CARD OBAT & TIMELINE dengan onTap ---
  Widget _buildMedicationTimeline({
    required String timeStart,
    required String timeEnd,
    required String medName,
    required String dosage,
    required Color iconColor,
    required Map<String, dynamic> medicationData,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(timeEnd, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  Text(timeStart, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 80,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: medicationData['isTaken'] == true ? Colors.green : const Color(0xFF5B92F5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.medication, color: iconColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(medName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(dosage, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (medicationData['isTaken'] == true)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}