import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/providers/chat_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _profileImageUrl;
  bool _isUploadingProfile = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get(ApiConstants.me);
      final data = response.data;
      final userData = data is Map<String, dynamic> && data.containsKey('data')
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      setState(() {
        _profileImageUrl = userData['profileImageUrl'] as String?;
      });
    } catch (_) {}
  }

  void _showProfileImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              if (_profileImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    '사진 삭제',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _removeProfileImage();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    setState(() => _isUploadingProfile = true);

    try {
      // Compress
      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        '${picked.path}_profile.jpg',
        quality: 85,
        minWidth: 512,
        minHeight: 512,
      );
      final file = File(compressed?.path ?? picked.path);
      final contentType = lookupMimeType(file.path) ?? 'image/jpeg';
      final fileLength = await file.length();

      // Get presigned URL
      final chatRepo = ref.read(chatRepositoryProvider);
      final presign = await chatRepo.getPresignedUrl(
        fileName: file.path.split('/').last,
        contentType: contentType,
        contentLength: fileLength,
        purpose: 'PROFILE',
      );

      // Upload to R2
      await chatRepo.uploadToR2(
        uploadUrl: presign.uploadUrl,
        file: file,
        contentType: contentType,
      );

      // Update user profile
      final client = ref.read(dioClientProvider);
      await client.put(
        ApiConstants.me,
        data: {'profileImageUrl': presign.publicUrl},
      );

      setState(() {
        _profileImageUrl = presign.publicUrl;
        _isUploadingProfile = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 사진이 변경되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingProfile = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 사진 업로드에 실패했습니다'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    try {
      final client = ref.read(dioClientProvider);
      await client.put(
        ApiConstants.me,
        data: {'profileImageUrl': ''},
      );
      setState(() => _profileImageUrl = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 사진이 삭제되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 사진 삭제에 실패했습니다'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          // Profile section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isUploadingProfile ? null : _showProfileImagePicker,
                  child: Stack(
                    children: [
                      if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(_profileImageUrl!),
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        )
                      else
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            (authState.nickname ?? '?').isNotEmpty
                                ? authState.nickname![0]
                                : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      if (_isUploadingProfile)
                        const Positioned.fill(
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.black38,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authState.nickname ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (authState.tag != null)
                      Text(
                        '#${authState.tag}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF8E8E93)),
            title: const Text('로그아웃'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authProvider.notifier).logout();
              }
            },
          ),
          const Divider(height: 1),

          // Account withdrawal
          ListTile(
            leading: const Icon(Icons.person_remove_outlined, color: Colors.red),
            title: const Text(
              '회원 탈퇴',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text(
              '계정과 모든 데이터가 영구적으로 삭제됩니다',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
            onTap: () => _showWithdrawalDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showWithdrawalDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('회원 탈퇴'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '탈퇴 시 다음 데이터가 모두 삭제됩니다:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text('• 계정 정보'),
                const Text('• 친구 목록'),
                const Text('• 채팅 기록'),
                const Text('• 전송한 메시지'),
                const SizedBox(height: 16),
                const Text(
                  '이 작업은 되돌릴 수 없습니다.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 확인',
                    hintText: '비밀번호를 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  passwordController.dispose();
                  Navigator.of(ctx).pop();
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  final password = passwordController.text.trim();
                  if (password.isEmpty) return;

                  Navigator.of(ctx).pop();
                  passwordController.dispose();

                  final success = await ref
                      .read(authProvider.notifier)
                      .withdrawUser(password);

                  if (!success && context.mounted) {
                    final errorMsg =
                        ref.read(authProvider).errorMessage ?? '탈퇴에 실패했습니다.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMsg),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('탈퇴하기'),
              ),
            ],
          );
        },
      ),
    );
  }
}
