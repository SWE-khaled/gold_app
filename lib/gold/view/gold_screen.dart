import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/gold_config.dart';
import '../cubit/cubit/gold_cubit.dart';
import '../cubit/cubit/gold_state.dart';
import '../model/gold_model.dart';

const _backgroundColor = Color(0xFF0E0B08);
const _cardColor = Color(0xFF15110C);
const _goldColor = Color(0xFFE6C27A);
const _topGoldColor = Color(0xFFD9A441);
const _mutedColor = Color(0xFFA89F8E);
const _dividerColor = Color(0xFF2A2620);
const _upColor = Color(0xFF3DDC84);
const _downColor = Color(0xFFE57373);

class GoldScreen extends StatelessWidget {
  const GoldScreen({super.key, this.cubit});

  final GoldCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit case final goldCubit?) {
      return BlocProvider.value(value: goldCubit, child: const _GoldHomeView());
    }

    return BlocProvider(
      create: (_) => GoldCubit()..fetchGoldPrices(),
      child: const _GoldHomeView(),
    );
  }
}

class _GoldHomeView extends StatefulWidget {
  const _GoldHomeView();

  @override
  State<_GoldHomeView> createState() => _GoldHomeViewState();
}

class _GoldHomeViewState extends State<_GoldHomeView> {
  GoldModel? _ounce;
  String? _ounceError;
  DateTime? _lastUpdated;
  String? _comparisonError;
  final Map<String, int?> _directions = {};
  int _ounceRequestId = 0;

  void _onGoldSuccess(Map<String, GoldModel> prices) {
    final gold21 = prices['21'];
    if (gold21 == null) {
      return;
    }

    final cubit = context.read<GoldCubit>();
    final gold14 = GoldModel(
      buyingPrice: cubit.convertPrice(gold21.buyingPrice, 14),
      sellingPrice: cubit.convertPrice(gold21.sellingPrice, 14),
    );
    final gold18 =
        prices['18'] ??
        GoldModel(
          buyingPrice: cubit.convertPrice(gold21.buyingPrice, 18),
          sellingPrice: cubit.convertPrice(gold21.sellingPrice, 18),
        );
    final gramPrices = <String, GoldModel>{
      '14': gold14,
      '18': gold18,
      '21': gold21,
    };

    setState(() {
      _lastUpdated = DateTime.now().toLocal();
      _ounce = null;
      _ounceError = null;
      _comparisonError = null;
      _directions.clear();
    });

    unawaited(_loadOunceAndCompare(gramPrices));
  }

  Future<void> _loadOunceAndCompare(Map<String, GoldModel> gramPrices) async {
    final requestId = ++_ounceRequestId;
    final apiService = context.read<GoldCubit>().apiService;
    await _saveAndComparePrices({
      for (final entry in gramPrices.entries)
        entry.key: entry.value.sellingPrice,
    });

    try {
      final ounce = await apiService.getGoldPrice('ounce');
      if (!mounted || requestId != _ounceRequestId) {
        return;
      }

      setState(() {
        _ounce = ounce;
      });

      await _saveAndComparePrices({'ounce': ounce.sellingPrice});
    } catch (error) {
      if (mounted && requestId == _ounceRequestId) {
        setState(() {
          _ounceError = 'تعذر تحميل سعر الأوقية: $error';
        });
      }
    }
  }

  Future<void> _saveAndComparePrices(Map<String, double> prices) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final changes = <String, int?>{};

      for (final entry in prices.entries) {
        final key = 'gold_price_${entry.key}';
        final previousPrice = preferences.getDouble(key);
        changes[entry.key] =
            previousPrice == null || previousPrice == entry.value
            ? null
            : entry.value > previousPrice
            ? 1
            : -1;

        final saved = await preferences.setDouble(key, entry.value);
        if (!saved) {
          throw StateError('تعذر حفظ سعر الذهب ${entry.key}');
        }
      }

      if (mounted) {
        setState(() {
          _directions.addAll(changes);
          _comparisonError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _comparisonError = 'تعذر حفظ مقارنة الأسعار: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: BlocConsumer<GoldCubit, GoldState>(
          listener: (context, state) {
            if (state is GoldSuccess) {
              _onGoldSuccess(state.goldPrices);
            }
          },
          builder: (context, state) {
            if (state is GoldLoading || state is GoldInitial) {
              return const Center(
                child: CircularProgressIndicator(color: _topGoldColor),
              );
            }

            if (state is GoldError) {
              return _buildError(context, state.message);
            }

            if (state is GoldSuccess) {
              return _buildSuccess(context, state.goldPrices);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تعذر تحميل أسعار الذهب',
              style: GoogleFonts.cairo(
                color: _goldColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: _mutedColor, fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.read<GoldCubit>().fetchGoldPrices(),
              style: OutlinedButton.styleFrom(
                foregroundColor: _goldColor,
                side: const BorderSide(color: _topGoldColor),
              ),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, Map<String, GoldModel> prices) {
    final gold21 = prices['21'];
    if (gold21 == null) {
      return _buildError(context, 'بيانات الأسعار غير مكتملة');
    }

    final cubit = context.read<GoldCubit>();
    final gramPrices = <String, GoldModel>{
      '14': GoldModel(
        buyingPrice: cubit.convertPrice(gold21.buyingPrice, 14),
        sellingPrice: cubit.convertPrice(gold21.sellingPrice, 14),
      ),
      '18':
          prices['18'] ??
          GoldModel(
            buyingPrice: cubit.convertPrice(gold21.buyingPrice, 18),
            sellingPrice: cubit.convertPrice(gold21.sellingPrice, 18),
          ),
      '21': gold21,
    };

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, safeConstraints) {
          return RefreshIndicator(
            color: _topGoldColor,
            onRefresh: cubit.fetchGoldPrices,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, safeConstraints.maxHeight - 32),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: math.min(safeConstraints.maxWidth - 32, 700),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPriceCard(gramPrices),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _openSource,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              'المصدر: isagha.com',
                              style: GoogleFonts.cairo(
                                color: _mutedColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceCard(Map<String, GoldModel> gramPrices) {
    final dateText = _lastUpdated == null
        ? ''
        : DateFormat('d MMMM y - h:mm a', 'ar').format(_lastUpdated!);

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _dividerColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 3,
              decoration: const BoxDecoration(
                color: _topGoldColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'سعر الذهب الآن',
                    style: GoogleFonts.cairo(
                      color: _goldColor,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: _upColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          dateText.isEmpty
                              ? 'جارٍ تحديث الأسعار'
                              : 'آخر تحديث: $dateText',
                          style: GoogleFonts.cairo(
                            color: _mutedColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildGrid(gramPrices),
                  if (_comparisonError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _comparisonError!,
                      style: GoogleFonts.cairo(color: _downColor, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(Map<String, GoldModel> gramPrices) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildPriceCell(
                  title: 'عيار 14',
                  model: gramPrices['14']!,
                  direction: _directions['14'],
                  isOunce: false,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _buildPriceCell(
                  title: 'عيار 18',
                  model: gramPrices['18']!,
                  direction: _directions['18'],
                  isOunce: false,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: _dividerColor),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildPriceCell(
                  title: 'عيار 21',
                  model: gramPrices['21']!,
                  direction: _directions['21'],
                  isOunce: false,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _buildPriceCell(
                  title: 'أوقية الذهب',
                  model: _ounce,
                  direction: _directions['ounce'],
                  isOunce: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return const VerticalDivider(width: 1, thickness: 1, color: _dividerColor);
  }

  Widget _buildPriceCell({
    required String title,
    required GoldModel? model,
    required int? direction,
    required bool isOunce,
  }) {
    final buySpread = isOunce
        ? GoldConfig.ounceBuySpread
        : GoldConfig.gramBuySpread;
    final sellSpread = isOunce
        ? GoldConfig.ounceSellSpread
        : GoldConfig.gramSellSpread;
    final buyPrice = model == null ? null : model.buyingPrice - buySpread;
    final sellPrice = model == null ? null : model.sellingPrice + sellSpread;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: GoogleFonts.cairo(
                      color: _goldColor,
                      fontSize: isOunce ? 14 : 17,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (direction != null && direction != 0) ...[
                const SizedBox(width: 4),
                Icon(
                  direction > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: direction > 0 ? _upColor : _downColor,
                  size: 14,
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          _buildPriceLine('شراء', buyPrice, isOunce),
          const SizedBox(height: 8),
          _buildPriceLine('بيع', sellPrice, isOunce),
          if (isOunce && _ounceError != null) ...[
            const SizedBox(height: 4),
            Text(
              _ounceError!,
              style: GoogleFonts.cairo(color: _downColor, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceLine(String label, double? price, bool isOunce) {
    return Row(
      children: [
        Text(label, style: GoogleFonts.cairo(color: _mutedColor, fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOunce)
                      Text(
                        r'$',
                        style: GoogleFonts.cairo(
                          color: _mutedColor,
                          fontSize: 14,
                        ),
                      ),
                    if (!isOunce) ...[
                      Text(
                        'ج.م',
                        style: GoogleFonts.cairo(
                          color: _mutedColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      price == null ? '—' : _formatPrice(price),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Future<void> _openSource() async {
    final opened = await launchUrl(
      Uri.parse("https://market.isagha.com/prices"),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر فتح موقع المصدر', style: GoogleFonts.cairo()),
        ),
      );
    }
  }
}
