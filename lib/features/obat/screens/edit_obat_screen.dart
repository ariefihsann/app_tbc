import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class EditObatScreen extends StatefulWidget {
  final Map<String, dynamic> medication;

  const EditObatScreen({super.key, required this.medication});

  @override
  State<EditObatScreen> createState() => _EditObatScreenState();
}

class _EditObatScreenState extends State<EditObatScreen> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _frequencyController;
  late TextEditingController _quantityController;
  late TextEditingController _perIntakeController;
  late TextEditingController _notesController;

  // Variables
  late String _selectedUnit;
  late String _selectedPillUnit;
  late List<TimeOfDay> _multipleTimes;
  late List<bool> _timeChecked;
  late DateTime? _startDate;
  late DateTime? _endDate;

  bool _isLoading = false;

  // Options
  final List<String> _unitOptions = ['Mg', 'Ml', 'Gram', 'mcg'];
  final List<String> _pillUnitOptions = ['Pil', 'Kapsul', 'Tablet', 'Sendok'];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _nameController = TextEditingController(text: widget.medication['name'] ?? '');
    _initializeDosageData();
    _initializeFrequencyData();
    _initializeQuantityData();
    _initializePerIntakeData();
    _initializeScheduleTimes();
    _initializeDurationData();
    _notesController = TextEditingController(text: widget.medication['notes'] ?? '');
  }

  void _initializeDosageData() {
    if (widget.medication['dosage'] != null && widget.medication['dosage'].toString().isNotEmpty) {
      String dosage = widget.medication['dosage'].toString();
      RegExp regExp = RegExp(r'(\d+(?:\.\d+)?)\s*(\w+)');
      Match? match = regExp.firstMatch(dosage);
      if (match != null) {
        _dosageController = TextEditingController(text: match.group(1));
        _selectedUnit = match.group(2) ?? 'Mg';
      } else {
        _dosageController = TextEditingController(text: dosage);
        _selectedUnit = 'Mg';
      }
    } else if (widget.medication['dosage_value'] != null) {
      _dosageController = TextEditingController(text: widget.medication['dosage_value'].toString());
      _selectedUnit = widget.medication['dosage_unit'] ?? 'Mg';
    } else {
      _dosageController = TextEditingController(text: '');
      _selectedUnit = 'Mg';
    }
  }

  void _initializeFrequencyData() {
    String rawFrequency = widget.medication['frequency'] ?? '';
    final match = RegExp(r'\d+').firstMatch(rawFrequency);
    String initialCount = match != null ? match.group(0)! : '2';
    _frequencyController = TextEditingController(text: initialCount);
  }

  void _initializeQuantityData() {
    if (widget.medication['total_quantity'] != null) {
      _quantityController = TextEditingController(text: widget.medication['total_quantity'].toString());
    } else {
      _quantityController = TextEditingController(text: '');
    }
    _selectedPillUnit = widget.medication['per_intake_unit'] ?? 'Pil';

    if (!_pillUnitOptions.contains(_selectedPillUnit)) {
      _selectedPillUnit = 'Pil';
    }
  }

  void _initializePerIntakeData() {
    if (widget.medication['quantity_per_intake'] != null) {
      _perIntakeController = TextEditingController(text: widget.medication['quantity_per_intake'].toString());
    } else {
      _perIntakeController = TextEditingController(text: '');
    }
  }

  void _initializeScheduleTimes() {
    _multipleTimes = [];
    _timeChecked = [];

    String scheduleTimes = widget.medication['schedule_times'] ??
        widget.medication['schedule_time'] ??
        '08:00:00';

    List<String> times = scheduleTimes.split(',');

    for (int i = 0; i < times.length; i++) {
      String timeStr = times[i].trim();
      if (timeStr.length >= 5) {
        List<String> parts = timeStr.split(':');
        int hour = int.tryParse(parts[0]) ?? 8;
        int minute = int.tryParse(parts[1]) ?? 0;
        _multipleTimes.add(TimeOfDay(hour: hour, minute: minute));
        _timeChecked.add(true);
      }
    }

    int expectedCount = int.tryParse(_frequencyController.text.trim()) ?? 0;
    if (expectedCount == 0 && _multipleTimes.isNotEmpty) {
      expectedCount = _multipleTimes.length;
    }

    while (_multipleTimes.length < expectedCount) {
      _multipleTimes.add(const TimeOfDay(hour: 12, minute: 0));
      _timeChecked.add(true);
    }
    while (_multipleTimes.length > expectedCount) {
      _multipleTimes.removeLast();
      _timeChecked.removeLast();
    }
  }

  void _initializeDurationData() {
    if (widget.medication['start_date'] != null) {
      try {
        _startDate = DateTime.parse(widget.medication['start_date'].toString());
      } catch (e) {
        _startDate = DateTime.now();
      }
    } else {
      _startDate = DateTime.now();
    }

    if (widget.medication['end_date'] != null) {
      try {
        _endDate = DateTime.parse(widget.medication['end_date'].toString());
      } catch (e) {
        _endDate = DateTime.now().add(const Duration(days: 180));
      }
    } else {
      _endDate = DateTime.now().add(const Duration(days: 180));
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked.add(const Duration(days: 180));
        }
      });
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
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _multipleTimes[index],
    );
    if (picked != null && picked != _multipleTimes[index]) {
      setState(() {
        _multipleTimes[index] = picked;
      });
    }
  }

  void _toggleTimeCheck(int index) {
    setState(() {
      _timeChecked[index] = !_timeChecked[index];
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour12 = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    return '$hour12:$minute $period';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatTimeForDB(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00";
  }

  List<TimeOfDay> _getActiveTimes() {
    List<TimeOfDay> activeTimes = [];
    for (int i = 0; i < _timeChecked.length; i++) {
      if (_timeChecked[i] && i < _multipleTimes.length) {
        activeTimes.add(_multipleTimes[i]);
      }
    }
    return activeTimes;
  }

  void _adjustTimeSlots(String value) {
    if (value.trim().isEmpty) return;

    int expectedCount = int.tryParse(value.trim()) ?? _multipleTimes.length;
    if (expectedCount > 12) expectedCount = 12;

    setState(() {
      while (_multipleTimes.length < expectedCount) {
        _multipleTimes.add(const TimeOfDay(hour: 12, minute: 0));
        _timeChecked.add(true);
      }
      while (_multipleTimes.length > expectedCount) {
        _multipleTimes.removeLast();
        _timeChecked.removeLast();
      }
    });
  }

  // NOTIFIKASI SUKSES DI ATAS (TOP SNACKBAR)
  void _showTopSuccessNotification(String medicineName) {
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
                      'obat successfully updated',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      medicineName,
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

  Future<void> _updateMedication() async {
    if (_nameController.text.trim().isEmpty) {
      _showTopErrorNotification('Nama obat tidak boleh kosong');
      return;
    }

    if (_dosageController.text.trim().isEmpty) {
      _showTopErrorNotification('Dosis tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final dosageText = "${_dosageController.text.trim()} $_selectedUnit";
      final activeTimes = _getActiveTimes();
      final scheduleTimes = activeTimes.map((t) => _formatTimeForDB(t)).join(',');

      final startDateStr = _startDate?.toIso8601String().split('T')[0];
      final endDateStr = _endDate?.toIso8601String().split('T')[0];

      String frequencyString = _frequencyController.text.trim().isNotEmpty
          ? '${_frequencyController.text.trim()}x Sehari'
          : '1x Sehari';

      final updateData = {
        'name': _nameController.text.trim(),
        'dosage': dosageText,
        'dosage_value': int.tryParse(_dosageController.text.trim()),
        'dosage_unit': _selectedUnit,
        'frequency': frequencyString,
        'total_quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        'quantity_per_intake': int.tryParse(_perIntakeController.text.trim()) ?? 1,
        'per_intake_unit': _selectedPillUnit,
        'schedule_times': scheduleTimes,
        'schedule_time': scheduleTimes.isNotEmpty ? scheduleTimes.split(',').first : null,
        'start_date': startDateStr,
        'end_date': endDateStr,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('medications')
          .update(updateData)
          .eq('id', widget.medication['id']);

      if (mounted) {
        // Tampilkan notifikasi sukses di ATAS
        _showTopSuccessNotification(_nameController.text.trim());
        
        // LANGSUNG KEMBALI KE HISTORY TANPA DELAY
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error update: $e');
      if (mounted) {
        _showTopErrorNotification('Gagal mengupdate obat, silakan coba lagi');
        setState(() => _isLoading = false);
      }
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
          'Edit Your Medicine',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
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
            _buildTextField(controller: _nameController, hint: 'Masukkan nama obat'),
            const SizedBox(height: 20),

            _buildSectionTitle('Dosis'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField(controller: _dosageController, hint: '500', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildDropdown(value: _selectedUnit, items: _unitOptions, onChanged: (v) => setState(() => _selectedUnit = v!))),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Frekuensi (Berapa kali sehari?)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _frequencyController,
              hint: 'Contoh isi angka: 3',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _adjustTimeSlots(value);
              },
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Jumlah Obat'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField(controller: _quantityController, hint: '120', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildDropdown(value: _selectedPillUnit, items: _pillUnitOptions, onChanged: (v) => setState(() => _selectedPillUnit = v!))),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Jumlah Obat Sekali Minum'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField(controller: _perIntakeController, hint: '2', keyboardType: TextInputType.number)),
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
            Column(
              children: List.generate(_multipleTimes.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleTimeCheck(index),
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: _timeChecked[index] ? const Color(0xFF5B92F5) : Colors.white,
                            border: Border.all(color: _timeChecked[index] ? const Color(0xFF5B92F5) : Colors.grey.shade400, width: 2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _timeChecked[index] ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(context, index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatTime(_multipleTimes[index]), style: GoogleFonts.poppins(fontSize: 14, color: _timeChecked[index] ? Colors.black : Colors.grey.shade400)),
                                Icon(Icons.access_time, color: _timeChecked[index] ? Colors.grey : Colors.grey.shade300, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 10),

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
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B92F5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Update', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF5B92F5), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: GoogleFonts.poppins(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _quantityController.dispose();
    _perIntakeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}