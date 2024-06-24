import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:http/http.dart' as http;
import 'package:mrt_wallet/app/core.dart';

class HttpCaller {
  static const Map<String, String> applicationJson = {
    "Accept": "application/json"
  };
  static Future<MethodResult<T>> get<T>(String uri,
      {Map<String, String>? header,
      Duration timeout = const Duration(seconds: 30)}) async {
    final client = http.Client();
    try {
      return MethodCaller.httpCaller<T>(() async {
        try {
          return await client
              .get(Uri.parse(uri), headers: header)
              .timeout(timeout);
        } catch (e) {
          rethrow;
        }
      });
    } finally {
      client.close();
    }
  }

  static Future<MethodResult<T>> post<T>(
    String uri, {
    Map<String, String>? header,
    Object? body,
  }) async {
    final client = http.Client();
    Object? data;
    if (body != null && (body is Map || body is List)) {
      data = StringUtils.fromJson(body);
    }
    try {
      return MethodCaller.httpCaller(() async =>
          await client.post(Uri.parse(uri), headers: header, body: data));
    } finally {
      client.close();
    }
  }
}
