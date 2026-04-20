class BusinessInfoModel {
  final String businessName;
  final String ownerName;
  final String phoneNumber;
  final String email;
  final String address;
  final String description;
  final bool pickupAvailable;
  final bool deliveryAvailable;

  const BusinessInfoModel({
    required this.businessName,
    required this.ownerName,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.description,
    this.pickupAvailable = true,
    this.deliveryAvailable = true,
  });

  BusinessInfoModel copyWith({
    String? businessName,
    String? ownerName,
    String? phoneNumber,
    String? email,
    String? address,
    String? description,
    bool? pickupAvailable,
    bool? deliveryAvailable,
  }) {
    return BusinessInfoModel(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      description: description ?? this.description,
      pickupAvailable: pickupAvailable ?? this.pickupAvailable,
      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'ownerName': ownerName,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'description': description,
      'pickupAvailable': pickupAvailable,
      'deliveryAvailable': deliveryAvailable,
    };
  }

  factory BusinessInfoModel.fromMap(Map<String, dynamic> map) {
    return BusinessInfoModel(
      businessName: map['businessName'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      description: map['description'] as String? ?? '',
      pickupAvailable: map['pickupAvailable'] as bool? ?? true,
      deliveryAvailable: map['deliveryAvailable'] as bool? ?? true,
    );
  }
}
