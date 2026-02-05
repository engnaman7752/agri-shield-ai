import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:farmer_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:farmer_app/features/insurance/data/insurance_repository.dart';
import 'package:farmer_app/features/insurance/data/crop_model.dart';
import 'package:farmer_app/features/insurance/data/insurance_models.dart';

final insuranceRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return InsuranceRepository(dio);
});

final cropsProvider = FutureProvider<List<CropModel>>((ref) async {
  return ref.watch(insuranceRepositoryProvider).getCrops();
});

final myPoliciesProvider = FutureProvider<List<InsuranceResponse>>((ref) async {
  return ref.watch(insuranceRepositoryProvider).getMyPolicies();
});

final activePoliciesProvider = FutureProvider<List<InsuranceResponse>>((ref) async {
  return ref.watch(insuranceRepositoryProvider).getActivePolicies();
});

final insuranceApplicationProvider = StateNotifierProvider<InsuranceNotifier, AsyncValue<PaymentOrderResponse?>>((ref) {
  return InsuranceNotifier(ref.watch(insuranceRepositoryProvider), ref);
});

class InsuranceNotifier extends StateNotifier<AsyncValue<PaymentOrderResponse?>> {
  final InsuranceRepository _repository;
  final Ref _ref;

  InsuranceNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> apply(InsuranceApplicationRequest request) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.applyForInsurance(request);
      if (response != null) {
        state = AsyncValue.data(response);
      } else {
        state = AsyncValue.error('Application failed', StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> confirmPayment(PaymentSuccessResponse response) async {
    state = const AsyncValue.loading();
    try {
      final success = await _repository.confirmPayment(
        razorpayPaymentId: response.paymentId!,
        razorpayOrderId: response.orderId!,
        razorpaySignature: response.signature!,
      );
      if (success) {
        state = const AsyncValue.data(null);
        _ref.invalidate(myPoliciesProvider);
        return true;
      }
      state = AsyncValue.error('Payment confirmation failed', StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}
