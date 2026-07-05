import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dio_client.dart';

class ApiService {
  ApiService(this._client);

  final DioClient _client;

  Future<List<dynamic>> courses() async =>
      (await _client.dio.get('/courses')).data['courses'] as List<dynamic>;
  Future<Map<String, dynamic>> bundle() async =>
      (await _client.dio.get('/courses/bundle')).data as Map<String, dynamic>;
  Future<Map<String, dynamic>> course(String id) async =>
      (await _client.dio.get('/courses/$id')).data as Map<String, dynamic>;
  Future<List<dynamic>> courseVideos(String id) async =>
      (await _client.dio.get('/courses/$id/videos')).data['videos']
          as List<dynamic>;
  Future<Map<String, dynamic>> unlockFreeCourse(String id) async =>
      (await _client.dio.post('/courses/$id/unlock')).data
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> me() async =>
      (await _client.dio.get('/auth/me')).data['user'] as Map<String, dynamic>;
  Future<List<dynamic>> progressAll() async =>
      (await _client.dio.get('/progress/all')).data['progress']
          as List<dynamic>;
  Future<List<dynamic>> progressCourse(String id) async =>
      (await _client.dio.get('/progress/course/$id')).data['progress']
          as List<dynamic>;
  Future<List<dynamic>> legal() async =>
      (await _client.dio.get('/legal')).data['pages'] as List<dynamic>;
  Future<Map<String, dynamic>> settings() async =>
      (await _client.dio.get('/settings')).data['settings']
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> earnVideo() async =>
      (await _client.dio.get('/settings/earn-video')).data
          as Map<String, dynamic>;
  Future<List<dynamic>> banners() async =>
      (await _client.dio.get('/banners')).data['banners'] as List<dynamic>;
  Future<Map<String, dynamic>> streamUrl(String videoId) async =>
      (await _client.dio.get('/videos/$videoId/stream-url')).data
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body) async =>
      (await _client.dio.put('/auth/me', data: body)).data['user']
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> uploadProfileImage(String path) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(path),
    });
    return (await _client.dio.post(
          '/auth/me/profile-image',
          data: form,
        )).data['user']
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removeProfileImage() async =>
      (await _client.dio.delete('/auth/me/profile-image')).data['user']
          as Map<String, dynamic>;
  Future<void> deleteAccount() async =>
      await _client.dio.delete('/auth/me');
  Future<Map<String, dynamic>> validateCoupon(
    Map<String, dynamic> body,
  ) async =>
      (await _client.dio.post('/coupons/validate', data: body)).data
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> body) async =>
      (await _client.dio.post('/payments/create-order', data: body)).data
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> body) async =>
      (await _client.dio.post('/payments/verify', data: body)).data
          as Map<String, dynamic>;
  Future<void> updateProgress(Map<String, dynamic> body) async =>
      _client.dio.post('/progress/update', data: body);
  Future<void> review(String courseId, int rating, String comment) async =>
      _client.dio.put(
        '/reviews/course/$courseId',
        data: {'rating': rating, 'comment': comment},
      );
  String razorpayKey() => dotenv.env['RAZORPAY_KEY_ID'] ?? '';
  String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final apiBase = _client.dio.options.baseUrl;
    final origin = apiBase.endsWith('/api')
        ? apiBase.substring(0, apiBase.length - 4)
        : apiBase;
    return '$origin$path';
  }
}

final api = ApiService(dioProvider);

bool isAuthError(Object err) =>
    err is DioException && err.response?.statusCode == 401;
