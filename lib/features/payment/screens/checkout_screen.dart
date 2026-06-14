import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/gold_button.dart';

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
  late final Razorpay _razorpay;
  final _coupon = TextEditingController();
  final _referral = TextEditingController();
  Map<String, dynamic>? _course;
  Map<String, dynamic>? _order;
  num _discount = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _success);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _error);
    _load();
  }

  @override
  void dispose() {
    _razorpay.clear();
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
      _order = order;
      _razorpay.open({
        'key': order['keyId'].toString().isNotEmpty
            ? order['keyId']
            : api.razorpayKey(),
        'amount': order['amount'] * 100,
        'currency': 'INR',
        'name': 'Money Factory',
        'description': _course?['title'] ?? 'Course Purchase',
        'order_id': order['orderId'],
        'prefill': const {'contact': '', 'email': ''},
        'theme': {'color': '#FFD700'},
      });
    } catch (e) {
      if (e is DioException && e.response?.data is Map && e.response?.data['code'] == 'PHONE_REQUIRED') {
        _snack('Please add your phone number before purchasing a course.', AppColors.error);
        if (mounted) context.push('/complete-profile');
        return;
      }
      _snack(e.toString(), AppColors.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _success(PaymentSuccessResponse response) async {
    await api.verifyPayment({
      'razorpayOrderId': response.orderId ?? _order?['orderId'],
      'razorpayPaymentId': response.paymentId,
      'razorpaySignature': response.signature,
    });
    if (!mounted) return;
    _snack('Payment successful', AppColors.success);
    context.go('/learning');
  }

  void _error(PaymentFailureResponse response) =>
      _snack(response.message ?? 'Payment failed', AppColors.error);
  void _snack(String text, Color color) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    final originalPrice =
        (_course?['originalPrice'] ?? _course?['price'] ?? 0) as num;
    final price = (_course?['effectivePrice'] ?? _course?['price'] ?? 0) as num;
    final total = (price - _discount).clamp(0, price);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _course == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
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
                    style: const TextStyle(color: AppColors.muted),
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
                      color: AppColors.success,
                    ),
                    _line('Offer price', money(price), color: AppColors.gold),
                  ] else
                    _line('Original', money(price)),
                  _line(
                    'Coupon discount',
                    '-${money(_discount)}',
                    color: AppColors.success,
                  ),
                  const Divider(color: AppColors.border),
                  _line('Total', money(total), color: AppColors.gold),
                ]),
                if (!widget.isBundle) ...[
                  const SizedBox(height: 14),
                  _box([
                    const Text(
                      'Get ALL 6 courses for Rs 4999',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GoldButton(
                      label: 'Upgrade to Bundle',
                      onPressed: () =>
                          context.push('/checkout/bundle?bundle=true'),
                    ),
                  ]),
                ],
                const SizedBox(height: 20),
                GoldButton(
                  label: _loading ? 'Preparing...' : 'Pay with Razorpay',
                  onPressed: _loading ? null : _pay,
                ),
              ],
            ),
    );
  }

  Widget _box(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
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
        Text(label, style: const TextStyle(color: AppColors.muted)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color ?? (mutedStrike ? AppColors.muted : AppColors.white),
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w800,
            decoration: mutedStrike ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.muted,
          ),
        ),
      ],
    ),
  );
}
