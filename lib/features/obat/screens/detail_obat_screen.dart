import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_obat_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _medication = Map.from(widget.medication);
    _isTaken = _medication['isTaken'] ?? false;
    _takenAt = _medication['takenAt'];
    
    // Debug print untuk melihat data
    print('=== DETAIL OBAT DATA ===');
    print('Medication: $_medication');
    print('isTaken: $_isTaken');
    print('takenAt: $_takenAt');
  }

  // Helper function untuk mendapatkan waktu dengan aman
  String _getSafeTime() {
    if (_medication['time'] != null) {
      return _medication['time'];
    }
    if (_medication['schedule_time'] != null) {
      String timeStr = _medication['schedule_time'];
      if (timeStr.length >= 5) {
        return timeStr.substring(0, 5);
      }
      return timeStr;
    }
    return '--:--';
  }

  // Helper function untuk mendapatkan dosis dengan aman
  String _getSafeDosage() {
    if (_medication['dosage'] != null && _medication['dosage'].toString().isNotEmpty) {
      return _medication['dosage'].toString();
    }
    return '1 pill';
  }

  // Helper function untuk mendapatkan catatan dengan aman
  String? _getSafeNotes() {
    if (_medication['notes'] != null && _medication['notes'].toString().isNotEmpty) {
      return _medication['notes'].toString();
    }
    return null;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Obat ditandai sudah diminum' : 'Status obat dibatalkan'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Revert if failed
      setState(() {
        _isTaken = !newStatus;
        _takenAt = !newStatus ? DateTime.now() : null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengupdate status')),
        );
      }
    }
  }

  Future<void> _deleteMedication() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Obat'),
        content: const Text('Apakah Anda yakin ingin menghapus obat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Obat berhasil dihapus')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus obat')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

                  // Informasi Obat
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
                          value: _getSafeTime(),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          icon: Icons.medication,
                          label: 'Dosis',
                          value: _getSafeDosage(),
                        ),
                        if (_getSafeNotes() != null) ...[
                          const Divider(height: 24),
                          _buildInfoRow(
                            icon: Icons.note_alt_outlined,
                            label: 'Catatan',
                            value: _getSafeNotes()!,
                          ),
                        ],
                        if (_takenAt != null) ...[
                          const Divider(height: 24),
                          _buildInfoRow(
                            icon: Icons.check_circle_outline,
                            label: 'Diminum Pada',
                            value: '${_takenAt!.hour.toString().padLeft(2, '0')}:${_takenAt!.minute.toString().padLeft(2, '0')}',
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
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
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

// Edit Obat Screen
class EditObatScreen extends StatefulWidget {
  final Map<String, dynamic> medication;

  const EditObatScreen({super.key, required this.medication});

  @override
  State<EditObatScreen> createState() => _EditObatScreenState();
}

class _EditObatScreenState extends State<EditObatScreen> {
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _notesController;
  late TimeOfDay _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication['name'] ?? '');
    _dosageController = TextEditingController(text: widget.medication['dosage'] ?? '');
    _notesController = TextEditingController(text: widget.medication['notes'] ?? '');
    
    // Safety check untuk time
    String timeStr = widget.medication['time'] ?? widget.medication['schedule_time'] ?? '08:00:00';
    if (timeStr.contains(':')) {
      final parts = timeStr.split(':');
      int hour = int.tryParse(parts[0]) ?? 8;
      int minute = int.tryParse(parts[1]) ?? 0;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    } else {
      _selectedTime = const TimeOfDay(hour: 8, minute: 0);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _updateMedication() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama obat tidak boleh kosong!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final timeStr = "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00";

      final updateData = {
        'name': _nameController.text.trim(),
        'schedule_time': timeStr,
      };
      
      if (_dosageController.text.trim().isNotEmpty) {
        updateData['dosage'] = _dosageController.text.trim();
      }
      
      if (_notesController.text.trim().isNotEmpty) {
        updateData['notes'] = _notesController.text.trim();
      }

      await supabase.from('medications').update(updateData).eq('id', widget.medication['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Obat berhasil diupdate')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error update: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengupdate obat')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Edit Obat',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama Obat',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Misal: Rifampicin',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Dosis',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dosageController,
              decoration: InputDecoration(
                hintText: 'Misal: 2 pill atau 1 kapsul',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Waktu Minum',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    const Icon(Icons.access_time, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Catatan (Opsional)',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Diminum sebelum makan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B92F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Update',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}