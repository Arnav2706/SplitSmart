class Settlement {
  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final int amount; // in paise
  final String status; // 'pending' | 'confirmed'
  final String? upiTxnRef;
  final DateTime createdAt;

  const Settlement({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    this.status = 'pending',
    this.upiTxnRef,
    required this.createdAt,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      amount: json['amount'] as int,
      status: json['status'] as String? ?? 'pending',
      upiTxnRef: json['upiTxnRef'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'status': status,
      'upiTxnRef': upiTxnRef,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
