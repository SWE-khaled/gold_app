import 'package:gold_app/gold/model/gold_model.dart';


abstract class GoldState {}

class GoldInitial extends GoldState {}

class GoldLoading extends GoldState {}

class GoldSuccess extends GoldState {
  final Map<String, GoldModel> goldPrices;

  GoldSuccess(this.goldPrices);
}

class GoldError extends GoldState {
  final String message;

  GoldError(this.message);
}