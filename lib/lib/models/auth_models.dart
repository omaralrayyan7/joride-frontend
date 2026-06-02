export 'vehicle_model.dart' show Vehicle;

class AuthUser {
  final String id;
  final String name;
  final String email;
  final double walletBalance;
  final bool isAdmin;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.walletBalance = 0.0,
    this.isAdmin = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      walletBalance: json['walletBalance'] != null
          ? (json['walletBalance'] as num).toDouble()
          : 0.0,
      isAdmin: (json['isAdmin'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'walletBalance': walletBalance,
        'isAdmin': isAdmin,
      };
}

class AuthResponse {
  final String token;
  final DateTime expiresAt;
  final AuthUser user;

  const AuthResponse({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class Trip {
  final String id;
  final int userId;
  final int vehicleId;
  final DateTime startTime;
  final DateTime? scheduledEndTime;
  final DateTime? endTime;
  final int duration;
  final String durationType;
  final double baseFare;
  final double bookingFee;
  final double tax;
  final double? totalFare;
  final String paymentMethod;
  final String paymentStatus;
  final int overtimeMinutes;
  final double overtimeFare;
  final String overtimePaymentStatus;
  final bool digitalKeyEnabled;
  final String status;

  const Trip({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.startTime,
    this.scheduledEndTime,
    this.endTime,
    this.duration = 0,
    this.durationType = '',
    this.baseFare = 0,
    this.bookingFee = 0,
    this.tax = 0,
    this.totalFare,
    this.paymentMethod = '',
    this.paymentStatus = 'Unpaid',
    this.overtimeMinutes = 0,
    this.overtimeFare = 0,
    this.overtimePaymentStatus = 'None',
    this.digitalKeyEnabled = false,
    required this.status,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'].toString(),
      userId: (json['userId'] as num).toInt(),
      vehicleId: (json['vehicleId'] as num).toInt(),
      startTime: DateTime.parse(json['startTime'] as String).toLocal(),
      scheduledEndTime: json['scheduledEndTime'] != null
          ? DateTime.parse(json['scheduledEndTime'] as String).toLocal()
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String).toLocal()
          : null,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      durationType: (json['durationType'] as String?) ?? '',
      baseFare: (json['baseFare'] as num?)?.toDouble() ?? 0,
      bookingFee: (json['bookingFee'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      totalFare: json['totalFare'] != null ? (json['totalFare'] as num).toDouble() : null,
      paymentMethod: (json['paymentMethod'] as String?) ?? '',
      paymentStatus: (json['paymentStatus'] as String?) ?? 'Unpaid',
      overtimeMinutes: (json['overtimeMinutes'] as num?)?.toInt() ?? 0,
      overtimeFare: (json['overtimeFare'] as num?)?.toDouble() ?? 0,
      overtimePaymentStatus: (json['overtimePaymentStatus'] as String?) ?? 'None',
      digitalKeyEnabled: (json['digitalKeyEnabled'] as bool?) ?? false,
      status: (json['status'] as String?) ?? 'Unknown',
    );
  }

  bool get isCompleted => status == 'Completed';
  bool get isActivePaid => status == 'InProgress' && paymentStatus == 'Paid' && digitalKeyEnabled;
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? idNumber;
  final String? drivingLicenseNumber;
  final String? profileImageUrl;
  final double walletBalance;
  final DateTime createdAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isLicenseVerified;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.idNumber,
    this.drivingLicenseNumber,
    this.profileImageUrl,
    required this.walletBalance,
    required this.createdAt,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isLicenseVerified = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      idNumber: json['idNumber'] as String?,
      drivingLicenseNumber: json['drivingLicenseNumber'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      walletBalance: json['walletBalance'] != null
          ? (json['walletBalance'] as num).toDouble()
          : 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isEmailVerified: (json['isEmailVerified'] as bool?) ?? false,
      isPhoneVerified: (json['isPhoneVerified'] as bool?) ?? false,
      isLicenseVerified: (json['isLicenseVerified'] as bool?) ?? false,
    );
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      title: json['title'] as String,
      body: json['body'] as String,
      type: (json['type'] as String?) ?? 'system',
      isRead: (json['isRead'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class WalletTransaction {
  final String id;
  final String userId;
  final String type;
  final String description;
  final double amount;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      type: (json['type'] as String?) ?? 'unknown',
      description: (json['description'] as String?) ?? '',
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
