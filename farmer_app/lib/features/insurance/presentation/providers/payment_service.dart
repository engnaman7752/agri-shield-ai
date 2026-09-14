import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/features/insurance/data/insurance_models.dart';
import 'package:farmer_app/features/profile/presentation/providers/profile_provider.dart';

final paymentServiceProvider = Provider((ref) => PaymentService(ref));

// Set to false to show the actual Razorpay checkout UI using test keys
const bool kDemoPaymentMode = false;

class PaymentService {
  final Ref _ref;
  Razorpay? _razorpay;
  PaymentOrderResponse? _currentOrder;
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onError;

  PaymentService(this._ref) {
    if (!kDemoPaymentMode) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  void startPayment({
    required PaymentOrderResponse order,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
  }) async {
    _currentOrder = order;
    _onSuccess = onSuccess;
    _onError = onError;

    print('=== PAYMENT SERVICE ===');
    print('Order ID: ${order.orderId}');
    print('Insurance ID: ${order.insuranceId}');
    print('Amount from API (in ₹): ${order.amount}');
    print('Currency: ${order.currency}');

    // Demo mode: simulate successful payment immediately
    if (kDemoPaymentMode) {
      print('Demo Mode: Simulating successful payment');
      await Future.delayed(const Duration(milliseconds: 500));

      // Create a mock success response
      final mockResponse = PaymentSuccessResponse(
        order.orderId,
        order.orderId,
        'demo_signature_${DateTime.now().millisecondsSinceEpoch}',
        {},
      );

      _handlePaymentSuccess(mockResponse);
      return;
    }

    // Real Razorpay payment
    final profile = await _ref.read(userProfileProvider.future);

    // Validate amount
    if (order.amount <= 0) {
      print('❌ Invalid amount: ${order.amount}');
      _onError?.call(
        PaymentFailureResponse(
          0,
          'Invalid payment amount: ₹${order.amount}',
          null,
        ),
      );
      return;
    }

    // Amount must be in paisa (smallest unit). Multiply by 100.
    // Razorpay expects amount as an integer in paisas
    final amountInPaisa = (order.amount * 100).toInt();

    print('Amount in Paisa: $amountInPaisa');
    print(
      'Amount verification: ${amountInPaisa / 100} = ₹${(amountInPaisa / 100).toStringAsFixed(2)}',
    );
    print('======================');

    var options = {
      'key': order.razorpayKeyId,
      // Note: We don't use 'order_id' because it's a simulated order (not created via Razorpay API)
      // In production, you would create a real order via Razorpay API first
      'amount': amountInPaisa,
      'name': 'Farmer Shield',
      'currency': 'INR',
      'description': 'Insurance Premium - ${order.insuranceId}',
      'prefill': {'contact': profile?.phone ?? '', 'name': profile?.name ?? ''},
      'theme': {'color': '#4CAF50'},
      'timeout': 600, // 10 minutes timeout
      'retry': {'enabled': true, 'max_count': 1},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      print('❌ Razorpay Error: $e');
      _onError?.call(
        PaymentFailureResponse(0, 'Failed to open Razorpay: $e', null),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('✓ PAYMENT SUCCESS');
    print('Payment ID: ${response.paymentId}');
    print('Order ID: ${response.orderId}');
    print('Signature: ${response.signature}');
    print('Insurance ID (from stored order): ${_currentOrder?.insuranceId}');
    if (_onSuccess != null) _onSuccess!(response);
  }

  String? getCurrentOrderInsuranceId() {
    return _currentOrder?.insuranceId;
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ PAYMENT ERROR');
    print('Code: ${response.code}');
    print('Message: ${response.message}');
    if (_onError != null) _onError!(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('📱 EXTERNAL WALLET');
    print('Wallet: ${response.walletName}');
    // Handle external wallet
  }

  void dispose() {
    _razorpay?.clear();
  }
}
