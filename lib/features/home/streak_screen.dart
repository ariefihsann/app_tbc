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

  // INI ADALAH MOCK DATA (Data Tiruan Sementara untuk UI)
  final List<Map<String, dynamic>> _riwayatStreak = [
    {'hari': 'Hari ini', 'tanggal': '04 Mei 2026 - 08.05', 'status': 'Terlewat', 'isSuccess': false},
    {'hari': 'Kemarin', 'tanggal': '03 Mei 2026 - 08.05', 'status': 'Minum Obat', 'isSuccess': true},
    {'hari': '2 Hari lalu', 'tanggal': '02 Mei 2026 - 08.05', 'status': 'Minum Obat', 'isSuccess': true},
  ];

  @override
  void initState() {
    super.initState();
    _fetchStreakData();
  }

  Future<void> _fetchStreakData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final data = await supabase
            .from('profiles')
            .select('current_streak, best_streak, target_streak')
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _currentStreak = data['current_streak'] ?? 0;
            _bestStreak = data['best_streak'] ?? 0;
            _targetStreak = data['target_streak'] ?? 7;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF5B92F5))),
      );
    }

    double progressTarget = _targetStreak > 0 ? (_currentStreak / _targetStreak) : 0.0;
    if (progressTarget > 1.0) progressTarget = 1.0;

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

          // Tombol Lanjutkan Streak
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.white, Colors.white.withValues(alpha: 0.0)],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B92F5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      Text(
                        'Lanjutkan Streak',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderBlue() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 60),
      decoration: const BoxDecoration(
        color: Color(0xFF5B92F5),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
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
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('Streak', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  Text('$_currentStreak Days\nStreak!', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                  const SizedBox(height: 8),
                  Text('Kamu Konsisten\nminum obat 💪', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 20),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Best Streak', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                            Text('$_bestStreak Days', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
              const Icon(Icons.local_fire_department, size: 120, color: Colors.orangeAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTargetStreakCard(double progress) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70, height: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress, strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$_currentStreak/$_targetStreak', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('hari', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                      Text('${(progress * 100).toInt()}%', style: GoogleFonts.poppins(fontSize: 8, color: Colors.grey)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Target Streak', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Mencapai $_targetStreak hari berturut turut\nuntuk rekor baru!', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text('$_currentStreak/$_targetStreak days', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey))],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress, minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B92F5)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // DIUBAH: Menambahkan desain grafik garis (Line Chart)
  Widget _buildProgresMingguan() {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min', 'Hari\nini'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progres Mingguan', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [Text('7 Hari Terakhir', style: GoogleFonts.poppins(fontSize: 10)), const Icon(Icons.keyboard_arrow_down, size: 14)],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),

          // Row untuk "Konsisten" dan Chart Garis Biru
          Row(
            children: [
              Text('Konsisten', style: GoogleFonts.poppins(fontSize: 10, color: Colors.black)),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Garis penghubung di belakang
                    Positioned(
                      left: 10, right: 10,
                      child: Container(height: 2, color: const Color(0xFFA5C4F7)),
                    ),
                    // Lingkaran putih border biru
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(8, (index) {
                        return Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF4A89F3), width: 2),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Row untuk "Terlewat" dan Icon Centang
          Row(
            children: [
              Text('Terlewat  ', style: GoogleFonts.poppins(fontSize: 10, color: Colors.black)),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: days.map((day) {
                    bool isToday = day.contains('Hari');
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(isToday ? Icons.cancel : Icons.check_circle,
                            color: isToday ? Colors.redAccent : Colors.green, size: 16),
                        const SizedBox(height: 4),
                        Text(day, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // DIUBAH: Menambahkan efek Timeline (Garis Vertikal)
  Widget _buildRiwayatStreak() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Riwayat Streak', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _riwayatStreak.length,
            itemBuilder: (context, index) {
              var item = _riwayatStreak[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sisi Kiri: Icon & Garis Vertikal (Timeline)
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item['isSuccess'] ? Colors.green.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                        ),
                        child: Icon(item['isSuccess'] ? Icons.check_circle : Icons.cancel,
                            color: item['isSuccess'] ? Colors.green : Colors.redAccent, size: 24),
                      ),
                      // Garis Vertikal (kecuali item terakhir)
                      if (index != _riwayatStreak.length - 1)
                        Container(width: 2, height: 30, color: Colors.grey.shade300),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Sisi Kanan: Konten Teks
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
                                    Text(item['hari'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text(item['tanggal'], style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: item['isSuccess'] ? Colors.green.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(item['status'], style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: item['isSuccess'] ? Colors.green : Colors.redAccent)),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                          // Garis horizontal pemisah (kecuali item terakhir)
                          if (index != _riwayatStreak.length - 1)
                            const Divider(height: 30, color: Color(0xFFEEEEEE)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }

  // DIUBAH: Menyesuaikan warna card persis dengan Gambar 2
  Widget _buildAchievement() {
    List<Map<String, dynamic>> badges = [
      {'title': '3 Hari', 'sub': 'Getting Started', 'bg': const Color(0xFFE8EEF9), 'fireColor': const Color(0xFFFF7A00), 'icon': Icons.check_circle},
      {'title': '7 Hari', 'sub': 'Consistent', 'bg': const Color(0xFFFFF4E0), 'fireColor': const Color(0xFFFF7A00), 'icon': null},
      {'title': '14 Hari', 'sub': 'On Fire', 'bg': const Color(0xFFE8EEF9), 'fireColor': const Color(0xFFFF7A00), 'icon': null},
      {'title': '30 Hari', 'sub': 'Discipline Master', 'bg': const Color(0xFFE8EEF9), 'fireColor': const Color(0xFFFF7A00), 'icon': null},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Achivement', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Lihat Semua >', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF5B92F5))),
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
                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: badge['bg'],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_fire_department, size: 40, color: badge['fireColor']),
                          const SizedBox(height: 8),
                          Text(badge['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                          Text(badge['sub'], style: GoogleFonts.poppins(fontSize: 8, color: Colors.grey)),
                        ],
                      ),
                      if (badge['icon'] != null)
                        Positioned(
                          bottom: -5,
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(badge['icon'], color: Colors.green, size: 18),
                          ),
                        )
                    ],
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