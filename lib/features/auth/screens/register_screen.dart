import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // BG Layar jadi FFF
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
                    // TB (Grey Muda & Tipis) Checker (Blue)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'TB',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w500, // Tipis (Medium)
                              color: const Color(0xFFBDBDBD), // Abu-abu muda
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
                          MaterialPageRoute(builder: (context) => const LoginScreen())
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
              const CustomShadowInput(
                icon: Icons.person_outline,
                hintText: '',
              ),
              const SizedBox(height: 24),

              // Input Email
              const CustomShadowInput(
                icon: Icons.mail_outline,
                hintText: '',
              ),
              const SizedBox(height: 24),

              // Input Password
              const CustomShadowInput(
                icon: Icons.lock_outline,
                hintText: '',
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

                  // Tombol Register (Tetap berlabel Login sesuai desain gambar)
                  SizedBox(
                    width: 130,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B92F5),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.login_rounded, color: Colors.white, size: 18),
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

// Gunakan CustomShadowInput yang sama dengan LoginScreen
class CustomShadowInput extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final bool isPassword;

  const CustomShadowInput({
    super.key,
    required this.icon,
    required this.hintText,
    this.isPassword = false,
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
        obscureText: isPassword,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
          hintText: hintText,
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.only(right: 16),
        ),
      ),
    );
  }
}