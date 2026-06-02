import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_models.dart';
import '../models/vehicle_model.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';
  static const _userNameKey = 'auth_user_name';
  static const _userEmailKey = 'auth_user_email';
  static const _walletBalanceKey = 'auth_wallet_balance';
  static const _isAdminKey = 'auth_is_admin';
  static const _activeRentalKey = 'active_rental_session';
  static const _storage = FlutterSecureStorage();

  static String get baseUrl =>
      kIsWeb ? 'http://localhost:9000' : 'http://10.0.2.2:9000';

  // ─── Auth ────────────────────────────────────────────────────────────────

  static Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    String? idNumber,
    String? drivingLicenseNumber,
  }) async {
    final res = await _post('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'phone': phone,
      if (idNumber != null && idNumber.trim().isNotEmpty) 'idNumber': idNumber.trim(),
      if (drivingLicenseNumber != null && drivingLicenseNumber.trim().isNotEmpty)
        'drivingLicenseNumber': drivingLicenseNumber.trim(),
    });
    final auth = AuthResponse.fromJson(res);
    await _persistAuth(auth);
    return auth;
  }

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    final auth = AuthResponse.fromJson(res);
    await _persistAuth(auth);
    return auth;
  }

  static Future<void> _persistAuth(AuthResponse auth) async {
    await _storage.write(key: _tokenKey, value: auth.token);
    await _storage.write(key: _userIdKey, value: auth.user.id);
    await _storage.write(key: _userNameKey, value: auth.user.name);
    await _storage.write(key: _userEmailKey, value: auth.user.email);
    await _storage.write(
        key: _walletBalanceKey, value: auth.user.walletBalance.toString());
    await _storage.write(key: _isAdminKey, value: auth.user.isAdmin.toString());
  }

  static Future<void> logout() async {
    await clearActiveRental();
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _walletBalanceKey);
    await _storage.delete(key: _isAdminKey);
  }

  static Future<String?> getToken() => _storage.read(key: _tokenKey);
  static Future<String?> getUserId() => _storage.read(key: _userIdKey);
  static Future<String?> getUserName() => _storage.read(key: _userNameKey);
  static Future<String?> getUserEmail() => _storage.read(key: _userEmailKey);

  static Future<bool> getIsAdmin() async =>
      (await _storage.read(key: _isAdminKey)) == 'true';

  static Future<double> getWalletBalance() async {
    final val = await _storage.read(key: _walletBalanceKey);
    if (val == null) return 0.0;
    return double.tryParse(val) ?? 0.0;
  }


  // ─── OTP Verification ─────────────────────────────────────────────────────

  static Future<void> sendEmailOtp(String email) async {
    await _post('/api/otp/send-email', {'email': email});
  }

  static Future<void> sendSmsOtp(String phoneNumber) async {
    await _post('/api/otp/send', {'phoneNumber': phoneNumber});
  }

  static Future<bool> verifyEmailOtp(String email, String code) async {
    final res = await _post('/api/otp/verify-email', {
      'email': email,
      'code': code,
    });
    return (res['verified'] as bool?) ?? false;
  }

  static Future<bool> verifySmsOtp(String phoneNumber, String code) async {
    final res = await _post('/api/otp/verify', {
      'phoneNumber': phoneNumber,
      'code': code,
    });
    return (res['verified'] as bool?) ?? false;
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  static Future<UserProfile> getProfile() async {
    final userId = await getUserId();
    if (userId == null) throw ApiException('Not logged in.');
    final res = await _getMap('/api/users/$userId/profile');
    return UserProfile.fromJson(res);
  }

  static Future<UserProfile> updateProfile({
    required String name,
    String? phone,
    String? profileImageUrl,
  }) async {
    final userId = await getUserId();
    if (userId == null) throw ApiException('Not logged in.');
    final body = <String, dynamic>{'name': name};
    if (phone != null) body['phone'] = phone;
    if (profileImageUrl != null) body['profileImageUrl'] = profileImageUrl;
    final res = await _put('/api/users/$userId/profile', body);
    // تحديث الاسم في التخزين المحلي
    await _storage.write(key: _userNameKey, value: name);
    return UserProfile.fromJson(res);
  }

  // ─── Vehicles ─────────────────────────────────────────────────────────────

  static Future<List<Vehicle>> getVehicles() async {
    final list = await _getList('/api/vehicles');
    return list.map((e) => Vehicle.fromJson(e)).toList();
  }

  static Future<List<Vehicle>> getAvailableVehicles() async {
    final list = await _getList('/api/vehicles/available');
    return list.map((e) => Vehicle.fromJson(e)).toList();
  }

  static Future<Vehicle> getVehicle(String vehicleId) async {
    final res = await _getMap('/api/vehicles/$vehicleId');
    return Vehicle.fromJson(res);
  }

  // ─── Trips ────────────────────────────────────────────────────────────────

  /// Atomically confirms payment, creates the reservation, and enables the digital key.
  static Future<Trip> startTrip({
    required String vehicleId,
    required int duration,
    required String durationType,
    required double baseFare,
    required double bookingFee,
    required double tax,
    required double totalFare,
    required String paymentMethod,
  }) async {
    final userId = await getUserId();
    if (userId == null) throw ApiException('Not logged in.');
    final res = await _post('/api/trips/start', {
      'userId': int.parse(userId),
      'vehicleId': int.parse(vehicleId),
      'duration': duration,
      'durationType': durationType,
      'baseFare': baseFare,
      'bookingFee': bookingFee,
      'tax': tax,
      'totalFare': totalFare,
      'paymentMethod': paymentMethod,
    });
    return Trip.fromJson(res);
  }

  /// End an in-progress trip and receive the calculated fare.
  static Future<Trip> endTrip(String tripId) async {
    final res = await _put('/api/trips/$tripId/end', {
      'endTime': DateTime.now().toUtc().toIso8601String(),
    });
    return Trip.fromJson(res);
  }

  /// Fetch all trips for the currently logged-in user.
  static Future<List<Trip>> getMyTrips() async {
    final userId = await getUserId();
    if (userId == null) return [];
    final list = await _getList('/api/trips?userId=$userId');
    return list.map((e) => Trip.fromJson(e)).toList();
  }

  static Future<Trip?> getActiveTrip() async {
    final userId = await getUserId();
    if (userId == null) return null;
    try {
      final res = await _getMap('/api/trips/active?userId=$userId');
      return Trip.fromJson(res);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<void> saveActiveRental({
    required Map<String, dynamic> car,
    required Trip trip,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeRentalKey, jsonEncode({
      'car': car,
      'tripId': trip.id,
      'duration': trip.duration,
      'durationType': trip.durationType,
      'startTime': trip.startTime.toIso8601String(),
      'scheduledEndTime': trip.scheduledEndTime?.toIso8601String(),
      'paymentStatus': trip.paymentStatus,
      'digitalKeyEnabled': trip.digitalKeyEnabled,
      'paidTotal': trip.totalFare,
    }));
  }

  static Future<Map<String, dynamic>?> getSavedActiveRental() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeRentalKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await prefs.remove(_activeRentalKey);
      return null;
    }
  }

  static Future<void> clearActiveRental() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeRentalKey);
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  static Future<List<AppNotification>> getNotifications() async {
    final userId = await getUserId();
    if (userId == null) return [];
    final list = await _getList('/api/notifications?userId=$userId');
    return list.map((e) => AppNotification.fromJson(e)).toList();
  }

  static Future<int> getUnreadCount() async {
    final userId = await getUserId();
    if (userId == null) return 0;
    final res = await _getMap('/api/notifications/unread-count?userId=$userId');
    return (res['count'] as num?)?.toInt() ?? 0;
  }

  static Future<void> markNotificationRead(String id) async {
    await _putNoBody('/api/notifications/$id/read');
  }

  static Future<void> markAllNotificationsRead() async {
    final userId = await getUserId();
    if (userId == null) return;
    await _putNoBody('/api/notifications/read-all?userId=$userId');
  }

  // ─── Wallet ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getWallet() async {
    final userId = await getUserId();
    if (userId == null) throw ApiException('Not logged in.');
    final res = await _getMap('/api/wallet?userId=$userId');
    final balance = (res['balance'] as num?)?.toDouble() ?? 0.0;
    final rawTx = (res['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final transactions = rawTx.map((e) => WalletTransaction.fromJson(e)).toList();
    return {'balance': balance, 'transactions': transactions};
  }

  static Future<Map<String, dynamic>> topUp(
      double amount, String paymentMethod) async {
    final userId = await getUserId();
    if (userId == null) throw ApiException('Not logged in.');
    final res = await _post('/api/wallet/topup?userId=$userId', {
      'amount': amount,
      'paymentMethod': paymentMethod,
    });
    // تحديث الرصيد في التخزين المحلي
    final newBalance = (res['balance'] as num?)?.toDouble() ?? 0.0;
    await _storage.write(
        key: _walletBalanceKey, value: newBalance.toString());
    return res;
  }

  // ─── Digital Key ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getKeyStatus(String tripId) async {
    return _getMap('/api/digitalkey/status/$tripId');
  }

  static Future<void> unlockCar(String tripId) async {
    await _post('/api/digitalkey/unlock', {'tripId': int.parse(tripId)});
  }

  static Future<void> lockCar(String tripId) async {
    await _post('/api/digitalkey/lock', {'tripId': int.parse(tripId)});
  }

  // ─── Admin ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAdminStats() =>
      _getMap('/api/admin/stats');

  // Users (admin)
  static Future<List<Map<String, dynamic>>> adminGetUsers({String? search}) {
    final q = (search != null && search.trim().isNotEmpty)
        ? '?search=${Uri.encodeQueryComponent(search.trim())}'
        : '';
    return _getList('/api/users$q');
  }

  static Future<void> adminCreateUser(Map<String, dynamic> body) =>
      _post('/api/users', body);

  static Future<void> adminUpdateUser(String id, Map<String, dynamic> body) =>
      _put('/api/users/$id', body);

  static Future<void> adminDeleteUser(String id) => _delete('/api/users/$id');

  static Future<void> adminActivateUser(String id) =>
      _putNoBody('/api/admin/users/$id/activate');

  static Future<void> adminDeactivateUser(String id) =>
      _putNoBody('/api/admin/users/$id/deactivate');

  // Vehicles (admin)
  static Future<List<Vehicle>> adminGetVehicles({String? search}) async {
    final q = (search != null && search.trim().isNotEmpty)
        ? '?search=${Uri.encodeQueryComponent(search.trim())}'
        : '';
    final list = await _getList('/api/vehicles$q');
    return list.map((e) => Vehicle.fromJson(e)).toList();
  }

  static Future<void> adminCreateVehicle(Map<String, dynamic> body) =>
      _post('/api/vehicles', body);

  static Future<void> adminUpdateVehicle(String id, Map<String, dynamic> body) =>
      _put('/api/vehicles/$id', body);

  static Future<void> adminDeleteVehicle(String id) =>
      _delete('/api/vehicles/$id');

  /// Hide a vehicle from the user map (admin only).
  static Future<void> adminHideVehicle(String id) =>
      _putNoBody('/api/vehicles/$id/hide');

  /// Restore a vehicle to the user map (admin only).
  static Future<void> adminShowVehicle(String id) =>
      _putNoBody('/api/vehicles/$id/show');

  // Pricing (admin/all)
  static Future<List<Map<String, dynamic>>> getPricing() =>
      _getList('/api/pricing');

  static Future<void> updatePricing(String id, Map<String, dynamic> body) =>
      _put('/api/pricing/$id', body);

  // Audit logs (admin)
  static Future<List<Map<String, dynamic>>> getAuditLogs(
      {String? entityType, int limit = 200}) {
    final params = <String>['limit=$limit'];
    if (entityType != null && entityType.isNotEmpty) {
      params.add('entityType=$entityType');
    }
    return _getList('/api/admin/audit?${params.join('&')}');
  }

  // Telematics / remote control (admin). command: lock | unlock | engine/start | engine/kill
  static Future<void> adminVehicleControl(String vehicleId, String command) =>
      _post('/api/admin/vehicles/$vehicleId/$command', {});

  // ─── Low-level helpers ────────────────────────────────────────────────────

  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> _getList(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await authHeaders();
    http.Response res;
    try {
      res = await http.get(uri, headers: headers);
    } on SocketException {
      throw ApiException('Network error. Check your connection.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      if (decoded is! List) throw ApiException('Unexpected response format.');
      return decoded.cast<Map<String, dynamic>>();
    }
    throw ApiException(
      res.body.isNotEmpty ? res.body : 'Request failed (${res.statusCode}).',
      statusCode: res.statusCode,
    );
  }

  static Future<Map<String, dynamic>> _getMap(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await authHeaders();
    http.Response res;
    try {
      res = await http.get(uri, headers: headers);
    } on SocketException {
      throw ApiException('Network error. Check your connection.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(
      res.body.isNotEmpty ? res.body : 'Request failed (${res.statusCode}).',
      statusCode: res.statusCode,
    );
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    http.Response res;
    try {
      final headers = await authHeaders();
      res = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
    } on SocketException {
      throw ApiException('Network error. Check your connection.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(
      res.body.isNotEmpty ? res.body : 'Request failed (${res.statusCode}).',
      statusCode: res.statusCode,
    );
  }

  static Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await authHeaders();
    http.Response res;
    try {
      res = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
    } on SocketException {
      throw ApiException('Network error. Check your connection.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(
      res.body.isNotEmpty ? res.body : 'Request failed (${res.statusCode}).',
      statusCode: res.statusCode,
    );
  }

  static Future<void> _delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await authHeaders();
    http.Response res;
    try {
      res = await http.delete(uri, headers: headers);
    } on SocketException {
      throw ApiException('Network error. Check your connection.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ApiException(
      res.body.isNotEmpty ? res.body : 'Request failed (${res.statusCode}).',
      statusCode: res.statusCode,
    );
  }

  /// PUT بدون body (مثل mark-as-read) — يقبل 204 No Content
  static Future<void> _putNoBody(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await authHeaders();
    http.Response res;
    try {
      res = await http.put(uri, headers: headers);
    } on SocketException {
      throw ApiException('Network error. Check your connection.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ApiException(
      res.body.isNotEmpty ? res.body : 'Request failed (${res.statusCode}).',
      statusCode: res.statusCode,
    );
  }
}
