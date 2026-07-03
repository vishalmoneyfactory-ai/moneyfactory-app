import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final dioProvider = DioClient();

class DioClient {
  DioClient() {
    dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000/api', connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 15), sendTimeout: const Duration(seconds: 8)));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'jwt');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          await storage.delete(key: 'jwt');
        }
        handler.next(e);
      },
    ));
    dio.interceptors.add(PrettyDioLogger(requestBody: false, responseBody: false));
  }

  late final Dio dio;
  final storage = const FlutterSecureStorage();
}
