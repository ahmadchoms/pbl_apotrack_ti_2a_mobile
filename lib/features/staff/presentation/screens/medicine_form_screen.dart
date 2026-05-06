import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class _C {
  static const primary = Color(0xFF1D70F5);
  static const primaryLight = Color(0xFFEEF4FF);
  static const bg = Color(0xFFF4F7FE);
  static const surface = Colors.white;
  static const textDark = Color(0xFF0F1828);
  static const textMid = Color(0xFF4B5563);
  static const textLight = Color(0xFF9CA3AF);
  static const divider = Color(0xFFE5EAF2);
}

class MedicineFormScreen extends StatefulWidget {
  final Map<String, dynamic>? medicine;
  const MedicineFormScreen({super.key, this.medicine});

  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  late bool isEdit;
  
  // Controllers
  final _nameCtrl = TextEditingController();
  final _genericNameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();

  // Selections
  String? _category;
  String? _type;
  String? _form;
  String? _unit;
  bool _requiresPrescription = false;
  bool _isActive = true;

  // Batches
  final List<Map<String, dynamic>> _batches = [];

  // Options (Dummy - should come from API)
  final _categories = ['Antibiotik', 'Analgesik', 'Sirup', 'Antiseptik', 'Suplemen', 'Antasida'];
  final _types = ['Tablet', 'Pcs', 'Botol 60ml', 'Botol 15ml', 'Strip isi 10'];
  final _forms = ['Kapsul', 'Tablet', 'Sirup', 'Cair', 'Salep'];
  final _units = ['Strip', 'Botol', 'Box', 'Tube'];

  @override
  void initState() {
    super.initState();
    isEdit = widget.medicine != null;
    if (isEdit) {
      final m = widget.medicine!;
      _nameCtrl.text = m['name'] ?? '';
      _genericNameCtrl.text = m['generic_name'] ?? '';
      _manufacturerCtrl.text = m['manufacturer'] ?? '';
      _priceCtrl.text = m['price']?.toString() ?? '';
      _weightCtrl.text = m['weight']?.toString() ?? '';
      _descCtrl.text = m['description'] ?? '';
      _dosageCtrl.text = m['dosage'] ?? '';
      _category = m['category'];
      _type = m['type'];
      _form = m['form'];
      _unit = m['unit'];
      _requiresPrescription = m['requires_prescription'] ?? false;
      _isActive = m['is_active'] ?? true;
      
      if (m['batches'] != null) {
        for (var b in (m['batches'] as List)) {
          _batches.add(Map<String, dynamic>.from(b));
        }
      }
    } else {
      _addBatch(); // Initial empty batch
    }
  }

  void _addBatch() {
    setState(() {
      _batches.add({
        'number': '',
        'exp': '',
        'stock': '',
      });
    });
  }

  void _removeBatch(int index) {
    setState(() {
      _batches.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.textDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEdit ? 'Edit Data Obat' : 'Tambah Obat Baru',
          style: const TextStyle(color: _C.textDark, fontWeight: FontWeight.w900, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          children: [
            _buildImageUpload(),
            const SizedBox(height: 20),
            _buildSection(
              title: 'INFORMASI UMUM',
              icon: Icons.medication_rounded,
              children: [
                _buildTextField('Nama Obat', _nameCtrl, hint: 'Contoh: Amoxicillin 500mg', required: true),
                _buildTextField('Nama Generik', _genericNameCtrl, hint: 'Contoh: Amoxicillin Trihydrate'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDropdown('Kategori', _category, _categories, (v) => setState(() => _category = v))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdown('Tipe', _type, _types, (v) => setState(() => _type = v))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDropdown('Sediaan', _form, _forms, (v) => setState(() => _form = v))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdown('Satuan', _unit, _units, (v) => setState(() => _unit = v))),
                  ],
                ),
                _buildTextField('Produsen / Pabrik', _manufacturerCtrl, hint: 'Contoh: Kimia Farma', icon: Icons.factory_outlined),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'HARGA & PENGATURAN',
              icon: Icons.payments_outlined,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTextField('Harga Jual', _priceCtrl, hint: '0', prefix: 'Rp', keyboard: TextInputType.number, required: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Berat (gram)', _weightCtrl, hint: '0', icon: Icons.scale_outlined, keyboard: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSwitchTile('Butuh Resep Dokter', 'Hanya bisa dibeli dengan resep', _requiresPrescription, (v) => setState(() => _requiresPrescription = v), Icons.description_outlined),
                _buildSwitchTile('Status Aktif', 'Obat tampil di katalog & bisa dipesan', _isActive, (v) => setState(() => _isActive = v), Icons.check_circle_outline_rounded),
              ],
            ),
            const SizedBox(height: 20),
            _buildBatchSection(),
            const SizedBox(height: 20),
            _buildSection(
              title: 'DESKRIPSI & DOSIS',
              icon: Icons.info_outline_rounded,
              children: [
                _buildTextField('Deskripsi Obat', _descCtrl, hint: 'Jelaskan kegunaan utama...', maxLines: 3),
                _buildTextField('Petunjuk Dosis', _dosageCtrl, hint: 'Contoh: Dewasa 3x1 tablet...', maxLines: 2),
              ],
            ),
          ],
        ),
      ),
      bottomSheet: _buildSaveButton(),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _C.primary, size: 18),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _C.textLight, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {String? hint, IconData? icon, String? prefix, TextInputType? keyboard, bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.textDark),
              children: [
                if (required) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: ctrl,
              keyboardType: keyboard,
              maxLines: maxLines,
              style: const TextStyle(fontSize: 14, color: _C.textDark, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: _C.textLight, fontSize: 13),
                prefixIcon: prefix != null ? Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(prefix, style: const TextStyle(color: _C.textMid, fontWeight: FontWeight.w700, fontSize: 14)),
                ) : (icon != null ? Icon(icon, color: _C.textLight, size: 18) : null),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.textDark)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text('Pilih', style: TextStyle(color: _C.textLight, fontSize: 13)),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String sub, bool value, Function(bool) onChanged, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _C.textMid, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _C.textDark)),
                Text(sub, style: const TextStyle(fontSize: 11, color: _C.textLight, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _C.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildImageUpload() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.divider, style: BorderStyle.none), // Simplified
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: _C.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.cloud_upload_outlined, color: _C.primary, size: 30),
          ),
          const SizedBox(height: 12),
          const Text('Upload Foto Obat', style: TextStyle(fontWeight: FontWeight.w800, color: _C.textDark, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('Format JPG/PNG, Max 2MB', style: TextStyle(color: _C.textLight, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBatchSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: _C.primary, size: 18),
                  const SizedBox(width: 10),
                  Text('BATCH & STOK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _C.textLight, letterSpacing: 1.0)),
                ],
              ),
              GestureDetector(
                onTap: _addBatch,
                child: const Text('+ Tambah Batch', style: TextStyle(color: _C.primary, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._batches.asMap().entries.map((entry) {
            final i = entry.key;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSmallField('No. Batch', entry.value['number'], (v) => _batches[i]['number'] = v)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSmallField('Expired', entry.value['exp'], (v) => _batches[i]['exp'] = v, hint: 'DD/MM/YYYY')),
                      if (_batches.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _removeBatch(i)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSmallField('Stok Batch', entry.value['stock'], (v) => _batches[i]['stock'] = v, keyboard: TextInputType.number),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSmallField(String label, String value, Function(String) onChanged, {String? hint, TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.textMid)),
        const SizedBox(height: 6),
        Container(
          height: 40,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: TextField(
            onChanged: onChanged,
            keyboardType: keyboard,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _C.textLight, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.heavyImpact();
            // Logic to save...
            context.pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.save_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(isEdit ? 'Simpan Perubahan' : 'Simpan Obat', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
