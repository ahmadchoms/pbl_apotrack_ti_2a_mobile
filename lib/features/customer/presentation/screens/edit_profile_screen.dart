import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/customer_profile_provider.dart';
import '../widgets/profile/profile_input_field.dart';

class CustomerEditProfileScreen extends ConsumerStatefulWidget {
  const CustomerEditProfileScreen({super.key});

  @override
  ConsumerState<CustomerEditProfileScreen> createState() =>
      _CustomerEditProfileScreenState();
}

class _CustomerEditProfileScreenState
    extends ConsumerState<CustomerEditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _phoneError;

  File? _pickedImage;
  final _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Isi dari provider — data sudah di-load di AccountHubScreen
    final profile = ref.read(customerProfileProvider).profile;
    if (profile != null) {
      _nameController.text = profile.username;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    if (_nameController.text.trim().isEmpty) {
      _nameError = 'Nama tidak boleh kosong';
      valid = false;
    } else {
      _nameError = null;
    }
    if (_emailController.text.trim().isEmpty) {
      _emailError = 'Email tidak boleh kosong';
      valid = false;
    } else if (!RegExp(
      r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$',
    ).hasMatch(_emailController.text.trim())) {
      _emailError = 'Format email tidak valid';
      valid = false;
    } else {
      _emailError = null;
    }
    if (_phoneController.text.trim().isEmpty) {
      _phoneError = 'Nomor telepon tidak boleh kosong';
      valid = false;
    } else {
      _phoneError = null;
    }
    setState(() {});
    return valid;
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 600,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const Text(
                'Foto Profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF1D70F5),
                  ),
                ),
                title: const Text(
                  'Ambil Foto',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF16A34A),
                  ),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(customerProfileProvider.notifier)
          .updateProfile(
            username: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            imageFile: _pickedImage,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1D70F5);
    final profile = ref.watch(customerProfileProvider).profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Ubah Profil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Avatar ──────────────────────────
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (profile?.avatarUrl != null
                                  ? NetworkImage(profile!.avatarUrl!)
                                  : null)
                              as ImageProvider?,
                    child: (_pickedImage == null && profile?.avatarUrl == null)
                        ? Text(
                            profile?.initials ?? '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Fields ──────────────────────────
            ProfileInputField(
              label: 'Nama Lengkap',
              controller: _nameController,
              icon: Icons.person_outline_rounded,
              errorText: _nameError,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 16),
            ProfileInputField(
              label: 'Email',
              controller: _emailController,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
            const SizedBox(height: 16),
            ProfileInputField(
              label: 'Nomor Telepon',
              controller: _phoneController,
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              errorText: _phoneError,
              onChanged: (_) {
                if (_phoneError != null) setState(() => _phoneError = null);
              },
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
