class PhoneVerificationArguments {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String laundryServiceName;
  final String password;
  final String role;

  const PhoneVerificationArguments({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.laundryServiceName,
    required this.password,
    required this.role,
  });

  bool get isLaundry => role.trim().toLowerCase() == 'laundry';
  bool get isRider => role.trim().toLowerCase() == 'rider';

  String get displayName =>
      isLaundry ? laundryServiceName.trim() : fullName.trim();
}
