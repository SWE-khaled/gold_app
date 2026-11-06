class GoldModel {
  final double sellingPrice;
  final double buyingPrice;

  GoldModel({
    required this.sellingPrice,
    required this.buyingPrice,
  });

  factory GoldModel.fromJson(Map<String, dynamic> json) {
    return GoldModel(
      sellingPrice: double.parse(
        json['selling_price'].toString(),
      ),
      buyingPrice: double.parse(
        json['buying_price'].toString(),
      ),
    );
  }
}