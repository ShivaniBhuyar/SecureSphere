class UserProfile {
  String name;
  String email;
  String protectionStatus;

  UserProfile({
    required this.name,
    required this.email,
    this.protectionStatus = 'Basic Protection',
  });
}
