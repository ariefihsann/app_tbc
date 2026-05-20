import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  bool _isLoading = true;

  int _currentStreak = 0;
  int _bestStreak = 0;
  int _targetStreak = 7;

  // Data real dari database
  List<Map<String, dynamic>> _riwayatStreak = [];
  List<Map<String, dynamic>> _weeklyProgress = [];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchStreakData(),
      _fetchWeeklyProgress(),
      _fetchStreakHistory(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStreakData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final streakData = await _calculateStreakFromLogs(user.id);
        final int current = streakData['current'] ?? 0;
        final int best = streakData['best'] ?? 0;

        await supabase.from('profiles').upsert({
          'id': user.id,
          'current_streak': current,
          'best_streak': best,
          'target_streak': _targetStreak,
        });

        if (mounted) {
          setState(() {
            _currentStreak = current;
            _bestStreak = best;
          });
        }
      }
    } catch (e) {
      print('Error fetching streak data: $e');
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
    int bestStreak = 0;
    DateTime today = DateTime.now();

    for (int i = 0; i < 30; i++) {
      DateTime date = today.subtract(Duration(days: i));
      String dateStr = date.toIso8601String().split('T')[0];

      List<bool> statuses = logsByDate[dateStr] ?? [];
      int takenCount = statuses.where((s) => s == true).length;
      bool isComplete = takenCount == totalMedsPerDay && totalMedsPerDay > 0;

      if (isComplete) {
        currentStreak++;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      } else {
        if (i == 0) {
          currentStreak = 0;
        }
        if (i > 0) {
          break;
        }
      }
    }

    return {'current': currentStreak, 'best': bestStreak};
  }

  Future<void> _fetchWeeklyProgress() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final medsData = await supabase
          .from('medications')
          .select('id')
          .eq('user_id', user.id);

      final int totalMedsPerDay = medsData.length;
      List<Map<String, dynamic>> weeklyData = [];

      // Cari hari Senin terakhir (atau hari ini jika hari Senin)
      DateTime today = DateTime.now();
      int daysToSubtract = today.weekday == 1 ? 0 : today.weekday - 1;
      DateTime lastMonday = today.subtract(Duration(days: daysToSubtract));

      for (int i = 0; i < 7; i++) {
        DateTime date = lastMonday.add(Duration(days: i));
        String dateStr = date.toIso8601String().split('T')[0];

        final logsData = await supabase
            .from('medication_logs')
            .select()
            .eq('user_id', user.id)
            .eq('log_date', dateStr);

        int takenCount = 0;
        for (var log in logsData) {
          if (log['is_taken'] == true) takenCount++;
        }

        bool isComplete = totalMedsPerDay > 0 && takenCount == totalMedsPerDay;

        weeklyData.add({
          'date': date,
          'day': _getDayName(date.weekday),
          'isComplete': isComplete,
          'takenCount': takenCount,
          'totalCount': totalMedsPerDay,
        });
      }

      if (mounted) {
        setState(() {
          _weeklyProgress = weeklyData;
        });
      }
    } catch (e) {
      print('Error fetching weekly progress: $e');
    }
  }

  Future<void> _fetchStreakHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final medsData = await supabase
          .from('medications')
          .select('id')
          .eq('user_id', user.id);

      final int totalMedsPerDay = medsData.length;
      if (totalMedsPerDay == 0) {
        if (mounted) setState(() => _riwayatStreak = []);
        return;
      }

      List<Map<String, dynamic>> history = [];

      for (int i = 0; i < 14; i++) {
        DateTime date = DateTime.now().subtract(Duration(days: i));
        String dateStr = date.toIso8601String().split('T')[0];

        final logsData = await supabase
            .from('medication_logs')
            .select()
            .eq('user_id', user.id)
            .eq('log_date', dateStr);

        int takenCount = 0;
        for (var log in logsData) {
          if (log['is_taken'] == true) takenCount++;
        }

        bool isComplete = totalMedsPerDay > 0 && takenCount == totalMedsPerDay;

        String hariLabel = i == 0
            ? 'Hari ini'
            : (i == 1 ? 'Kemarin' : '$i Hari lalu');
        String statusText = isComplete
            ? 'Minum Obat'
            : (takenCount > 0 ? 'Sebagian' : 'Terlewat');
        Color statusColor = isComplete
            ? Colors.green
            : (takenCount > 0 ? Colors.orange : Colors.redAccent);

        history.add({
          'hari': hariLabel,
          'tanggal': _formatDateWithTime(date, logsData),
          'status': statusText,
          'isSuccess': isComplete,
          'statusColor': statusColor,
          'takenCount': takenCount,
          'totalCount': totalMedsPerDay,
        });
      }

      if (mounted) {
        setState(() {
          _riwayatStreak = history;
        });
      }
    } catch (e) {
      print('Error fetching streak history: $e');
    }
  }

  String _getDayName(int weekday) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[weekday - 1];
  }

  String _formatDateWithTime(DateTime date, List logsData) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    String timeStr = '';
    for (var log in logsData) {
      if (log['taken_at'] != null && log['is_taken'] == true) {
        DateTime takenAt = DateTime.parse(log['taken_at']).toLocal();
        timeStr =
            ' - ${takenAt.hour.toString().padLeft(2, '0')}.${takenAt.minute.toString().padLeft(2, '0')}';
        break;
      }
    }

    return '${date.day} ${months[date.month - 1]} ${date.year}$timeStr';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5B92F5)),
        ),
      );
    }

    double progressTarget = _targetStreak > 0
        ? (_currentStreak / _targetStreak).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                _buildHeaderBlue(),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Column(
                    children: [
                      _buildTargetStreakCard(progressTarget),
                      const SizedBox(height: 16),
                      _buildProgresMingguan(),
                      const SizedBox(height: 16),
                      _buildRiwayatStreak(),
                      const SizedBox(height: 16),
                      _buildAchievement(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.white, Colors.white.withOpacity(0.0)],
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              _fetchAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data streak diperbarui'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B92F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Refresh Streak',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBlue() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 60),
      decoration: const BoxDecoration(
        color: Color(0xFF5B92F5),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Streak',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_currentStreak Days\nStreak!',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kamu Konsisten\nminum obat 💪',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBestStreakCard(),
                ],
              ),
              const Icon(
                Icons.local_fire_department,
                size: 120,
                color: Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBestStreakCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.deepOrange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Best Streak',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              ),
              Text(
                '$_bestStreak Days',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetStreakCard(double progress) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildProgressCircle(progress),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Streak',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Mencapai $_targetStreak hari berturut turut\nuntuk rekor baru!',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$_currentStreak/$_targetStreak days',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF5B92F5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(double progress) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_currentStreak/$_targetStreak',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'hari',
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.poppins(fontSize: 8, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgresMingguan() {
    if (_weeklyProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Progres Mingguan', '7 Hari Terakhir'),
          const SizedBox(height: 24),
          _buildKonsistenRow(),
          const SizedBox(height: 24),
          _buildTerlewatRow(),
          const SizedBox(height: 16),
          _buildDayNamesRow(),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFEEEEEE), height: 1),
          const SizedBox(height: 16),
          ..._buildHistoryPreview(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(subtitle, style: GoogleFonts.poppins(fontSize: 10)),
              const Icon(Icons.keyboard_arrow_down, size: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKonsistenRow() {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            'Konsisten',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Hapus const di sini
              Positioned(
                left: 10,
                right: 10,
                child: Container(
                  height: 2,
                  color: const Color(0xFFA5C4F7), // Gunakan const untuk Color
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _weeklyProgress.map((day) {
                  bool isComplete = day['isComplete'];
                  double percentage = day['totalCount'] > 0
                      ? (day['takenCount'] / day['totalCount'])
                      : 0;

                  Color borderColor = isComplete
                      ? Colors.green
                      : (percentage > 0
                            ? Colors.orange
                            : const Color(0xFF4A89F3));

                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTerlewatRow() {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            'Terlewat',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weeklyProgress.map((day) {
              bool isComplete = day['isComplete'];
              double percentage = day['totalCount'] > 0
                  ? (day['takenCount'] / day['totalCount'])
                  : 0;

              return SizedBox(
                width: 24,
                child: Icon(
                  isComplete
                      ? Icons.check_circle
                      : (percentage > 0 ? Icons.warning_amber : Icons.cancel),
                  color: isComplete
                      ? Colors.green
                      : (percentage > 0 ? Colors.orange : Colors.redAccent),
                  size: 18,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayNamesRow() {
    return Row(
      children: [
        const SizedBox(width: 78),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weeklyProgress.map((day) {
              return Text(
                day['day'],
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildHistoryPreview() {
    return _riwayatStreak.take(3).map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Icon(
              item['isSuccess']
                  ? Icons.check_circle
                  : (item['takenCount'] > 0
                        ? Icons.warning_amber
                        : Icons.cancel),
              color: item['statusColor'],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['hari'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item['tanggal'],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: item['statusColor'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item['status'],
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: item['statusColor'],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRiwayatStreak() {
    if (_riwayatStreak.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            'Belum ada riwayat minum obat',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Streak',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _riwayatStreak.length,
            itemBuilder: (context, index) {
              var item = _riwayatStreak[index];
              return _buildHistoryItem(item, index, _riwayatStreak.length);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    Map<String, dynamic> item,
    int index,
    int totalLength,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item['isSuccess']
                    ? Colors.green.withOpacity(0.1)
                    : item['statusColor'].withOpacity(0.1),
              ),
              child: Icon(
                item['isSuccess']
                    ? Icons.check_circle
                    : (item['takenCount'] > 0
                          ? Icons.warning_amber
                          : Icons.cancel),
                color: item['statusColor'],
                size: 24,
              ),
            ),
            if (index != totalLength - 1)
              Container(width: 2, height: 30, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['hari'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            item['tanggal'],
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item['statusColor'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item['status'],
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: item['statusColor'],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
                if (index != _riwayatStreak.length - 1)
                  const Divider(height: 30, color: Color(0xFFEEEEEE)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievement() {
    List<Map<String, dynamic>> badges = [
      {
        'title': '3 Hari',
        'sub': 'Getting Started',
        'bg': const Color(0xFFE8EEF9),
        'fireColor': const Color(0xFFFF7A00),
        'icon': _currentStreak >= 3 ? Icons.check_circle : null,
      },
      {
        'title': '7 Hari',
        'sub': 'Consistent',
        'bg': const Color(0xFFFFF4E0),
        'fireColor': const Color(0xFFFF7A00),
        'icon': _currentStreak >= 7 ? Icons.check_circle : null,
      },
      {
        'title': '14 Hari',
        'sub': 'On Fire',
        'bg': const Color(0xFFE8EEF9),
        'fireColor': const Color(0xFFFF7A00),
        'icon': _currentStreak >= 14 ? Icons.check_circle : null,
      },
      {
        'title': '30 Hari',
        'sub': 'Discipline Master',
        'bg': const Color(0xFFE8EEF9),
        'fireColor': const Color(0xFFFF7A00),
        'icon': _currentStreak >= 30 ? Icons.check_circle : null,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievement',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: badges.length,
              itemBuilder: (context, index) {
                var badge = badges[index];
                bool isUnlocked = badge['icon'] != null;
                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: badge['bg'],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Opacity(
                    opacity: isUnlocked ? 1.0 : 0.5,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 40,
                              color: badge['fireColor'],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              badge['title'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              badge['sub'],
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        if (isUnlocked)
                          Positioned(
                            bottom: -5,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                badge['icon'],
                                color: Colors.green,
                                size: 18,
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
