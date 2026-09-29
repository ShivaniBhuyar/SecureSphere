import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileService extends ChangeNotifier {
  late UserProfile _profile;

  UserProfile get profile => _profile;

  ProfileService() {
    _profile = UserProfile(
      name: 'SecureSphere User',
      email: 'user@example.com',
    );
    _loadProfile();
  }

  void _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('profile_name');
    final email = prefs.getString('profile_email');
    if (name != null || email != null) {
      _profile.name = name ?? _profile.name;
      _profile.email = email ?? _profile.email;
      notifyListeners();
    }
  }

  void updateProfile({String? name, String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      _profile.name = name;
      prefs.setString('profile_name', name);
    }
    if (email != null) {
      _profile.email = email;
      prefs.setString('profile_email', email);
    }
    notifyListeners();
  }
}
