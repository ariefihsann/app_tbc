import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetAccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Reset semua medications (data obat) untuk user tertentu
  Future<void> resetUserMedications(String userId) async {
    try {
      // Hapus semua data obat dari tabel medications
      await _supabase.from('medications').delete().eq('user_id', userId);

      debugPrint('Medications deleted for user: $userId');
    } catch (e) {
      debugPrint('Error deleting medications: $e');
      throw Exception('Failed to reset medications: $e');
    }
  }

  /// Hapus semua medication logs (riwayat minum obat)
  Future<void> resetMedicationLogs(String userId) async {
    try {
      // Hapus semua logs dari tabel medication_logs
      await _supabase.from('medication_logs').delete().eq('user_id', userId);

      debugPrint('Medication logs deleted for user: $userId');
    } catch (e) {
      debugPrint('Error deleting medication logs: $e');
      throw Exception('Failed to reset medication logs: $e');
    }
  }

  /// Reset streak data di profiles ke 0
  Future<void> resetUserStreak(String userId) async {
    try {
      // Reset current_streak dan best_streak ke 0
      await _supabase
          .from('profiles')
          .update({'current_streak': 0, 'best_streak': 0})
          .eq('id', userId);

      debugPrint('Streak reset to 0 for user: $userId');
    } catch (e) {
      debugPrint('Error resetting streak: $e');
      throw Exception('Failed to reset streak: $e');
    }
  }

  /// Reset complete account (medications + logs + streaks)
  Future<void> resetCompleteAccount(String userId) async {
    try {
      // Hapus medications terlebih dahulu
      await resetUserMedications(userId);

      // Hapus medication logs
      await resetMedicationLogs(userId);

      // Reset streak ke 0
      await resetUserStreak(userId);

      debugPrint('Account fully reset for user: $userId');
    } catch (e) {
      debugPrint('Error resetting account: $e');
      throw Exception('Failed to reset account: $e');
    }
  }

  /// Verifikasi apakah data sudah benar-benar kosong
  Future<Map<String, dynamic>> verifyReset(String userId) async {
    try {
      // Cek jumlah medications
      final medicationsResponse = await _supabase
          .from('medications')
          .select('id')
          .eq('user_id', userId);

      final medicationsCount = medicationsResponse.length;

      // Cek jumlah medication logs
      final logsResponse = await _supabase
          .from('medication_logs')
          .select('id')
          .eq('user_id', userId);

      final logsCount = logsResponse.length;

      // Cek streak values
      final profileResponse = await _supabase
          .from('profiles')
          .select('current_streak, best_streak')
          .eq('id', userId)
          .maybeSingle();

      int currentStreak = 0;
      int bestStreak = 0;

      if (profileResponse != null) {
        currentStreak = profileResponse['current_streak'] ?? 0;
        bestStreak = profileResponse['best_streak'] ?? 0;
      }

      debugPrint(
        'Verification - Medications: $medicationsCount, Logs: $logsCount, Streak: $currentStreak/$bestStreak',
      );

      return {
        'medications_count': medicationsCount,
        'logs_count': logsCount,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
      };
    } catch (e) {
      debugPrint('Error verifying reset: $e');
      throw Exception('Failed to verify reset: $e');
    }
  }
}

/// Widget dialog konfirmasi reset account dengan warning lebih jelas
Future<bool?> showResetAccountDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            'Reset Account',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This action will permanently delete:',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.medication, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'All your medication data (obat-obatan)',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.history, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your medication history (riwayat minum obat)',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                size: 16,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your current streak (will reset to 0)',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.emoji_events, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your best streak record',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              '⚠️ This action cannot be undone!',
              style: GoogleFonts.poppins(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Text(
            'Yes, Reset',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

/// Fungsi untuk menjalankan reset account
Future<bool> executeResetAccount(BuildContext context, String userId) async {
  // Tampilkan loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Resetting account...', style: GoogleFonts.poppins()),
          const SizedBox(height: 8),
          Text(
            'Please wait',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    ),
  );

  try {
    final resetService = ResetAccountService();

    // Reset semua data
    await resetService.resetCompleteAccount(userId);

    // Verifikasi reset berhasil
    final verification = await resetService.verifyReset(userId);

    if (context.mounted) {
      // Tutup loading dialog
      Navigator.pop(context);

      if (verification['medications_count'] == 0 &&
          verification['logs_count'] == 0 &&
          verification['current_streak'] == 0 &&
          verification['best_streak'] == 0) {
        // Tampilkan pesan sukses dengan detail
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Reset Successful!',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'All medications deleted • Streak reset to 0',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        return true;
      } else {
        throw Exception('Verification failed: Data still exists');
      }
    }
    return false;
  } catch (e) {
    if (context.mounted) {
      // Tutup loading dialog
      Navigator.pop(context);

      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error resetting account: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    return false;
  }
}