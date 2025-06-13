import 'package:cloud_firestore/cloud_firestore.dart';

class Voucher {
  final String id;
  final String code;
  final DateTime createdAt;
  final DateTime expiryDate;
  final bool isUsed;
  final int discountPercentage;

  Voucher({
    required this.id,
    required this.code,
    required this.createdAt,
    required this.expiryDate,
    required this.isUsed,
    required this.discountPercentage,
  });

  factory Voucher.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Voucher(
      id: doc.id,
      code: data['code'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      isUsed: data['isUsed'] ?? false,
      discountPercentage: (data['discountPercentage'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'createdAt': createdAt,
      'expiryDate': expiryDate,
      'isUsed': isUsed,
      'discountPercentage': discountPercentage,
    };
  }

  bool get isValid {
    return !isUsed && DateTime.now().isBefore(expiryDate);
  }
} 