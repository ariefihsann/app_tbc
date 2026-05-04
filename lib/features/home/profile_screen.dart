import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_screen.dart'; // Sesuaikan lokasi file home
import 'history_screen.dart'; // Sesuaikan lokasi file history
import '../auth/screens/login_screen.dart'; // Untuk fitur logout

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = 'Loading...';
  String _email = 'Loading...';
  bool _isPaused = true; // State untuk toggle notifikasi

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        // Ambil nama dari tabel profiles
        final data = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _fullName = data['full_name'] ?? 'User';
            _email = user.email ?? 'No Email';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullName = 'User';
          _email = 'user@example.com';
        });
      }
    }
  }

  // Fungsi tambahan untuk Logout (Ditaruh di tombol Reset Account)
  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Warna background senada
      body: Stack(
        children: [
          // KONTEN UTAMA
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 100), // Spasi atas

                // Foto Profil
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade300,
                    image: const DecorationImage(
                      // Gambar dummy, nantinya bisa pakai NetworkImage
                      image: AssetImage('assets/images/logo_tbc.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Fallback jika gambar tidak ada
                  child: const Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Nama & Email
                Text(
                  _fullName,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  _email,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // WIDGET MENU SETTING
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // Menu Pause Notifications
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_off_outlined, color: Colors.black87, size: 22),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text('Pause notifications', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                            ),
                            Switch(
                              value: _isPaused,
                              activeColor: Colors.white,
                              activeTrackColor: Colors.green,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: Colors.grey.shade300,
                              onChanged: (value) {
                                setState(() {
                                  _isPaused = value;
                                });
                              },
                            )
                          ],
                        ),
                      ),

                      Divider(height: 1, color: Colors.grey.shade200),

                      // Menu Reset Account / Logout
                      InkWell(
                        onTap: () {
                          // Untuk sementara kita jadikan fungsi Logout agar Mas Arif gampang ganti akun
                          _signOut();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: Row(
                            children: [
                              const Icon(Icons.restore, color: Colors.black87, size: 22),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text('Reset Account', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.black87, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
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
                  // Tombol Home (Inactive)
                  IconButton(
                    icon: const Icon(Icons.home_outlined, color: Colors.black54),
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                    },
                  ),
                  // Tombol History (Inactive)
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.black54),
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                    },
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        // Perbaikan ada di baris bawah ini (person_outline)
                        const Icon(Icons.person_outline, color: Color(0xFF4A89F3), size: 20),
                        const SizedBox(width: 6),
                        Text('Profile', style: GoogleFonts.poppins(color: const Color(0xFF4A89F3), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}