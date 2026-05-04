import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Tambahkan import Supabase
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. Siapkan controller untuk menangkap teks inputan
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // 2. Fungsi utama untuk mendaftar ke Supabase
  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // Mendaftarkan user ke sistem Auth Supabase
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = authResponse.user;

      // Jika berhasil daftar Auth, simpan nama ke tabel 'profiles'
      if (user != null) {
        await supabase.from('profiles').insert({
          'id': user.id,
          'full_name': _nameController.text.trim(),
          'current_streak': 0,
          'best_streak': 0,
          'target_streak': 7,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi Berhasil! Silakan Sign In.'),
              backgroundColor: Colors.green,
            ),
          );
          // Pindah ke halaman Login setelah sukses
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan yang tidak terduga'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 3. Bersihkan controller saat layar ditutup untuk mencegah memory leak
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 44.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Area Logo & Teks Dua Warna
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo_tbc.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'TB',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFBDBDBD),
                            ),
                          ),
                          TextSpan(
                            text: 'Checker',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4A89F3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // Judul Register
              Text(
                'Register',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // Sub-judul & Sign In (Link Aktif)
              Row(
                children: [
                  Text(
                    "Already have account? ",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      "sign in",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A89F3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Input Name
              CustomShadowInput(
                controller: _nameController, // Menghubungkan controller
                icon: Icons.person_outline,
                hintText: 'Full Name', // Menambahkan hint text
              ),
              const SizedBox(height: 24),

              // Input Email
              CustomShadowInput(
                controller: _emailController, // Menghubungkan controller
                icon: Icons.mail_outline,
                hintText: 'Email', // Menambahkan hint text
              ),
              const SizedBox(height: 24),

              // Input Password
              CustomShadowInput(
                controller: _passwordController, // Menghubungkan controller
                icon: Icons.lock_outline,
                hintText: 'Password', // Menambahkan hint text
                isPassword: true,
              ),
              const SizedBox(height: 54),

              // Row Bawah: Google & Register Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ikon Google Placeholder
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_to_home_screen_rounded,
                        color: Colors.grey,
                        size: 22,
                      ),
                    ),
                  ),

                  // Tombol Register dengan indikator Loading
                  SizedBox(
                    width: 130,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp, // Panggil fungsi saat ditekan
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B92F5),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Register', // Mengubah label agar sesuai fungsi
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.app_registration, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget Input (Sudah termasuk parameter controller)
class CustomShadowInput extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;

  const CustomShadowInput({
    super.key,
    required this.icon,
    required this.hintText,
    this.isPassword = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.only(right: 16),
        ),
      ),
    );
  }
}