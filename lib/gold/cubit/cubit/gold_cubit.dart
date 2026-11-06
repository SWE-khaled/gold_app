import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_app/gold/model/gold_model.dart';
import 'package:gold_app/gold/service/gold_api_service.dart' show GoldApiService;


import 'gold_state.dart';

class GoldCubit extends Cubit<GoldState> {
  GoldCubit() : super(GoldInitial());

  final GoldApiService apiService = GoldApiService();

  Future<void> fetchGoldPrices() async {
    emit(GoldLoading());

    try {
      // عيار 21 هو الأساس
      final gold21 = await apiService.getGoldPrice('21');

      // محاولة جلب عيار 24 و18
      GoldModel? gold24;
      GoldModel? gold18;

      try {
        gold24 = await apiService.getGoldPrice('24');
      } catch (_) {}

      try {
        gold18 = await apiService.getGoldPrice('18');
      } catch (_) {}

      // حساب الأسعار في حالة عدم توفرها
      gold24 ??= GoldModel(
        sellingPrice: convertPrice(gold21.sellingPrice, 24),
        buyingPrice: convertPrice(gold21.buyingPrice, 24),
      );

      gold18 ??= GoldModel(
        sellingPrice: convertPrice(gold21.sellingPrice, 18),
        buyingPrice: convertPrice(gold21.buyingPrice, 18),
      );

      emit(
        GoldSuccess({
          '21': gold21,
          '24': gold24,
          '18': gold18,
        }),
      );
    } catch (e) {
      emit(GoldError(e.toString()));
    }
  }

  double convertPrice(double price21, int karat) {
    final converted = (price21 * karat) / 21;

    final whole = converted.floor();
    final fraction = converted - whole;

    double result;

    if (fraction > 0.87) {
      result = whole + 1;
    } else if (fraction > 0.62) {
      result = whole + 0.75;
    } else if (fraction > 0.37) {
      result = whole + 0.5;
    } else if (fraction > 0.13) {
      result = whole + 0.25;
    } else {
      result = whole.toDouble();
    }

    return double.parse(result.toStringAsFixed(2));
  }
}