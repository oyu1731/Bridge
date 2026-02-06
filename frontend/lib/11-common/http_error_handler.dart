import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// HTTP通信の結果を返すクラス
class HttpResponse<T> {
  final int statusCode;
  final T? data;
  final String? errorMessage;

  HttpResponse({required this.statusCode, this.data, this.errorMessage});

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// GETリクエストをラップする共通関数
/// onError: HTTP 400以上のエラー時のコールバック関数（statusCodeを受け取り）
Future<HttpResponse<String>> safeGet(
  Uri url, {
  Map<String, String>? headers,
  Function(int)? onError,
}) async {
  try {
    final response = await http.get(url, headers: headers);

    // HTTPエラーの場合、コールバック関数を呼び出し
    if (response.statusCode >= 400) {
      onError?.call(response.statusCode);
      return HttpResponse<String>(
        statusCode: response.statusCode,
        errorMessage: 'HTTP Error: ${response.statusCode}',
      );
    }

    return HttpResponse<String>(
      statusCode: response.statusCode,
      data: response.body,
    );
  } catch (e) {
    // ネットワークエラーなど例外はログのみ、エラーページ遷移はしない
    debugPrint('【Network Error】$e');
    return HttpResponse<String>(statusCode: -1, errorMessage: e.toString());
  }
}

/// POSTリクエストをラップする共通関数
/// onError: HTTP 400以上のエラー時のコールバック関数（statusCodeを受け取り）
Future<HttpResponse<String>> safePost(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  Function(int)? onError,
}) async {
  try {
    final response = await http.post(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );

    // HTTPエラーの場合、コールバック関数を呼び出し
    if (response.statusCode >= 400) {
      onError?.call(response.statusCode);
      return HttpResponse<String>(
        statusCode: response.statusCode,
        errorMessage: 'HTTP Error: ${response.statusCode}',
      );
    }

    return HttpResponse<String>(
      statusCode: response.statusCode,
      data: response.body,
    );
  } catch (e) {
    // ネットワークエラーなど例外はログのみ、エラーページ遷移はしない
    debugPrint('【Network Error】$e');
    return HttpResponse<String>(statusCode: -1, errorMessage: e.toString());
  }
}

/// PUTリクエストをラップする共通関数
/// onError: HTTP 400以上のエラー時のコールバック関数（statusCodeを受け取り）
Future<HttpResponse<String>> safePut(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
  Function(int)? onError,
}) async {
  try {
    final response = await http.put(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );

    // HTTPエラーの場合、コールバック関数を呼び出し
    if (response.statusCode >= 400) {
      onError?.call(response.statusCode);
      return HttpResponse<String>(
        statusCode: response.statusCode,
        errorMessage: 'HTTP Error: ${response.statusCode}',
      );
    }

    return HttpResponse<String>(
      statusCode: response.statusCode,
      data: response.body,
    );
  } catch (e) {
    // ネットワークエラーなど例外はログのみ、エラーページ遷移はしない
    debugPrint('【Network Error】$e');
    return HttpResponse<String>(statusCode: -1, errorMessage: e.toString());
  }
}

/// DELETEリクエストをラップする共通関数
/// onError: HTTP 400以上のエラー時のコールバック関数（statusCodeを受け取り）
Future<HttpResponse<String>> safeDelete(
  Uri url, {
  Map<String, String>? headers,
  Function(int)? onError,
}) async {
  try {
    final response = await http.delete(url, headers: headers);

    // HTTPエラーの場合、コールバック関数を呼び出し
    if (response.statusCode >= 400) {
      onError?.call(response.statusCode);
      return HttpResponse<String>(
        statusCode: response.statusCode,
        errorMessage: 'HTTP Error: ${response.statusCode}',
      );
    }

    return HttpResponse<String>(
      statusCode: response.statusCode,
      data: response.body,
    );
  } catch (e) {
    // ネットワークエラーなど例外はログのみ、エラーページ遷移はしない
    debugPrint('【Network Error】$e');
    return HttpResponse<String>(statusCode: -1, errorMessage: e.toString());
  }
}
