import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_tbc/core/services/notification_service.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _perIntakeController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedUnit = 'Mg';
  String _selectedFrequency = '2x Sehari';
  String _selectedPillUnit = 'Pil';
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  
  final List<String> _unitOptions = ['Mg', 'Ml', 'Gram', 'mcg'];
  final List<String> _frequencyOptions = ['1x Sehari', '2x Sehari', '3x Sehari'];
  final List<String> _pillUnitOptions = ['Pil', 'Kapsul', 'Tablet', 'Sendok'];
  
  List<TimeOfDay> _multipleTimes = [const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 18, minute: 0)];
  List<bool> _timeChecked = [true, true];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 180));
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null && picked != _endDate) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _multipleTimes[index],
    );
    if (picked != null && picked != _multipleTimes[index]) {
      setState(() => _multipleTimes[index] = picked);
    }
  }

  void _toggleTimeCheck(int index) {
    setState(() => _timeChecked[index] = !_timeChecked[index]);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _saveMedication() async {
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
      
      if (user == null) throw Exception('User tidak login');

      final timeStr = "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00";
      
      // Gabungkan semua informasi ke dalam field notes (karena kolom lain mungkin tidak ada)
      final allNotes = '''
Nama: ${_nameController.text.trim()}
Dosis: ${_dosageController.text.trim()} $_selectedUnit
Frekuensi: $_selectedFrequency
Jumlah Obat: ${_quantityController.text.trim()} $_selectedPillUnit
Sekali Minum: ${_perIntakeController.text.trim()} $_selectedPillUnit
Waktu: ${_formatTime(_selectedTime)}
Durasi: ${_startDate != null ? _formatDate(_startDate!) : '-'} s/d ${_endDate != null ? _formatDate(_endDate!) : '-'}
Catatan: ${_notesController.text.trim()}
''';

      final data = {
        'user_id': user.id,
        'name': _nameController.text.trim(),
        'schedule_time': timeStr,
        'notes': allNotes, // Simpan semua data ke notes
      };

      await supabase.from('medications').insert(data);
      // Aktifkan alarm notifikasi di HP User

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Obat berhasil ditambahkan!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${e.toString()}'), backgroundColor: Colors.red),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Your Medicine',
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Nama Obat'),
            const SizedBox(height: 8),
            _buildTextField(_nameController, 'Masukkan nama obat'),
            const SizedBox(height: 20),

            _buildSectionTitle('Dosis'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField(_dosageController, '500', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildDropdown(_selectedUnit, _unitOptions, (v) => setState(() => _selectedUnit = v!))),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Frekuensi'),
            const SizedBox(height: 8),
            _buildDropdown(_selectedFrequency, _frequencyOptions, (v) => setState(() => _selectedFrequency = v!)),
            const SizedBox(height: 20),

            _buildSectionTitle('Jumlah Obat'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField(_quantityController, '120', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildDropdown(_selectedPillUnit, _pillUnitOptions, (v) => setState(() => _selectedPillUnit = v!))),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Jumlah Obat Sekali Minum'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField(_perIntakeController, '2', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                  child: Text(_selectedPillUnit, style: GoogleFonts.poppins(fontSize: 14)),
                )),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Waktu Minum'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectTime(context, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatTime(_selectedTime), style: GoogleFonts.poppins(fontSize: 14)),
                    const Icon(Icons.access_time, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Durasi'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: GestureDetector(
                  onTap: () => _selectStartDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                    child: Text(_startDate != null ? _formatDate(_startDate!) : 'Pilih tanggal', style: GoogleFonts.poppins(fontSize: 14)),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: GestureDetector(
                  onTap: () => _selectEndDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                    child: Text(_endDate != null ? _formatDate(_endDate!) : 'Pilih tanggal', style: GoogleFonts.poppins(fontSize: 14)),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Catatan'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Masukkan Catatan (Ex: Sebelum Makan)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B92F5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Simpan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14));
  
  Widget _buildTextField(TextEditingController c, String h, {TextInputType keyboardType = TextInputType.text}) => TextField(
    controller: c, keyboardType: keyboardType,
    decoration: InputDecoration(
      hintText: h, hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value, isExpanded: true, icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    ),
  );

  @override
  void dispose() {
    _nameController.dispose(); _dosageController.dispose(); _quantityController.dispose();
    _perIntakeController.dispose(); _notesController.dispose();
    super.dispose();
  }
}