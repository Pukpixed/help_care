// lib/screen/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes.dart';
import '../service/account_service.dart';
import '../color.dart'; // ใช้พาเลตสี AppColors

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ===== UI helpers =====
  String _initialsFrom(User? u) {
    final raw = (u?.displayName?.trim().isNotEmpty == true)
        ? u!.displayName!.trim()
        : (u?.email ?? '');
    if (raw.isEmpty) return 'U';
    final parts = raw.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0].isNotEmpty ? parts[0][0] : 'U').toUpperCase() +
          (parts[1].isNotEmpty ? parts[1][0] : '');
    }
    return raw[0].toUpperCase();
  }

  Widget _sectionTitle(String text, {Color? color}) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        color: color ?? AppColors.maroon,
        fontSize: 14,
        letterSpacing: 0.3,
      ),
    ),
  );

  Widget _tileCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    return Card(
      elevation: 3,
      color: AppColors.white,
      shadowColor: AppColors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.pink.withOpacity(0.6), width: 1),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.pinkLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.burgundy),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: TextStyle(color: AppColors.black.withOpacity(0.6)),
              ),
        trailing:
            trailing ??
            const Icon(Icons.chevron_right, color: AppColors.maroon),
        onTap: onTap,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'ลบบัญชีผู้ใช้',
              style: TextStyle(
                color: AppColors.maroon,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const Text(
              'การลบนี้ไม่สามารถย้อนกลับได้ ต้องการลบจริงหรือไม่?',
              style: TextStyle(color: AppColors.black),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ยกเลิก'),
              ),
              // ปุ่มแดงแบบไล่เฉด
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.red, AppColors.redDeep],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('ลบเลย'),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await AccountService.deleteCurrentUser(context);
      if (context.mounted) {
        Navigator.of(context).pop(); // ปิด progress
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.first, (_) => false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ลบบัญชีสำเร็จ')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // ปิด progress
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่า'),
        elevation: 0,
        backgroundColor: AppColors.maroon,
        foregroundColor: AppColors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.pinkLight, AppColors.pink],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // ===== Profile Header Card =====
              Card(
                elevation: 6,
                color: AppColors.white,
                shadowColor: AppColors.black.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: AppColors.pink.withOpacity(0.7),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // วงแหวนไฮไลต์
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.pink, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundImage: (user?.photoURL?.isNotEmpty == true)
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: (user?.photoURL?.isNotEmpty == true)
                              ? null
                              : Text(
                                  _initialsFrom(user),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: AppColors.burgundy,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName?.trim().isNotEmpty == true
                                  ? user!.displayName!
                                  : 'ผู้ใช้งาน',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '—',
                              style: TextStyle(
                                color: AppColors.black.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ปุ่มแก้ไขโปรไฟล์ (ปุ่มรองสีชมพู)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.pinkLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.pink, width: 1),
                        ),
                        child: IconButton(
                          tooltip: 'แก้ไขโปรไฟล์',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.editProfile,
                          ),
                          icon: const Icon(
                            Icons.edit,
                            color: AppColors.burgundy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _sectionTitle('โปรไฟล์'),
              _tileCard(
                icon: Icons.person_outline,
                title: 'แก้ไขโปรไฟล์',
                subtitle: 'ชื่อ, อายุ, เบอร์โทร, ที่อยู่ และรูปภาพ',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.editProfile),
              ),

              _sectionTitle('บัญชี'),
              _tileCard(
                icon: Icons.logout,
                title: 'ออกจากระบบ',
                subtitle: 'ออกจากอุปกรณ์นี้',
                iconColor: AppColors.maroon,
                onTap: () async {
                  await AccountService.signOut(context);
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.first, (_) => false);
                  }
                },
              ),

              _sectionTitle('อันตราย', color: AppColors.redDeep),
              // ===== Danger Zone Card =====
              Card(
                color: AppColors.white,
                elevation: 4,
                shadowColor: AppColors.black.withOpacity(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: AppColors.red.withOpacity(0.6),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.redDeep,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ลบบัญชีผู้ใช้',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.redDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'การลบนี้เป็นการลบข้อมูลทั้งหมดที่ผูกกับบัญชีนี้อย่างถาวร และไม่สามารถยกเลิกได้',
                        style: TextStyle(
                          color: AppColors.black.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: AbsorbPointer(
                          absorbing: user == null,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.red, AppColors.redDeep],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: user == null
                                  ? null
                                  : () => _confirmDelete(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor: AppColors.white,
                              ),
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('ลบบัญชีผู้ใช้'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
