import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../model/gold_model.dart';

class GoldApiService {
  final Dio dio = Dio();

  Future<GoldModel> getGoldPrice(String type) async {
    try {
      final response = await dio.get(
        'https://market.isagha.com/api/last-price',
        queryParameters: {'type': type, 'priceFor': 'gold'},
      );

      developer.log(
        'Request URL: ${response.realUri}\n'
        'Status code: ${response.statusCode}\n'
        'API response: ${response.data}',
        name: 'GoldApiService',
      );

      final data = response.data;

      if (data['code'].toString() != '1') {
        throw Exception(data['message'] ?? 'Price not found');
      }
      return GoldModel.fromJson(data);
    } on DioException catch (e) {
      developer.log(
        'Dio request failed: ${e.message}\n'
        'Response: ${e.response?.data}',
        name: 'GoldApiService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw Exception('Connection Error');
    } catch (e) {
      developer.log(
        'Gold price request failed',
        name: 'GoldApiService',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
}
