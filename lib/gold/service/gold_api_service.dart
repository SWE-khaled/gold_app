import 'package:dio/dio.dart';
import '../model/gold_model.dart';

class GoldApiService {
  final Dio dio = Dio();

  Future<GoldModel> getGoldPrice(String type) async {
    try {
      final response = await dio.get(
        'https://market.isagha.com/api/last-price',
        queryParameters: {
          'type': type,
          'priceFor': 'gold',
        },
      );

      // اطبع بيانات الطلب والرد
      print('REQUEST URL: ${response.realUri}');
      print('STATUS CODE: ${response.statusCode}');
      print('API RESPONSE: ${response.data}');

      final data = response.data;

      if (data['code'].toString() != '1') {
        throw Exception(data['message'] ?? 'Price not found');
      }

      return GoldModel.fromJson(data);

    } on DioException catch (e) {
      print('DIO ERROR: ${e.message}');
      print('ERROR RESPONSE: ${e.response?.data}');

      throw Exception('Connection Error');
    } catch (e) {
      print('GENERAL ERROR: $e');
      rethrow;
    }
  }
}