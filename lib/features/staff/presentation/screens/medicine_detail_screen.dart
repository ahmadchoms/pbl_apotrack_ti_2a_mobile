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
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
}

class MedicineDetailScreen extends StatelessWidget {
  const MedicineDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data based on what we saw in Inventory Screen
    final medicine = {
      'name': 'Amoxicillin 500mg',
      'generic_name': 'Amoxicillin Trihydrate',
      'category': 'Antibiotik',
      'type': 'Tablet',
      'form': 'Strip isi 10',
      'unit': 'Strip',
      'price': 15000,
      'stock': 45,
      'min_stock': 20,
      'manufacturer': 'Kimia Farma',
      'description': 'Amoxicillin adalah obat antibiotik yang digunakan untuk mengobati berbagai macam infeksi bakteri.',
      'dosage': 'Dewasa: 250-500 mg setiap 8 jam.',
      'requires_prescription': true,
      'is_active': true,
      'batches': [
        {'number': 'BCH-2024-001', 'exp': '12 Des 2025', 'stock': 20},
        {'number': 'BCH-2024-005', 'exp': '15 Jan 2026', 'stock': 25},
      ],
    };

    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context, medicine),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                children: [
                  _buildMainInfoCard(medicine),
                  const SizedBox(height: 16),
                  _buildInventoryCard(medicine),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(medicine),
                  const SizedBox(height: 16),
                  _buildBatchList(medicine),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildActionBottom(context),
    );
  }

  Widget _buildSliverHeader(BuildContext context, Map<String, dynamic> med) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _C.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
          onPressed: () => context.push('/staff/medicine-form', extra: med),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: _C.primary,
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 50),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfoCard(Map<String, dynamic> med) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  med['category'] as String,
                  style: const TextStyle(color: _C.primary, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              if (med['requires_prescription'] as bool)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.description_outlined, color: Color(0xFFF59E0B), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'RESEP DOKTER',
                        style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            med['name'] as String,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _C.textDark, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            med['generic_name'] as String,
            style: const TextStyle(fontSize: 14, color: _C.textLight, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSimpleStat('Tipe', med['type'] as String),
              _buildSimpleStat('Satuan', med['unit'] as String),
              _buildSimpleStat('Produsen', med['manufacturer'] as String),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _C.textLight, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: _C.textDark, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> med) {
    final int stock = med['stock'] as int;
    final int price = med['price'] as int;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('STOK SAAT INI', style: TextStyle(color: _C.textLight, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$stock', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _C.textDark)),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(med['unit'] as String, style: const TextStyle(color: _C.textLight, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: _C.divider),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HARGA JUAL', style: TextStyle(color: _C.textLight, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Text('Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _C.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Map<String, dynamic> med) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DESKRIPSI & DOSIS', style: TextStyle(color: _C.textLight, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          Text(med['description'] as String, style: const TextStyle(color: _C.textMid, height: 1.6, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: _C.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Petunjuk Dosis', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _C.textDark)),
                      const SizedBox(height: 4),
                      Text(med['dosage'] as String, style: const TextStyle(color: _C.textMid, fontSize: 12, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchList(Map<String, dynamic> med) {
    final batches = med['batches'] as List<Map<String, dynamic>>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('DATA BATCH & EXPIRED', style: TextStyle(color: _C.textLight, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        ),
        ...batches.map((b) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: _C.textMid, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b['number'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _C.textDark)),
                    const SizedBox(height: 2),
                    Text('Exp: ${b['exp']}', style: const TextStyle(color: _C.textLight, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${b['stock']} unit', style: const TextStyle(color: _C.primary, fontSize: 12, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActionBottom(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _C.divider),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Kelola Batch', style: TextStyle(color: _C.textMid, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => HapticFeedback.mediumImpact(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Update Stok', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
