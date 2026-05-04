import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/home_screen.dart'; // Sesuaikan path ini dengan lokasi home_screen Anda
import '../home/profile_screen.dart'; // Sesuaikan path ini dengan lokasi profile_screen Anda

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // --- MOCK DATA KALENDER ---
  // isSelected: penanda hari yang sedang diklik
  // dots: status obat. true = hijau (diminum), false = merah (terlewat)
  // Kalau array-nya kosong [], berarti belum ada jadwal/belum lewat harinya
  final List<Map<String, dynamic>> _calendarDays = [
    {'day': '23', 'dayName': 'SUN', 'dots': [true, true], 'isSelected': false},
    {'day': '24', 'dayName': 'MON', 'dots': [false, true], 'isSelected': false},
    {'day': '25', 'dayName': 'TUE', 'dots': [true, true], 'isSelected': false},
    {'day': '26', 'dayName': 'WED', 'dots': [true, true], 'isSelected': false},
    {'day': '27', 'dayName': 'THU', 'dots': [true, true], 'isSelected': false},
    {'day': '28', 'dayName': 'FRI', 'dots': [false, true], 'isSelected': false},
    {'day': '29', 'dayName': 'SAT', 'dots': [true, true], 'isSelected': false},
    {'day': '30', 'dayName': 'SUN', 'dots': [true, true], 'isSelected': true}, // Hari ini
    {'day': '31', 'dayName': 'MON', 'dots': [], 'isSelected': false},
    {'day': '1', 'dayName': 'TUE', 'dots': [], 'isSelected': false},
    {'day': '2', 'dayName': 'WED', 'dots': [], 'isSelected': false},
  ];

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
                const SizedBox(height: 60), // Margin atas (Status Bar)

                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kalender', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: const Icon(Icons.add, size: 20, color: Color(0xFF1E293B)),
                      )
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
                  child: Text('Hari Ini', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),

                // Obat 1
                _buildMedicationTimeline(
                  timeStart: '09.00', timeEnd: '10.00',
                  medName: 'Rifampicin', dosage: 'Dosis 2 pill',
                  iconColor: const Color(0xFFE2C8A0),
                ),

                // Garis Indikator Waktu Sekarang (Garis Biru Horizontal)
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF5B92F5), shape: BoxShape.circle)),
                      Expanded(child: Container(height: 2, color: const Color(0xFF5B92F5))),
                    ],
                  ),
                ),

                // Obat 2
                _buildMedicationTimeline(
                  timeStart: '07.00', timeEnd: '08.00',
                  medName: 'Pyrazinamide', dosage: 'Dosis Kapsul',
                  iconColor: const Color(0xFFA5C4F7),
                ),
              ],
            ),
          ),

          // BOTTOM NAVIGATION BAR KHUSUS HISTORY
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24, left: 30, right: 30),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF9),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Tombol Home (Kembali ke Beranda)
                  IconButton(
                    icon: const Icon(Icons.home_outlined, color: Colors.black54),
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                    },
                  ),

                  // Tombol History (Aktif)
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
                  // Tombol Profile
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

  // --- WIDGET KALENDER UTAMA ---
  Widget _buildCalendarWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Navigasi Bulan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.chevron_left, color: Color(0xFF1E293B)),
                Text('Februari', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                const Icon(Icons.chevron_right, color: Color(0xFF1E293B)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nama Hari (SUN, MON, TUE...)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((day) {
                return SizedBox(
                  width: 35,
                  child: Text(day, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // List Tanggal Horizontal
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _calendarDays.length,
              itemBuilder: (context, index) {
                var dayData = _calendarDays[index];
                bool isSelected = dayData['isSelected'];
                List<bool> dots = dayData['dots'];

                return Container(
                  width: 45,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF5B92F5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayData['day'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Indikator Titik (Merah / Hijau)
                      if (dots.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dots.map((isSuccess) {
                            Color dotColor;
                            if (isSelected) {
                              dotColor = Colors.white; // Jika kotak biru, titiknya warna putih
                            } else {
                              dotColor = isSuccess ? Colors.green : Colors.redAccent; // Titik normal
                            }
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              width: 4, height: 4,
                              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                            );
                          }).toList(),
                        )
                      else
                        const SizedBox(height: 4), // Placeholder jika tidak ada jadwal
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET CARD OBAT & TIMELINE ---
  Widget _buildMedicationTimeline({required String timeStart, required String timeEnd, required String medName, required String dosage, required Color iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Agar kotak berada di tengah antara 2 jam
        children: [
          // Kolom Waktu
          SizedBox(
            width: 50,
            height: 80, // Tinggi disejajarkan dengan card
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 10.00 di atas, 09.00 di bawah
              children: [
                Text(timeEnd, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                Text(timeStart, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Card Obat
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
                  // Garis biru di sisi kiri card
                  Container(width: 3, height: double.infinity, decoration: BoxDecoration(color: const Color(0xFF5B92F5), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 16),
                  // Icon Lingkaran Pil
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.3), shape: BoxShape.circle),
                    child: Icon(Icons.medication, color: iconColor), // Bisa diganti image.asset nanti
                  ),
                  const SizedBox(width: 16),
                  // Teks Nama & Dosis
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(medName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(dosage, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}