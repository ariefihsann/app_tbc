import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_tbc/features/home/add_medication_screen.dart';
import 'streak_screen.dart'; // Import halaman Streak
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

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchMedications();
  }

  Future<void> _fetchUserName() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase.from('profiles').select('full_name').eq('id', user.id).single();
        if (mounted) setState(() => _userName = data['full_name']?.split(' ')[0] ?? 'User');
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

      print('🔍 Fetching data for user: ${user.id}');
      final medsData = await supabase.from('medications').select().eq('user_id', user.id);
      print('📊 Meds fetched: ${medsData.length}');
      
      final logsData = await supabase.from('medication_logs').select().eq('user_id', user.id).eq('log_date', todayStr);
      print('📋 Logs fetched: ${logsData.length}');

      List<Map<String, dynamic>> combined = [];

      for (var med in medsData) {
        final logList = (logsData as List).where((l) => l['medication_id'] == med['id']).toList();
        final log = logList.isNotEmpty ? logList.first : null;

      combined.add({
          'id': med['id'],
          'name': med['name'],
          'time': med['schedule_time'].toString().substring(0, 5),
          'isTaken': log != null ? log['is_taken'] : false,
          'takenAt': (log != null && log['taken_at'] != null) ? DateTime.parse(log['taken_at']).toLocal() : null,
          'color': const Color(0xFFA5C4F7),
        });
      }
      
      print('✅ Combined meds to display: ${combined.length}');
      
      if (mounted) {
        setState(() {
          _todayMeds = combined;
          _isLoadingMeds = false;
        });
      }
    } catch (e) {
      print('❌ Fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data obat: $e')),
        );
        setState(() => _isLoadingMeds = false);
      }
    }
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
    } catch (e) {
      _fetchMedications(); // Revert jika gagal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // Mencegah layout rusak saat keyboard tiba-tiba muncul (seperti di screenshot)
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStreakSection(),
                const SizedBox(height: 24),
                _buildMedicationSection(),
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.home_outlined, color: Color(0xFF4A89F3), size: 20),
                        const SizedBox(width: 6),
                        Text('Home', style: GoogleFonts.poppins(color: const Color(0xFF4A89F3), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.history, color: Colors.black54), onPressed: () {
                    // Navigasi ke History Screen tanpa menumpuk layar
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                  },),
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.black54),
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
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
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // <-- Mengubah posisi teks jadi Center
        children: [
          // Baris Notifikasi (Jam dihapus, Icon Notifikasi diletakkan di kanan)
          const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.notifications_none, color: Colors.white),
          ),
          const SizedBox(height: 20),

          // Teks Sapaan yang sudah di-Center
          Text(
            'Hello, $_userName!!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            'Jadwal obat hari ini apa ya??',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 30),

          // Card Highlight
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: const BoxDecoration(color: Color(0xFFA5C4F7), shape: BoxShape.circle),
                  child: const Icon(Icons.medication, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pyrazinamide', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Contoh Highlight', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStreakSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Streak Peats', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // <-- Ditambahkan GestureDetector untuk pindah ke Halaman Streak
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StreakScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Most consistent', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Kamu menyelesaikan\n0 berturut turut', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text('0/180 days', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      value: 0.0, minHeight: 8, backgroundColor: Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A89F3)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationSection() {
    return RefreshIndicator(
      onRefresh: _fetchMedications,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Obat Hari ini', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      )
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _todayMeds.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildMedicationCard(_todayMeds[index]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> med) {
    bool isTaken = med['isTaken'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: med['color']?.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(Icons.medication, color: med['color']),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med['name'], style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('hari ini pukul ${med['time']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleMedication(med),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: isTaken ? const Color(0xFF4A89F3) : Colors.transparent,
                    border: Border.all(color: isTaken ? const Color(0xFF4A89F3) : Colors.grey.shade400, width: 2),
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
                  Text(
                    'Sudah Diminimum pukul ${med['takenAt'].hour.toString().padLeft(2, '0')}:${med['takenAt'].minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF3266B1), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }
}
