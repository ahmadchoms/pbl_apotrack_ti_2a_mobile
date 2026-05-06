import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // --- TOP BAR & SEARCH ---
          _buildSliverAppBar(),
          
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategories(),
                _buildPromoSection(),
                _buildSectionHeader('Obat Populer', () {}),
                _buildProductGrid(),
                const SizedBox(height: 100), // Padding bottom
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokasi Anda',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Seturan, Yogyakarta',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      _buildHeaderIcon(Icons.notifications_none_rounded),
                      const SizedBox(width: 10),
                      _buildHeaderIcon(Icons.shopping_cart_outlined),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Cari Obat Apa?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Cari obat, vitamin, atau alat kesehatan...',
                hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildCategories() {
    final cats = [
      {'icon': Icons.medication_rounded, 'label': 'Obat', 'color': const Color(0xFF6366F1)},
      {'icon': Icons.health_and_safety_rounded, 'label': 'Vitamin', 'color': const Color(0xFF10B981)},
      {'icon': Icons.child_care_rounded, 'label': 'Ibu & Anak', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.healing_rounded, 'label': 'P3K', 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.science_outlined, 'label': 'Alkes', 'color': const Color(0xFF8B5CF6)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            'KATEGORI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textLight,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (_, i) => Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (cats[i]['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(cats[i]['icon'] as IconData, color: cats[i]['color'] as Color, size: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  cats[i]['label'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Penawaran Terbatas', () {}),
        SizedBox(
          height: 150,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) => Container(
              width: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: i == 0 
                    ? [const Color(0xFF1D70F5), const Color(0xFF3B82F6)]
                    : [const Color(0xFF10B981), const Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.local_offer_rounded,
                      size: 120,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PROMO HARI INI',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Diskon Vitamin Up to 30%',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const Text(
                          'Khusus pembelian melalui aplikasi',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: const Text(
              'Lihat Semua',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = [
      {'name': 'Paracetamol', 'price': 2500, 'unit': 'Tablet', 'image': Icons.medication_rounded},
      {'name': 'Amoxicillin', 'price': 15000, 'unit': 'Strip', 'image': Icons.local_pharmacy_rounded},
      {'name': 'Vitamin C 1000mg', 'price': 8000, 'unit': 'Box', 'image': Icons.health_and_safety_rounded},
      {'name': 'Sangobion', 'price': 22000, 'unit': 'Box', 'image': Icons.bloodtype_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (_, i) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Icon(products[i]['image'] as IconData, size: 48, color: AppColors.primary.withOpacity(0.3)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      products[i]['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'per ${products[i]['unit']}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${products[i]['price']}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
