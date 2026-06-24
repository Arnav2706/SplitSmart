class Group {
  final String id;
  final String name;
  final String inviteCode;
  final List<String> members;
  final String currency;
  final DateTime createdAt;

  const Group({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.members,
    this.currency = 'INR',
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['inviteCode'] as String,
      members: List<String>.from(json['members'] ?? []),
      currency: json['currency'] as String? ?? 'INR',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'inviteCode': inviteCode,
      'members': members,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
