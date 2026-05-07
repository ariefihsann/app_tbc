import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_tbc/features/home/add_medication_screen.dart';
import 'package:app_tbc/features/home/notification_screen.dart';
import 'streak_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Loading...';
  List<Map<String, dynamic>> _todayMeds = [];
  bool _isLoadingMeds = true;
  
  // Variabel untuk streak
  int _currentStreak = 0;
  int _targetStreak = 7;
  bool _isLoadingStreak = true;
  
  // Variabel untuk jadwal selanjutnya
  Map<String, dynamic>? _nextMedication;
  bool _isLoadingNext = true;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchMedications();
    _fetchStreakData();
  }

  Future<void> _fetchUserName() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .single();
        if (mounted)
          setState(
            () => _userName = data['full_name']?.split(' ')[0] ?? 'User',
          );
      }
    } catch (e) {
      if (mounted) setState(() => _userName = 'User');
    }
  }

  Future<void> _fetchMedications() async {
    if (!mounted) return;
    setState(() => _isLoadingMeds = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final medsData = await supabase
          .from('medications')
          .select()
          .eq('user_id', user.id);

      final logsData = await supabase
          .from('medication_logs')
          .select()
          .eq('user_id', user.id)
          .eq('log_date', todayStr);

      List<Map<String, dynamic>> combined = [];

      for (var med in medsData) {
        final logList = (logsData as List)
            .where((l) => l['medication_id'] == med['id'])
            .toList();
        final log = logList.isNotEmpty ? logList.first : null;

        combined.add({
          'id': med['id'],
          'name': med['name'],
          'dosage': med['dosage'] ?? '1 pill',
          'time': med['schedule_time'].toString().substring(0, 5),
          'isTaken': log != null ? log['is_taken'] : false,
          'takenAt': (log != null && log['taken_at'] != null)
              ? DateTime.parse(log['taken_at']).toLocal()
              : null,
          'color': const Color(0xFFA5C4F7),
        });
      }

      combined.sort((a, b) => a['time'].compareTo(b['time']));

      if (mounted) {
        setState(() {
          _todayMeds = combined;
          _isLoadingMeds = false;
        });
        _findNextMedication();
      }
    } catch (e) {
      print('❌ Fetch error: $e');
      if (mounted) {
        setState(() => _isLoadingMeds = false);
      }
    }
  }

  void _findNextMedication() {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;
    
    Map<String, dynamic>? nextMed;
    int smallestTimeDiff = 24 * 60;
    
    for (var med in _todayMeds) {
      if (!med['isTaken']) {
        final timeParts = med['time'].split(':');
        final medTime = int.parse(timeParts[0]) * 60 + int.parse(timeParts[1]);
        
        int timeDiff = medTime - currentTime;
        
        if (timeDiff < 0) {
          timeDiff += 24 * 60;
        }
        
        if (timeDiff < smallestTimeDiff) {
          smallestTimeDiff = timeDiff;
          nextMed = med;
        }
      }
    }
    
    setState(() {
      _nextMedication = nextMed;
      _isLoadingNext = false;
    });
  }

  Future<void> _fetchStreakData() async {
    setState(() => _isLoadingStreak = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final streakData = await _calculateStreakFromLogs(user.id);

        setState(() {
          _currentStreak = streakData['current'] ?? 0;
          _isLoadingStreak = false;
        });
      } else {
        setState(() => _isLoadingStreak = false);
      }
    } catch (e) {
      print('Error fetching streak data: $e');
      setState(() => _isLoadingStreak = false);
    }
  }

  Future<Map<String, int>> _calculateStreakFromLogs(String userId) async {
    final supabase = Supabase.instance.client;

    final medsData = await supabase
        .from('medications')
        .select('id')
        .eq('user_id', userId);

    final int totalMedsPerDay = medsData.length;
    if (totalMedsPerDay == 0) return {'current': 0, 'best': 0};

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final startDate = thirtyDaysAgo.toIso8601String().split('T')[0];

    final logsData = await supabase
        .from('medication_logs')
        .select()
        .eq('user_id', userId)
        .gte('log_date', startDate)
        .order('log_date', ascending: false);

    Map<String, List<bool>> logsByDate = {};
    for (var log in logsData) {
      String date = log['log_date'];
      if (!logsByDate.containsKey(date)) {
        logsByDate[date] = [];
      }
      logsByDate[date]!.add(log['is_taken'] == true);
    }

    int currentStreak = 0;
    DateTime today = DateTime.now();

    for (int i = 0; i < 30; i++) {
      DateTime date = today.subtract(Duration(days: i));
      String dateStr = date.toIso8601String().split('T')[0];

      List<bool> statuses = logsByDate[dateStr] ?? [];
      int takenCount = statuses.where((s) => s == true).length;
      bool isComplete = takenCount == totalMedsPerDay && totalMedsPerDay > 0;

      if (isComplete) {
        currentStreak++;
      } else {
        if (i == 0) {
          currentStreak = 0;
        }
        if (i > 0) {
          break;
        }
      }
    }

    return {'current': currentStreak, 'best': 0};
  }

  Future<void> _toggleMedication(Map<String, dynamic> med) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final bool newStatus = !med['isTaken'];

    setState(() {
      med['isTaken'] = newStatus;
      med['takenAt'] = newStatus ? DateTime.now() : null;
    });

    try {
      await supabase.from('medication_logs').upsert({
        'user_id': user.id,
        'medication_id': med['id'],
        'log_date': todayStr,
        'is_taken': newStatus,
        'taken_at': newStatus ? DateTime.now().toUtc().toIso8601String() : null,
      }, onConflict: 'user_id, medication_id, log_date');
      
      await _fetchStreakData();
      _findNextMedication();
    } catch (e) {
      _fetchMedications();
    }
  }

  String _getTimeRemaining(String medTime) {
    final now = DateTime.now();
    final timeParts = medTime.split(':');
    final medDateTime = DateTime(
      now.year, now.month, now.day,
      int.parse(timeParts[0]), int.parse(timeParts[1])
    );
    
    if (medDateTime.isBefore(now)) {
      final tomorrow = now.add(const Duration(days: 1));
      final medTomorrow = DateTime(
        tomorrow.year, tomorrow.month, tomorrow.day,
        int.parse(timeParts[0]), int.parse(timeParts[1])
      );
      final diff = medTomorrow.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours > 0) {
        return '${hours}j ${minutes}m lagi';
      } else {
        return '${minutes}m lagi';
      }
    } else {
      final diff = medDateTime.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours > 0) {
        return '${hours}j ${minutes}m lagi';
      } else if (minutes > 0) {
        return '${minutes}m lagi';
      } else {
        return 'Sekarang!';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildStreakSection(),
                const SizedBox(height: 24),
                _buildMedicationSection(),
                const SizedBox(height: 100),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.home_outlined, color: Color(0xFF4A89F3), size: 20),
                        const SizedBox(width: 6),
                        Text('Home', style: GoogleFonts.poppins(color: const Color(0xFF4A89F3), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.black54),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF5B92F5),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Notifikasi dengan navigasi
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Hello, $_userName!!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Jadwal obat hari ini apa ya??',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 24),

          // Jadwal Obat Selanjutnya
          _buildNextMedicationWidget(),
        ],
      ),
    );
  }

  Widget _buildNextMedicationWidget() {
    if (_isLoadingMeds || _isLoadingNext) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    
    if (_nextMedication == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semua Obat Sudah Diminum!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  Text(
                    'Bagus! Pertahankan streak-mu 💪',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm, color: Colors.orange, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal Obat Selanjutnya',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _nextMedication!['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Pukul ${_nextMedication!['time']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getTimeRemaining(_nextMedication!['time']),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF5B92F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _nextMedication!['time'],
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection() {
    double progress = _targetStreak > 0
        ? (_currentStreak / _targetStreak).clamp(0.0, 1.0)
        : 0.0;

    String streakText = '';
    String streakSubText = '';

    if (_isLoadingStreak) {
      streakText = 'Memuat...';
      streakSubText = 'Mengambil data streak';
    } else if (_currentStreak == 0) {
      streakText = 'Mulai Streak-mu';
      streakSubText = 'Minum obat hari ini untuk memulai streak! 💪';
    } else if (_currentStreak < 3) {
      streakText = '$_currentStreak Days Streak!';
      streakSubText = 'Kamu menyelesaikan $_currentStreak hari berturut-turut';
    } else if (_currentStreak < 7) {
      streakText = '$_currentStreak Days Streak! 🔥';
      streakSubText = 'Bagus! Pertahankan streak-mu!';
    } else if (_currentStreak < 14) {
      streakText = '$_currentStreak Days Streak! 🎉';
      streakSubText = 'Luar biasa! Kamu sangat konsisten!';
    } else {
      streakText = '$_currentStreak Days Streak! 👑';
      streakSubText = 'Hebat! Kamu adalah pejuang sejati!';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Streak', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StreakScreen()),
                  ).then((_) => _fetchStreakData());
                },
                child: Text('Lihat Semua', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF4A89F3))),
              ),
            ],
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StreakScreen()),
              ).then((_) => _fetchStreakData());
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _currentStreak > 0 ? Colors.orange.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_fire_department,
                          color: _currentStreak > 0 ? Colors.deepOrange : Colors.grey,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(streakText, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: _currentStreak > 0 ? Colors.deepOrange : Colors.grey)),
                            const SizedBox(height: 4),
                            Text(streakSubText, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A89F3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('$_currentStreak/$_targetStreak', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4A89F3))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A89F3)),
                    ),
                  ),
                  if (_currentStreak >= _targetStreak) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events, size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Text('Target Tercapai! 🎯', style: GoogleFonts.poppins(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daftar Obat Hari Ini', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (_isLoadingMeds)
            const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
          else if (_todayMeds.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.medical_information_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Anda belum menambah obat', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMedicationScreen()));
                      _fetchMedications();
                    },
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: Text('Tambah Obat', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B92F5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _todayMeds.map((med) => _buildMedicationCard(med)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> med) {
    bool isTaken = med['isTaken'];
    final now = DateTime.now();
    final timeParts = med['time'].split(':');
    final medTime = int.parse(timeParts[0]) * 60 + int.parse(timeParts[1]);
    final currentTime = now.hour * 60 + now.minute;
    bool isPast = medTime < currentTime && !isTaken;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPast ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: isPast ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isTaken ? Colors.green.withOpacity(0.2) : (isPast ? Colors.red.withOpacity(0.2) : med['color']?.withOpacity(0.2)),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.medication, color: isTaken ? Colors.green : (isPast ? Colors.red : med['color'])),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med['name'], style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: isPast ? Colors.red.shade700 : Colors.black87)),
                    Text('Pukul ${med['time']}', style: GoogleFonts.poppins(fontSize: 12, color: isPast ? Colors.red.shade400 : Colors.grey)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleMedication(med),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isTaken ? const Color(0xFF4A89F3) : Colors.transparent,
                    border: Border.all(color: isTaken ? const Color(0xFF4A89F3) : (isPast ? Colors.red : Colors.grey.shade400), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isTaken ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                ),
              ),
            ],
          ),
          if (isTaken && med['takenAt'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFFA5C4F7).withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, size: 16, color: Color(0xFF3266B1)),
                  const SizedBox(width: 8),
                  Text('Diminum pukul ${med['takenAt'].hour.toString().padLeft(2, '0')}:${med['takenAt'].minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF3266B1), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          if (isPast && !isTaken) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Waktu minum telah lewat', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}