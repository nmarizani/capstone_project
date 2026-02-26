import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../auth/auth_service.dart';
import '../home_pages/welcome_page.dart';
import 'privacy_policy_page.dart';
import 'password_management_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy And Policy',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildSettingsItem(
                icon: Icons.lock_outline,
                title: 'Password Manager',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PasswordManagerScreen()),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildSettingsItem(
                icon: Icons.logout,
                title: 'Logout Of Account',
                onTap: () => _showLogoutDialog(context),
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.danger : AppColors.primary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.danger : AppColors.textDark,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textLight,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Midwife avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medical_services_outlined,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              'Midwife',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'are you sure you want to log out?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.secondary),
                      foregroundColor: AppColors.textDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WelcomeScreen()),
                          (_) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Yes, Logout'),
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