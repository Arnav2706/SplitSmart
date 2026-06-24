class AppUser {
  final String id;
  final String name;
  final String upiId;
  final String phone;
  final String avatarUrl;

  const AppUser({
    required this.id,
    required this.name,
    this.upiId = '',
    this.phone = '',
    this.avatarUrl = '',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      upiId: json['upiId'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'upiId': upiId,
      'phone': phone,
      'avatarUrl': avatarUrl,
    };
  }
}
