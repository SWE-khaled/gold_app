import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gold_app/gold/cubit/cubit/gold_cubit.dart';
import 'package:gold_app/gold/view/gold_screen.dart';

class _IdleGoldCubit extends GoldCubit {
  @override
  Future<void> fetchGoldPrices() async {}
}

void main() {
  testWidgets('shows the gold loading indicator', (tester) async {
    final cubit = _IdleGoldCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(MaterialApp(home: GoldScreen(cubit: cubit)));

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.color, const Color(0xFFD9A441));
  });
}
