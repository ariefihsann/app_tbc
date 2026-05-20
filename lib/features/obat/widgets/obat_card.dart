import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ObatCard extends StatelessWidget {
  final String namaObat;
  final String dosis;
  final String waktu;
  final Color warnaIcon;
  final bool isSudahDiminum;
  final VoidCallback? onTap;
  final VoidCallback? onToggleStatus;

  const ObatCard({
    super.key,
    required this.namaObat,
    required this.dosis,
    required this.waktu,
    this.warnaIcon = const Color(0xFFA5C4F7),
    this.isSudahDiminum = false,
    this.onTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Lingkaran Obat
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: warnaIcon.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medication,
                color: warnaIcon,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Informasi Obat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaObat,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        waktu,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.medication,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dosis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status Checkbox atau Icon
            if (onToggleStatus != null)
              GestureDetector(
                onTap: onToggleStatus,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSudahDiminum
                        ? const Color(0xFF4A89F3)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSudahDiminum
                          ? const Color(0xFF4A89F3)
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isSudahDiminum
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.white,
                        )
                      : null,
                ),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSudahDiminum
                      ? Colors.green.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isSudahDiminum
                    ? const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Colors.green,
                      )
                    : const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

// Version untuk Timeline di History Screen
class ObatTimelineCard extends StatelessWidget {
  final String waktuMulai;
  final String waktuSelesai;
  final String namaObat;
  final String dosis;
  final Color warnaIcon;
  final bool isSudahDiminum;
  final VoidCallback? onTap;

  const ObatTimelineCard({
    super.key,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.namaObat,
    required this.dosis,
    this.warnaIcon = const Color(0xFFE2C8A0),
    this.isSudahDiminum = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    waktuSelesai,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    waktuMulai,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Garis status di sisi kiri
                    Container(
                      width: 3,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: isSudahDiminum ? Colors.green : const Color(0xFF5B92F5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Icon Lingkaran
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: warnaIcon.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.medication,
                        color: warnaIcon,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Teks Nama & Dosis
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            namaObat,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dosis,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Icon
                    if (isSudahDiminum)
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

// Version untuk Daftar Obat (List View)
class ObatListCard extends StatelessWidget {
  final String namaObat;
  final String dosis;
  final String waktu;
  final Color warnaIcon;
  final VoidCallback? onTap;

  const ObatListCard({
    super.key,
    required this.namaObat,
    required this.dosis,
    required this.waktu,
    this.warnaIcon = const Color(0xFFA5C4F7),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: warnaIcon.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication,
                color: warnaIcon,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaObat,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        waktu,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.medication,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dosis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}