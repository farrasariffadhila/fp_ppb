import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String address;
  final String email;
  final String endDate;
  final String movieId;
  final String name;
  final String phone;
  final String startDate;
  final int totalPrice;
  final String transactionId;
  final String userId;
  final String status;
  final bool isReturned;

  TransactionModel({
    required this.id,
    required this.address,
    required this.email,
    required this.endDate,
    required this.movieId,
    required this.name,
    required this.phone,
    required this.startDate,
    required this.totalPrice,
    required this.transactionId,
    required this.userId,
    required this.status,
    required this.isReturned,
  });

  factory TransactionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      address: data['address'] ?? '',
      email: data['email'] ?? '',
      endDate: data['endDate'] ?? '',
      movieId: data['movieId']?.toString() ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      startDate: data['startDate'] ?? '',
      totalPrice: (data['totalPrice'] as num?)?.toInt() ?? 0,
      transactionId: data['transactionId']?.toString() ?? '',
      userId: data['userID'] ?? '',
      status: data['status'] ?? 'waiting for confirmation',
      isReturned: data['isReturned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'email': email,
      'endDate': endDate,
      'movieId': movieId,
      'name': name,
      'phone': phone,
      'startDate': startDate,
      'totalPrice': totalPrice,
      'transactionId': transactionId,
      'userID': userId,
      'status': status,
      'isReturned': isReturned,
    };
  }
} 