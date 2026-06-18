import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/pharmacy_service.dart';

class PharmacySearchScreen extends ConsumerStatefulWidget {
  const PharmacySearchScreen({super.key});

  @override
  ConsumerState<PharmacySearchScreen> createState() =>
      _PharmacySearchScreenState();
}

class _PharmacySearchScreenState extends ConsumerState<PharmacySearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _pharmacies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacies() async {
    try {
      final pharmacies = await ref
          .read(pharmacyServiceProvider)
          .getPharmacies();
      if (mounted)
        setState(() {
          _pharmacies = pharmacies;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cari Apotek'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama apotek...',
                hintStyle: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pharmacies.isEmpty
                ? const Center(child: Text('Tidak ada apotek ditemukan'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _pharmacies.length,
                    itemBuilder: (_, i) => _buildPharmacyCard(_pharmacies[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(Map<String, dynamic> pharmacy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            pharmacy['logo_url'] as String? ?? '',
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_pharmacy_rounded,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        title: Text(
          pharmacy['name'] as String? ?? '',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              pharmacy['address'] as String? ?? '',
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: Color(0xFFFBBF24),
                ),
                const SizedBox(width: 2),
                Text(
                  '${pharmacy['rating'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textLight,
        ),
      ),
    );
  }
}
