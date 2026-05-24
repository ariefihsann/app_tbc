import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'edit_obat_screen.dart';

class DetailObatScreen extends StatefulWidget {
  final Map<String, dynamic> medication;
  final DateTime selectedDate;

  const DetailObatScreen({
    super.key,
    required this.medication,
    required this.selectedDate,
  });

  @override
  State<DetailObatScreen> createState() => _DetailObatScreenState();
}

class _DetailObatScreenState extends State<DetailObatScreen> {
  bool _isTaken = false;
  DateTime? _takenAt;
  bool _isLoading = false;
  late Map<String, dynamic> _medication;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _medication = Map.from(widget.medication);
    _isTaken = _medication['isTaken'] ?? false;
    _takenAt = _medication['takenAt'];
  }

  // NOTIFIKASI SUKSES DI ATAS (TOP SNACKBAR)
  void _showTopSuccessNotification(String title, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white70,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✓',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 10, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 2),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  void _showTopErrorNotification(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed!',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white70,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✗',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.red.shade400,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 10, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 2),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  Future<void> _fetchLatestMedicationData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('medications')
          .select()
          .eq('id', _medication['id'])
          .single();

      setState(() {
        _medication = response;
        _isModified = true;
      });
    } catch (e) {
      print('Error fetching updated data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getSafeTime() {
    if (_medication['time'] != null && _medication['time'].toString().isNotEmpty) {
      return _medication['time'];
    }
    if (_medication['schedule_time'] != null) {
      String timeStr = _medication['schedule_time'].toString();
      if (timeStr.length >= 5) {
        return timeStr.substring(0, 5);
      }
      return timeStr;
    }
    if (_medication['schedule_times'] != null) {
      String times = _medication['schedule_times'].toString();
      return times.split(',').first.substring(0, 5);
    }
    return '--:--';
  }

  String _getSafeDosage() {
    if (_medication['dosage'] != null && _medication['dosage'].toString().isNotEmpty) {
      return _medication['dosage'].toString();
    }
    if (_medication['dosage_value'] != null) {
      return '${_medication['dosage_value']} ${_medication['dosage_unit'] ?? 'Mg'}';
    }
    return '1 pill';
  }

  String _getSafeFrequency() {
    if (_medication['frequency'] != null && _medication['frequency'].toString().isNotEmpty) {
      return _medication['frequency'];
    }
    if (_medication['schedule_times'] != null) {
      int count = _medication['schedule_times'].toString().split(',').length;
      return '$count x Sehari';
    }
    return '1 x Sehari';
  }

  String _getSafeTotalQuantity() {
    if (_medication['total_quantity'] != null) {
      return '${_medication['total_quantity']} ${_medication['per_intake_unit'] ?? 'Pil'}';
    }
    return '-';
  }

  String _getSafePerIntake() {
    if (_medication['quantity_per_intake'] != null) {
      return '${_medication['quantity_per_intake']} ${_medication['per_intake_unit'] ?? 'Pil'}';
    }
    return '-';
  }

  String _getSafeDuration() {
    if (_medication['start_date'] != null && _medication['end_date'] != null) {
      String start = _formatDateString(_medication['start_date'].toString());
      String end = _formatDateString(_medication['end_date'].toString());
      return '$start s/d $end';
    }
    return '-';
  }

  String _formatDateString(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getSafeNotes() {
    if (_medication['notes'] != null && _medication['notes'].toString().isNotEmpty) {
      return _medication['notes'].toString();
    }
    return '-';
  }

  String _getSafeScheduleTimes() {
    if (_medication['schedule_times'] != null && _medication['schedule_times'].toString().isNotEmpty) {
      List<String> times = _medication['schedule_times'].toString().split(',');
      List<String> formattedTimes = [];
      for (var t in times) {
        if (t.length >= 5) {
          formattedTimes.add(t.substring(0, 5));
        } else {
          formattedTimes.add(t);
        }
      }
      return formattedTimes.join(', ');
    }
    return _getSafeTime();
  }

  Future<void> _toggleMedication() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final dateStr = widget.selectedDate.toIso8601String().split('T')[0];
    final bool newStatus = !_isTaken;

    setState(() {
      _isTaken = newStatus;
      _takenAt = newStatus ? DateTime.now() : null;
    });

    try {
      await supabase.from('medication_logs').upsert({
        'user_id': user.id,
        'medication_id': _medication['id'],
        'log_date': dateStr,
        'is_taken': newStatus,
        'taken_at': newStatus ? DateTime.now().toUtc().toIso8601String() : null,
      }, onConflict: 'user_id, medication_id, log_date');

      if (mounted) {
        _showTopSuccessNotification(
          newStatus ? 'Marked as Taken' : 'Status Updated',
          newStatus 
            ? '${_medication['name']} telah ditandai sudah diminum'
            : '${_medication['name']} status dibatalkan'
        );
      }
    } catch (e) {
      setState(() {
        _isTaken = !newStatus;
        _takenAt = !newStatus ? DateTime.now() : null;
      });
      if (mounted) {
        _showTopErrorNotification('Gagal mengupdate status');
      }
    }
  }

  Future<void> _deleteMedication() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        actionsPadding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hapus Obat',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${_medication['name']}?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('medications').delete().eq('id', _medication['id']);

      if (mounted) {
        // Tampilkan notifikasi sukses di ATAS
        _showTopSuccessNotification('obat successfully deleted', _medication['name']);
        
        // Langsung kembali ke history tanpa delay
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showTopErrorNotification('Gagal menghapus obat, silakan coba lagi');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editMedication() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditObatScreen(medication: _medication),
      ),
    );

    if (result == true) {
      await _fetchLatestMedicationData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _isModified);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Detail Obat',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _isModified),
          ),
          actions: [
            IconButton(
              onPressed: _editMedication,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: _deleteMedication,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA5C4F7).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication,
                        size: 40,
                        color: Color(0xFF5B92F5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _medication['name'] ?? 'Obat',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isTaken
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isTaken ? 'Sudah Diminum' : 'Belum Diminum',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isTaken ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Informasi Obat Lengkap
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Obat',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: 'Waktu Minum',
                      value: _getSafeScheduleTimes(),
                    ),
                    const Divider(height: 24),

                    _buildInfoRow(
                      icon: Icons.medication,
                      label: 'Dosis',
                      value: _getSafeDosage(),
                    ),
                    const Divider(height: 24),

                    _buildInfoRow(
                      icon: Icons.repeat,
                      label: 'Frekuensi',
                      value: _getSafeFrequency(),
                    ),
                    const Divider(height: 24),

                    _buildInfoRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Jumlah Obat',
                      value: _getSafeTotalQuantity(),
                    ),
                    const Divider(height: 24),

                    _buildInfoRow(
                      icon: Icons.medication_liquid,
                      label: 'Jumlah Sekali Minum',
                      value: _getSafePerIntake(),
                    ),
                    const Divider(height: 24),

                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Durasi',
                      value: _getSafeDuration(),
                    ),

                    if (_getSafeNotes() != '-') ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.note_alt_outlined,
                        label: 'Catatan',
                        value: _getSafeNotes(),
                      ),
                    ],

                    if (_takenAt != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.check_circle_outline,
                        label: 'Diminum Pada',
                        value: DateFormat('dd MMM yyyy, HH:mm').format(_takenAt!),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Toggle Status
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _toggleMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTaken
                        ? Colors.orange
                        : const Color(0xFF5B92F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isTaken ? Icons.refresh : Icons.check_circle,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isTaken ? 'Batalkan Status' : 'Tandai Sudah Diminum',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF5B92F5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF5B92F5), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}