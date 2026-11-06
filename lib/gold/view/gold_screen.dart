import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_app/gold/cubit/cubit/gold_cubit.dart';
import 'package:gold_app/gold/cubit/cubit/gold_state.dart';

import '../model/gold_model.dart';


class GoldScreen extends StatelessWidget {
  const GoldScreen({super.key});

  Widget priceCard(String title, GoldModel gold) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text('Selling Price: ${gold.sellingPrice} EGP'),
            const SizedBox(height: 5),
            Text('Buying Price: ${gold.buyingPrice} EGP'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GoldCubit()..fetchGoldPrices(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gold Prices'),
          centerTitle: true,
        ),
        body: BlocBuilder<GoldCubit, GoldState>(
          builder: (context, state) {
            if (state is GoldLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is GoldError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        context.read<GoldCubit>().fetchGoldPrices();
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            if (state is GoldSuccess) {
              return RefreshIndicator(
                onRefresh: () {
                  return context.read<GoldCubit>().fetchGoldPrices();
                },
                child: ListView(
                  children: [
                    priceCard('Gold 21', state.goldPrices['21']!),
                    priceCard('Gold 24', state.goldPrices['24']!),
                    priceCard('Gold 18', state.goldPrices['18']!),
                  ],
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}