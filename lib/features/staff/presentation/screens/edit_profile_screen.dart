import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/staff_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imagePicker = ImagePicker();

  XFile? _pickedFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Gunakan postFrameCallback untuk memastikan provider sudah siap jika dibutuhkan,
    // tapi untuk read di initState biasanya aman.
    final user = ref.read(authNotifierProvider).user;
    debugPrint("DEBUG INITIAL USER: $user");
    _initControllers(user);
  }

  void _initControllers(UserModel? user) {
    _nameController.text = user?.username ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked != null) {
        setState(() => _pickedFile = picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      _showSnack('Nama dan Email tidak boleh kosong', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = ref.read(staffServiceProvider);

      final Map<String, dynamic> data = {
        'username': name,
        'email': email,
        'phone': phone.isEmpty ? null : phone,
      };

      final formData = FormData.fromMap(data);
      if (_pickedFile != null) {
        if (kIsWeb) {
          formData.files.add(
            MapEntry(
              'image',
              MultipartFile.fromBytes(
                await _pickedFile!.readAsBytes(),
                filename: 'avatar.jpg',
              ),
            ),
          );
        } else {
          formData.files.add(
            MapEntry(
              'image',
              await MultipartFile.fromFile(
                _pickedFile!.path,
                filename: 'avatar.jpg',
              ),
            ),
          );
        }
      }

      // Laravel needs _method=PUT for multipart POST
      formData.fields.add(const MapEntry('_method', 'PUT'));

      await service.updateProfile(formData);

      // Refresh user session
      await ref.read(authNotifierProvider.notifier).updateProfileData();

      if (mounted) {
        _showSnack('Profil berhasil diperbarui!');
        context.pop();
      }
    } catch (e) {
      if (mounted) _showSnack('Gagal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to user changes to keep controllers in sync if data refreshes
    ref.listen(authNotifierProvider.select((s) => s.user), (prev, next) {
      if (next != null && prev != next) {
        _initControllers(next);
      }
    });

    final user = ref.watch(authNotifierProvider).user;
    final initials = (user?.username.isNotEmpty == true)
        ? user!.username
              .split(' ')
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join()
        : 'ST';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: AppColors.textDark,
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
            // --- AVATAR ---
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: _pickedFile != null
                            ? FileImage(File(_pickedFile!.path))
                            : (user?.avatarUrl != null &&
                                  user!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(user.avatarUrl!) as ImageProvider
                            : null,
                        child:
                            (_pickedFile == null &&
                                (user?.avatarUrl == null ||
                                    user!.avatarUrl!.isEmpty))
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- FORM ---
            _buildInputField(
              'Nama Lengkap',
              _nameController,
              Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              'Email',
              _emailController,
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              'Nomor Telepon',
              _phoneController,
              Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textMid, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
