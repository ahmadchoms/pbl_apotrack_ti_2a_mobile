import 'package:flutter/material.dart';

class StaffInventoryScreen extends StatelessWidget {
  const StaffInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1D70F5);
    const Color backgroundColor = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Stok Obat',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // --- SEARCH HEADER ---
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama obat atau kategori...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- MEDICINE LIST ---
          Expanded(
            child: _buildMedicineList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineList() {
    // Dummy Data
    final List<Map<String, dynamic>> dummyMedicines = [
      {
        'name': 'Amoxicillin 500mg',
        'type': 'Strip isi 10',
        'price': 'Rp 15.000',
        'stock': 45,
      },
      {
        'name': 'Paracetamol 500mg',
        'type': 'Pcs',
        'price': 'Rp 2.500',
        'stock': 8, // Low stock
      },
      {
        'name': 'OBH Combi Anak',
        'type': 'Botol 60ml',
        'price': 'Rp 18.500',
        'stock': 22,
      },
      {
        'name': 'Betadine Antiseptik',
        'type': 'Botol 15ml',
        'price': 'Rp 22.000',
        'stock': 5, // Low stock
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: dummyMedicines.length,
      itemBuilder: (context, index) {
        final medicine = dummyMedicines[index];
        return _buildMedicineCard(medicine);
      },
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    const Color primaryColor = Color(0xFF1D70F5);
    bool lowStock = (medicine['stock'] as int) < 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Placeholder Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication_outlined, color: Color(0xFF94A3B8), size: 30),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  medicine['type'],
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      medicine['price'],
                      style: const TextStyle(fontWeight: FontWeight.w900, color: primaryColor),
                    ),
                    Row(
                      children: [
                        const Text(
                          'Stok: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          medicine['stock'].toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: lowStock ? Colors.red : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Actions
          Column(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8), size: 20),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.swap_vert_rounded, color: primaryColor, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
