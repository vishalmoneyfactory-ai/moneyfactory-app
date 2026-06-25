import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../../core/utils/formatters.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.courseId,
    this.isBundle = false,
  });

  final String courseId;
  final bool isBundle;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CFPaymentGatewayService _cfPaymentGatewayService = CFPaymentGatewayService();
  final _coupon = TextEditingController();
  final _referral = TextEditingController();
  Map<String, dynamic>? _course;
  num _discount = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _cfPaymentGatewayService.setCallback(_verifyPayment, _onError);
    _load();
  }

  @override
  void dispose() {
    _coupon.dispose();
    _referral.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = widget.isBundle
        ? await api.bundle()
        : await api.course(widget.courseId);
    setState(() => _course = widget.isBundle ? data['bundle'] : data['course']);
  }

  Future<void> _applyCoupon() async {
    try {
      final res = await api.validateCoupon({
        'code': _coupon.text.trim(),
        'courseId': widget.courseId,
        'isBundle': widget.isBundle,
      });
      setState(() => _discount = res['discountAmount'] ?? 0);
      _snack('Discount Applied: -${money(_discount)}', AppColors.success);
    } catch (_) {
      _snack('Invalid or expired coupon', AppColors.error);
    }
  }

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      final order = await api.createOrder({
        'courseId': widget.courseId,
        'isBundle': widget.isBundle,
        'couponCode': _coupon.text.trim().isEmpty ? null : _coupon.text.trim(),
        'referralCode': _referral.text.trim().isEmpty ? null : _referral.text.trim(),
      });

      final environment = order['environment'] == 'PRODUCTION' ? CFEnvironment.PRODUCTION : CFEnvironment.SANDBOX;

      var session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(order['orderId'])
          .setPaymentSessionId(order['paymentSessionId'])
          .build();

      var theme = CFThemeBuilder()
          .setNavigationBarBackgroundColorColor("#FFD700")
          .setNavigationBarTextColor("#000000")
          .setButtonBackgroundColor("#FFD700")
          .setButtonTextColor("#000000")
          .setPrimaryTextColor("#FFFFFF")
          .build();

      var dropCheckoutPayment = CFDropCheckoutPaymentBuilder()
          .setSession(session)
          .setTheme(theme)
          .build();

      _cfPaymentGatewayService.doPayment(dropCheckoutPayment);

    } catch (e) {
      if (e is DioException &&
          e.response?.data is Map &&
          e.response?.data['code'] == 'PHONE_REQUIRED') {
        _snack(
          'Please add your phone number before purchasing a course.',
          AppColors.error,
        );
        if (mounted) context.push('/complete-profile');
        return;
      }
      _snack(e.toString(), AppColors.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _verifyPayment(String orderId) async {
    try {
      await api.verifyPayment({
        'orderId': orderId,
      });
      if (!mounted) return;
      _snack('Payment successful', AppColors.success);
      context.go('/learning');
    } catch (e) {
      _snack('Payment verification failed on server', AppColors.error);
    }
  }

  void _onError(dynamic error, String orderId) {
    _snack(error.getMessage() ?? 'Payment failed', AppColors.error);
  }

  void _snack(String text, Color color) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    final originalPrice = (_course?['originalPrice'] ?? _course?['price'] ?? 0) as num;
    final price = (_course?['effectivePrice'] ?? _course?['price'] ?? 0) as num;
    final total = (price - _discount).clamp(0, price);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _course == null
          ? Center(
              child: CircularProgressIndicator(color: AppColors.themeGold(context)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _box([
                  Text(
                    _course!['title'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _course!['shortDescription'] ?? '',
                    style: TextStyle(color: AppColors.mutedText(context)),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _coupon,
                        decoration: const InputDecoration(
                          labelText: 'Coupon code',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 92,
                      child: GoldButton(
                        label: 'Apply',
                        onPressed: _applyCoupon,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _referral,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Referral Code (optional)',
                  ),
                ),
                const SizedBox(height: 14),
                _box([
                  if (_course?['hasOffer'] == true) ...[
                    _line('Original', money(originalPrice), mutedStrike: true),
                    _line(
                      'Offer ${_course?['offerPercent'] ?? 0}% off',
                      '-${money(_course?['offerDiscount'] ?? (originalPrice - price))}',
                      color: AppColors.themeSuccess(context),
                    ),
                    _line('Offer price', money(price), color: AppColors.themeGold(context)),
                  ] else
                    _line('Original', money(price)),
                  _line(
                    'Coupon discount',
                    '-${money(_discount)}',
                    color: AppColors.themeSuccess(context),
                  ),
                  Divider(color: AppColors.line(context)),
                  _line('Total', money(total), color: AppColors.themeGold(context)),
                ]),
                if (!widget.isBundle) ...[
                  const SizedBox(height: 14),
                  _box([
                    Text(
                      'Get ALL 6 courses for Rs 4999',
                      style: TextStyle(
                        color: AppColors.themeGold(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GoldButton(
                      label: 'Upgrade to Bundle',
                      onPressed: () => context.push('/checkout/bundle?bundle=true'),
                    ),
                  ]),
                ],
                const SizedBox(height: 20),
                GoldButton(
                  label: _loading ? 'Preparing...' : 'Pay with Cashfree',
                  onPressed: _loading ? null : _pay,
                ),
              ],
            ),
    );
  }

  Widget _box(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.line(context)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
  Widget _line(
    String label,
    String value, {
    Color? color,
    bool mutedStrike = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(label, style: TextStyle(color: AppColors.mutedText(context))),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color ??
                (mutedStrike
                    ? AppColors.mutedText(context)
                    : AppColors.text(context)),
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w800,
            decoration: mutedStrike ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.mutedText(context),
          ),
        ),
      ],
    ),
  );
}
