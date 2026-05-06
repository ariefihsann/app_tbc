import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddObatScreen extends StatefulWidget {
  const AddObatScreen({super.key});

  @override
  State<AddObatScreen> createState() => _AddObatScreenState();
}

class _AddObatScreenState extends State<AddObatScreen> {
  // Controllers
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _perIntakeController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Variables
  String _selectedUnit = 'Mg';
  String _selectedFrequency = '2x Sehari';
  String _selectedPillUnit = 'Pil';
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  
  // Options
  final List<String> _unitOptions = ['Mg', 'Ml', 'Gram', ' mcg'];
  final List<String> _frequencyOptions = ['1x Sehari', '2x Sehari', '3x Sehari'];
  final List<String> _pillUnitOptions = ['Pil', 'Kapsul', 'Tablet', 'Sendok'];
  
  // Multiple time options (for 2x sehari, etc.)
  List<TimeOfDay> _multipleTimes = [TimeOfDay.now(), TimeOfDay.now()];
  List<bool> _timeChecked = [true, true];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 180));
    _initializeMultipleTimes();
  }

  void _initializeMultipleTimes() {
    // Set default times: 08:00 and 18:00
    _multipleTimes = [
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 18, minute: 0),
    ];
    _timeChecked = [true, true];
    _selectedTime = _multipleTimes[0];
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

  Future<void> _saveMedication() async {
    // Validations
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama obat tidak boleh kosong!')),
      );
      return;
    }

    if (_dosageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosis tidak boleh kosong!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Build dosage string
      final dosageText = "${_dosageController.text.trim()} ${_selectedUnit}";
      
      // Build frequency text with times
      final activeTimes = _getActiveTimes();
      final frequencyText = _selectedFrequency;
      
      // Build schedule times as JSON or comma separated
      final scheduleTimes = activeTimes.map((t) => _formatTimeForDB(t)).join(',');
      
      // Format dates
      final startDateStr = _startDate?.toIso8601String().split('T')[0];
      final endDateStr = _endDate?.toIso8601String().split('T')[0];

      await supabase.from('medications').insert({
        'user_id': user.id,
        'name': _nameController.text.trim(),
        'dosage': dosageText,
        'dosage_value': int.tryParse(_dosageController.text.trim()),
        'dosage_unit': _selectedUnit,
        'frequency': _selectedFrequency,
        'total_quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        'quantity_per_intake': int.tryParse(_perIntakeController.text.trim()) ?? 1,
        'per_intake_unit': _selectedPillUnit,
        'schedule_times': scheduleTimes,
        'schedule_time': scheduleTimes.split(',')[0], // For backward compatibility
        'start_date': startDateStr,
        'end_date': endDateStr,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Obat berhasil ditambahkan!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving medication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan obat'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  String _formatTimeForDB(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00";
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
            // Nama Obat
            _buildSectionTitle('Nama Obat'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'Masukkan nama obat',
            ),
            const SizedBox(height: 20),

            // Dosis
            _buildSectionTitle('Dosis'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _dosageController,
                    hint: '500',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildDropdown(
                    value: _selectedUnit,
                    items: _unitOptions,
                    onChanged: (value) => setState(() => _selectedUnit = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Frekuensi
            _buildSectionTitle('Frekuensi'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedFrequency,
              items: _frequencyOptions,
              onChanged: (value) => setState(() => _selectedFrequency = value!),
            ),
            const SizedBox(height: 20),

            // Jumlah Obat
            _buildSectionTitle('Jumlah Obat'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _quantityController,
                    hint: '120',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildDropdown(
                    value: _selectedPillUnit,
                    items: _pillUnitOptions,
                    onChanged: (value) => setState(() => _selectedPillUnit = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Jumlah Obat Sekali Minum
            _buildSectionTitle('Jumlah Obat Sekali Minum'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _perIntakeController,
                    hint: '2',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _selectedPillUnit,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Waktu Minum
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
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _timeChecked[index] 
                                ? const Color(0xFF5B92F5) 
                                : Colors.white,
                            border: Border.all(
                              color: _timeChecked[index] 
                                  ? const Color(0xFF5B92F5) 
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _timeChecked[index]
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(context, index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTime(_multipleTimes[index]),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: _timeChecked[index] 
                                        ? Colors.black 
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                Icon(
                                  Icons.access_time,
                                  color: _timeChecked[index] 
                                      ? Colors.grey 
                                      : Colors.grey.shade300,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (index == _multipleTimes.length - 1 && _selectedFrequency != '1x Sehari')
                        const SizedBox(width: 30),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Durasi
            _buildSectionTitle('Durasi'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectStartDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _startDate != null ? _formatDate(_startDate!) : 'Pilih tanggal',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectEndDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _endDate != null ? _formatDate(_endDate!) : 'Pilih tanggal',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Catatan
            _buildSectionTitle('Catatan'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Masukkan Catatan (Ex: Sebelum Makan)',
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF5B92F5), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 32),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B92F5),
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
                    : Text(
                        'Simpan',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF5B92F5), width: 2),
        ),
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
              child: Text(
                item,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
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
    _quantityController.dispose();
    _perIntakeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}