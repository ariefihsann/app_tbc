import 'package:app_tbc/features/obat/screens/add_obat_screen.dart';
import 'package:app_tbc/features/obat/screens/detail_obat_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/home_screen.dart';
import '../home/profile_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // --- DATA OBAT UNTUK DITAMPILKAN ---
  final List<Map<String, dynamic>> _todayMedications = [
    {
      'id': '1',
      'name': 'Rifampicin',
      'dosage': 'Dosis 2 pill',
      'timeStart': '09.00',
      'timeEnd': '10.00',
      'iconColor': const Color(0xFFE2C8A0),
      'schedule_time': '09:00:00',
      'notes': 'Diminum sebelum makan',
      'isTaken': false,
    },
    {
      'id': '2',
      'name': 'Pyrazinamide',
      'dosage': 'Dosis Kapsul',
      'timeStart': '07.00',
      'timeEnd': '08.00',
      'iconColor': const Color(0xFFA5C4F7),
      'schedule_time': '07:00:00',
      'notes': 'Diminum sesudah makan',
      'isTaken': true,
    },
  ];

  // --- MOCK DATA KALENDER ---
  final List<Map<String, dynamic>> _calendarDays = [
    {'day': '23', 'dayName': 'SUN', 'dots': [true, true], 'isSelected': false, 'date': DateTime(2024, 2, 23)},
    {'day': '24', 'dayName': 'MON', 'dots': [false, true], 'isSelected': false, 'date': DateTime(2024, 2, 24)},
    {'day': '25', 'dayName': 'TUE', 'dots': [true, true], 'isSelected': false, 'date': DateTime(2024, 2, 25)},
    {'day': '26', 'dayName': 'WED', 'dots': [true, true], 'isSelected': false, 'date': DateTime(2024, 2, 26)},
    {'day': '27', 'dayName': 'THU', 'dots': [true, true], 'isSelected': false, 'date': DateTime(2024, 2, 27)},
    {'day': '28', 'dayName': 'FRI', 'dots': [false, true], 'isSelected': false, 'date': DateTime(2024, 2, 28)},
    {'day': '29', 'dayName': 'SAT', 'dots': [true, true], 'isSelected': false, 'date': DateTime(2024, 2, 29)},
    {'day': '30', 'dayName': 'SUN', 'dots': [true, true], 'isSelected': true, 'date': DateTime(2024, 2, 30)},
    {'day': '31', 'dayName': 'MON', 'dots': [], 'isSelected': false, 'date': DateTime(2024, 2, 31)},
    {'day': '1', 'dayName': 'TUE', 'dots': [], 'isSelected': false, 'date': DateTime(2024, 3, 1)},
    {'day': '2', 'dayName': 'WED', 'dots': [], 'isSelected': false, 'date': DateTime(2024, 3, 2)},
  ];

  // Fungsi untuk navigasi ke detail obat
  void _navigateToDetail(Map<String, dynamic> medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailObatScreen(
          medication: medication,
          selectedDate: DateTime.now(),
        ),
      ),
    ).then((result) {
      // Jika ada perubahan (edit/hapus), refresh data di sini
      if (result == true) {
        setState(() {
          // Refresh data jika perlu
        });
      }
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
                      Text('Kalender', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddObatScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: const Icon(Icons.add, size: 20, color: Color(0xFF1E293B)),
                        ),
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

                // Daftar Obat - Menggunakan loop agar bisa diklik
                ..._todayMedications.map((med) => _buildMedicationTimeline(
                  timeStart: med['timeStart'],
                  timeEnd: med['timeEnd'],
                  medName: med['name'],
                  dosage: med['dosage'],
                  iconColor: med['iconColor'],
                  medicationData: med,
                  onTap: () => _navigateToDetail(med),
                )),

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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home_outlined, color: Colors.black54),
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
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

  Widget _buildCalendarWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
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
                      if (dots.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dots.map((isSuccess) {
                            Color dotColor;
                            if (isSelected) {
                              dotColor = Colors.white;
                            } else {
                              dotColor = isSuccess ? Colors.green : Colors.redAccent;
                            }
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              width: 4, height: 4,
                              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                            );
                          }).toList(),
                        )
                      else
                        const SizedBox(height: 4),
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
            // Kolom Waktu
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
                    // Garis status di sisi kiri (hijau jika sudah diminum)
                    Container(
                      width: 3,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: medicationData['isTaken'] == true ? Colors.green : const Color(0xFF5B92F5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Icon Lingkaran Pil
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
                    ),
                    // Icon indicator (centang jika sudah diminum)
                    if (medicationData['isTaken'] == true)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
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
  }
}