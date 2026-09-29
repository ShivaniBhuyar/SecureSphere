import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileService = Provider.of<ProfileService>(context);
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.royalBlue,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profileService.profile.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profileService.profile.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.safeGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield, color: AppTheme.safeGreen, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          profileService.profile.protectionStatus,
                          style: const TextStyle(color: AppTheme.safeGreen, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Sections
            _buildSectionHeader(context, 'ACCOUNT'),
            _buildListTile(
              context,
              icon: Icons.edit,
              title: 'Edit Profile',
              onTap: () => _showEditProfileDialog(context, profileService),
            ),
            
            const SizedBox(height: 24),
            
            _buildSectionHeader(context, 'PREFERENCES'),
            ListTile(
              leading: const Icon(Icons.dark_mode, color: AppTheme.softViolet),
              title: const Text('Appearance'),
              trailing: DropdownButton<ThemeMode>(
                value: themeService.themeMode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (ThemeMode? mode) {
                  if (mode != null) {
                    themeService.setThemeMode(mode);
                  }
                },
              ),
            ),
            _buildListTile(
              context,
              icon: Icons.mic,
              title: 'Voice Assistance',
              trailing: Switch(value: true, onChanged: (val) {}, activeTrackColor: AppTheme.royalBlue.withValues(alpha: 0.5), activeThumbColor: AppTheme.royalBlue),
            ),
            _buildListTile(
              context,
              icon: Icons.notifications,
              title: 'Notifications',
              trailing: Switch(value: true, onChanged: (val) {}, activeTrackColor: AppTheme.royalBlue.withValues(alpha: 0.5), activeThumbColor: AppTheme.royalBlue),
            ),
            
            const SizedBox(height: 24),
            
            _buildSectionHeader(context, 'PRIVACY & ABOUT'),
            _buildListTile(context, icon: Icons.privacy_tip, title: 'Privacy Information'),
            _buildListTile(context, icon: Icons.info, title: 'About SecureSphere', trailing: const Text('v1.0.0')),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.royalBlue),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(BuildContext context, ProfileService profileService) {
    final nameController = TextEditingController(text: profileService.profile.name);
    final emailController = TextEditingController(text: profileService.profile.email);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                profileService.updateProfile(
                  name: nameController.text,
                  email: emailController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }
}
