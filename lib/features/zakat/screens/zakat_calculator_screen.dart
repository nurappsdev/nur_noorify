import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/core/theme/brand_colors.dart';

/// "Zakat Calculator" — lets the user enter the value of their assets (gold,
/// silver, cash, future deposits) and any loans they have given out, then
/// reports the zakat payable. Zakat is 2.5% of net zakatable assets, but only
/// when those assets meet or exceed the nisab threshold. Everything is computed
/// locally with no network access.
class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  // Nisab per currency, valued on 06/06/2026 (silver-based threshold). The BDT
  // figure is authoritative; the others are its equivalent in each currency.
  static const _nisabDate = '06/06/2026';
  static const _currencies = <({String label, String symbol, double nisab})>[
    (label: 'BDT ৳', symbol: '৳', nisab: 178500),
    (label: 'USD \$', symbol: '\$', nisab: 1487),
    (label: 'SAR ﷼', symbol: '﷼', nisab: 5578),
    (label: 'INR ₹', symbol: '₹', nisab: 127500),
  ];

  late final _nisabController = TextEditingController(
    text: _formatAmount(_currencies.first.nisab),
  );
  final _goldController = TextEditingController();
  final _silverController = TextEditingController();
  final _cashController = TextEditingController();
  final _depositController = TextEditingController();
  final _loanController = TextEditingController();

  String _currency = _currencies.first.label;

  // One focus node per amount field so the field's text can switch color on
  // focus/blur (brand color while editing, black once it loses focus).
  late final Map<TextEditingController, FocusNode> _focusNodes = {
    for (final c in [
      _nisabController,
      _goldController,
      _silverController,
      _cashController,
      _depositController,
      _loanController,
    ])
      c: FocusNode(),
  };

  ({String label, String symbol, double nisab}) get _selected =>
      _currencies.firstWhere((c) => c.label == _currency);

  @override
  void initState() {
    super.initState();
    for (final node in _focusNodes.values) {
      node.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.removeListener(_onFocusChange);
      node.dispose();
    }
    _nisabController.dispose();
    _goldController.dispose();
    _silverController.dispose();
    _cashController.dispose();
    _depositController.dispose();
    _loanController.dispose();
    super.dispose();
  }

  /// Formats a whole-number amount with thousands separators (e.g. 178500 ->
  /// "178,500"). The Nisab field is shown this way and [_parse] strips the
  /// commas back out before computing.
  String _formatAmount(double value) {
    final digits = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '')) ?? 0;

  void _calculate() {
    final assets =
        _parse(_goldController) +
        _parse(_silverController) +
        _parse(_cashController) +
        _parse(_depositController) +
        _parse(_loanController);
    final nisab = _parse(_nisabController);
    final totalAssets = nisab + assets;
    final totalZakat = totalAssets * 0.025;

    _showResultDialog(totalAssets, totalZakat);
  }

  void _showResultDialog(double totalAssets, double totalZakat) {
    final symbol = _selected.symbol;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandColors.screenBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Zakat Calculation',
          style: TextStyle(
            color: BrandColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _resultRow('Total Assets', '${_formatAmount(totalAssets)} $symbol'),
            SizedBox(height: 12.h),
            _resultRow(
              'Total Zakat (2.5%)',
              '${totalZakat.toStringAsFixed(2)} $symbol',
              isZakat: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: BrandColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, {bool isZakat = false}) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isZakat ? BrandColors.tintBackground : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: BrandColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: BrandColors.textSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isZakat ? BrandColors.primaryDark : BrandColors.textPrimary,
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final symbol = _selected.symbol;
    return Scaffold(
      backgroundColor: BrandColors.screenBackground,
      appBar: AppBar(
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Calculate Your Zakat Easily'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            _label('Currency', required: true),
            SizedBox(height: 6.h),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: _fieldDecoration(),
              items: _currencies
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c.label,
                      child: Text(c.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _currency = value;
                  _nisabController.text = _formatAmount(_selected.nisab);
                });
              },
            ),
            SizedBox(height: 16.h),
            _label('Nisab (updated $_nisabDate)'),
            SizedBox(height: 6.h),
            _amountField(_nisabController),
            SizedBox(height: 20.h),
            _sectionCard(symbol),
            SizedBox(height: 20.h),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: BrandColors.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              onPressed: _calculate,
              child: const Text('Calculate Zakat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String symbol) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 16.h),
      decoration: BoxDecoration(
        color: BrandColors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Assets',
              style: TextStyle(
                color: BrandColors.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          _field('Value of Gold ($symbol)', _goldController),
          _field('Value of Silver ($symbol)', _silverController),
          _field('Cash in hand and in bank accounts ($symbol)', _cashController),
          _field(
            'Deposited for some future purpose, e.g. Hajj ($symbol)',
            _depositController,
          ),
          _field('Given out in loans ($symbol)', _loanController, last: true),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          SizedBox(height: 6.h),
          _amountField(controller),
        ],
      ),
    );
  }

  Widget _amountField(TextEditingController controller) {
    final node = _focusNodes[controller]!;
    return TextFormField(
      controller: controller,
      focusNode: node,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: TextStyle(
        color: node.hasFocus ? BrandColors.primaryDark : Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: _fieldDecoration(hint: '0'),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: BrandColors.textPrimary,
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ]
            : null,
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: BrandColors.card,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: BrandColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: BrandColors.primary, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: BrandColors.border),
      ),
    );
  }
}
