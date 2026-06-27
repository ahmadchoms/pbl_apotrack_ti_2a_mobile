import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/staff_service.dart';
import '../providers/staff_provider.dart';
import 'package:mobile/core/models/medicine.dart';
import '../widgets/medicine_form/medicine_form_batch.dart';

class MedicineDetailScreen extends ConsumerStatefulWidget {
  final Medicine medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  ConsumerState<MedicineDetailScreen> createState() =>
      _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends ConsumerState<MedicineDetailScreen> {
  late Medicine _medicine;

  @override
  void initState() {
    super.initState();
    _medicine = widget.medicine;
  }

  Future<void> _refreshDetail() async {
    try {
      final updated = await ref
          .read(staffServiceProvider)
          .getMedicine(_medicine.id);
      if (mounted) {
        setState(() => _medicine = updated);
        ref.invalidate(staffMedicinesProvider);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshDetail,
        edgeOffset: 100,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _MedicineHeroAppBar(medicine: _medicine),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _MedicinePrimaryInfo(medicine: _medicine),
                    const SizedBox(height: 20),
                    _InventoryInsightCard(medicine: _medicine),
                    const SizedBox(height: 20),
                    _ClinicalDetailSection(medicine: _medicine),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _PersistentActionFooter(
        onTap: () => _showBatchManagement(context),
      ),
    );
  }

  void _showBatchManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BatchManagementSheet(
        medicine: _medicine,
        onUpdate: (updatedMed) {
          setState(() => _medicine = updatedMed);
        },
      ),
    );
  }
}

class _MedicineHeroAppBar extends StatelessWidget {
  final Medicine medicine;
  const _MedicineHeroAppBar({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: AppColors.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.2),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.2),
            child: IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () =>
                  context.push('/staff/medicine-form', extra: medicine),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty)
              Image.network(medicine.imageUrl!, fit: BoxFit.cover)
            else
              Container(
                color: AppColors.primary,
                child: Icon(
                  medicine.icon,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 100,
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black26,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black45,
                  ],
                  stops: [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicinePrimaryInfo extends StatelessWidget {
  final Medicine medicine;
  const _MedicinePrimaryInfo({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildBadge(
              medicine.category ?? 'Uncategorized',
              AppColors.primary,
              AppColors.primaryLight,
            ),
            const SizedBox(width: 8),
            if (medicine.requiresPrescription)
              _buildBadge(
                'BUTUH RESEP',
                AppColors.warning,
                AppColors.warningLight,
                icon: Icons.receipt_long_rounded,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          medicine.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          medicine.genericName ?? '-',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                'Tipe',
                medicine.type ?? '-',
                Icons.medication_rounded,
              ),
              _buildVerticalDivider(),
              _buildInfoItem(
                'Bentuk',
                medicine.form ?? '-',
                Icons.waves_rounded,
              ),
              _buildVerticalDivider(),
              _buildInfoItem(
                'Satuan',
                medicine.unit ?? '-',
                Icons.straighten_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color, Color bg, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textSubtle),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() =>
      Container(width: 1, height: 30, color: AppColors.divider);
}

class _InventoryInsightCard extends StatelessWidget {
  final Medicine medicine;
  const _InventoryInsightCard({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final int stock = medicine.totalActiveStock;
    final bool isLow = stock <= 20;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isLow
              ? AppColors.danger.withValues(alpha: 0.1)
              : AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KETERSEDIAAN STOK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isLow ? AppColors.danger : AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$stock',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      medicine.unit ?? 'Unit',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildPriceTag(medicine.price),
        ],
      ),
    );
  }

  Widget _buildPriceTag(num price) {
    final str = price.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'HARGA JUAL',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rp ${buf.toString()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalDetailSection extends StatelessWidget {
  final Medicine medicine;
  const _ClinicalDetailSection({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMASI KLINIS',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textSubtle,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            'Deskripsi Produk',
            medicine.description ?? 'N/A',
            Icons.info_outline_rounded,
          ),
          const Divider(height: 32),
          _buildDetailRow(
            'Petunjuk Dosis',
            medicine.dosage ?? 'Ikuti instruksi dokter.',
            Icons.auto_graph_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMid,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _PersistentActionFooter extends StatelessWidget {
  final VoidCallback onTap;
  const _PersistentActionFooter({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(
            Icons.inventory_2_rounded,
            size: 20,
            color: Colors.white,
          ),
          label: const Text(
            'KELOLA BATCH & STOK',
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

class _BatchManagementSheet extends ConsumerStatefulWidget {
  final Medicine medicine;
  final Function(Medicine) onUpdate;
  const _BatchManagementSheet({required this.medicine, required this.onUpdate});

  @override
  ConsumerState<_BatchManagementSheet> createState() =>
      _BatchManagementSheetState();
}

class _BatchManagementSheetState extends ConsumerState<_BatchManagementSheet> {
  bool _isLoading = false;
  late Medicine _medicine;

  @override
  void initState() {
    super.initState();
    _medicine = widget.medicine;
  }

  Future<void> _refresh() async {
    final updated = await ref
        .read(staffServiceProvider)
        .getMedicine(_medicine.id);
    setState(() => _medicine = updated);
    widget.onUpdate(updated);
    ref.invalidate(staffMedicinesProvider);
  }

  Future<void> _addBatch(String number, String exp, int stock) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(staffServiceProvider).updateStock(_medicine.id, {
        'type': 'IN',
        'batch_number': number,
        'expired_date': exp,
        'quantity': stock,
      });
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch berhasil ditambahkan!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _adjustStock(String batchId, int newStock) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(staffServiceProvider).updateStock(_medicine.id, {
        'type': 'ADJUSTMENT',
        'batch_id': batchId,
        'new_stock': newStock,
      });
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok disesuaikan!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Inventory Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildQuickAddCard(),
                    const SizedBox(height: 32),
                    const Text(
                      'DAFTAR BATCH AKTIF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textLight,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(_medicine.batches ?? []).map(
                      (b) => _BatchItemCard(batch: b, onAdjust: _adjustStock),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.white.withValues(alpha: 0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Text(
            'Butuh penambahan stok baru?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showAddBatchDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 52),
              elevation: 0,
            ),
            child: const Text(
              'INPUT DATA BATCH BARU',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBatchDialog(BuildContext context) {
    String number = '', exp = '', stock = '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.add_business_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Input Batch Baru',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pastikan data sesuai dengan label fisik obat',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                MedicineFormBatchField(
                  initialValue: number,
                  label: 'NOMOR BATCH',
                  hint: 'B-2024-XXX',
                  icon: Icons.tag_rounded,
                  onChanged: (v) => number = v,
                ),
                const SizedBox(height: 16),
                MedicineFormBatchField(
                  label: 'TANGGAL KADALUWARSA',
                  hint: 'Pilih Tanggal',
                  icon: Icons.calendar_today_rounded,
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null) {
                      setDialogState(
                        () => exp = date.toString().split(' ').first,
                      );
                    }
                  },
                  initialValue: exp,
                  onChanged: (v) => exp = v,
                ),
                const SizedBox(height: 16),
                MedicineFormBatchField(
                  initialValue: stock,
                  label: 'STOK AWAL',
                  hint: '0',
                  icon: Icons.inventory_2_rounded,
                  keyboard: TextInputType.number,
                  isDigitsOnly: true,
                  onChanged: (v) => stock = v,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (number.isNotEmpty &&
                          exp.isNotEmpty &&
                          stock.isNotEmpty) {
                        _addBatch(number, exp, int.tryParse(stock) ?? 0);
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan Batch',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchItemCard extends StatelessWidget {
  final Map<String, dynamic> batch;
  final Function(String, int) onAdjust;
  const _BatchItemCard({required this.batch, required this.onAdjust});

  @override
  Widget build(BuildContext context) {
    final stock = batch['stock'] ?? 0;
    final exp = batch['expired_date']?.toString() ?? '-';
    bool isExpiring = false;
    try {
      isExpiring = DateTime.parse(exp).difference(DateTime.now()).inDays < 90;
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpiring
              ? AppColors.danger.withValues(alpha: 0.2)
              : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: isExpiring ? AppColors.danger : AppColors.textLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch['batch_number'] ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Exp: $exp',
                      style: TextStyle(
                        fontSize: 11,
                        color: isExpiring
                            ? AppColors.danger
                            : AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$stock',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Unit',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showAdjustDialog(context),
              icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
              label: const Text(
                'PENYESUAIAN STOK',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(BuildContext context) {
    String stock = batch['stock']?.toString() ?? '0';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Penyesuaian Stok',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Batch: ${batch['batch_number']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMid,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            MedicineFormBatchField(
              label: 'STOK TERBARU (AKTUAL)',
              initialValue: stock,
              icon: Icons.inventory_2_rounded,
              keyboard: TextInputType.number,
              isDigitsOnly: true,
              onChanged: (v) => stock = v,
            ),
            const SizedBox(height: 12),
            const Text(
              '*Gunakan fitur ini hanya jika terdapat selisih stok fisik',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textLight,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    onAdjust(batch['id'].toString(), int.tryParse(stock) ?? 0);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Stok',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
