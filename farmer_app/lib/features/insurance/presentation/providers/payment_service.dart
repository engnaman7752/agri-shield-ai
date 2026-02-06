import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/features/insurance/data/insurance_models.dart';
import 'package:farmer_app/features/profile/presentation/providers/profile_provider.dart';

final paymentServiceProvider = Provider((ref) => PaymentService(ref));

// Set to true for demo mode - bypasses Razorpay
const bool kDemoPaymentMode = true;

class PaymentService {
  final Ref _ref;
  Razorpay? _razorpay;
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
    _onSuccess = onSuccess;
    _onError = onError;

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
    
    var options = {
      'key': order.razorpayKeyId,
      'amount': order.amount,
      'name': 'Farmer Shield',
      'order_id': order.orderId,
      'description': 'Insurance Premium Payment',
      'prefill': {
        'contact': profile?.phone ?? '',
        'name': profile?.name ?? '',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      print('Razorpay Error: $e');
      _onError?.call(PaymentFailureResponse(0, 'Razorpay Error: $e', null));
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_onSuccess != null) _onSuccess!(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_onError != null) _onError!(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
  }

  void dispose() {
    _razorpay?.clear();
  }
}
