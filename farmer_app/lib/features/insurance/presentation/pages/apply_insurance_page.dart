import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:farmer_app/core/utils/location_utils.dart';
import 'package:farmer_app/features/insurance/presentation/providers/insurance_provider.dart';
import 'package:farmer_app/core/providers/location_providers.dart';
import 'package:farmer_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:farmer_app/core/models/location_models.dart';
import 'package:farmer_app/features/insurance/data/crop_model.dart';
import 'package:farmer_app/features/insurance/data/insurance_models.dart';
import 'package:farmer_app/features/insurance/presentation/providers/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:farmer_app/l10n/app_localizations.dart';

class ApplyInsurancePage extends ConsumerStatefulWidget {
  const ApplyInsurancePage({super.key});

  @override
  ConsumerState<ApplyInsurancePage> createState() => _ApplyInsurancePageState();
}

class _ApplyInsurancePageState extends ConsumerState<ApplyInsurancePage> {
  final _formKey = GlobalKey<FormState>();
  late PaymentService _paymentService;

  @override
  void initState() {
    super.initState();
    _paymentService = ref.read(paymentServiceProvider);
  }

  @override
  void dispose() {
    // Note: In real app, might want to be careful with ref access in dispose
    // but here we just want to ensure Razorpay is cleared
    super.dispose();
  }

  CropModel? _selectedCrop;
  KhasraModel? _selectedKhasra;

  Position? _currentPosition;
  double? _distanceFromLand;
  bool _isVerifyingLocation = false;
  bool _isLocationVerified = false;

  Future<void> _verifyLocation() async {
    if (_selectedKhasra == null) return;

    setState(() => _isVerifyingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      final result = LocationUtils.isWithinBoundary(
        position,
        _selectedKhasra!.latitude,
        _selectedKhasra!.longitude,
        isDemoMode: false, // Real geofencing - 100m boundary
      );

      setState(() {
        _currentPosition = position;
        _isLocationVerified = result.$1;
        _distanceFromLand = result.$2;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location Error: $e')));
    } finally {
      setState(() => _isVerifyingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final cropsAsync = ref.watch(cropsProvider);
    final applicationState = ref.watch(insuranceApplicationProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.applyInsurance ?? 'Apply for Insurance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => Navigator.pushNamed(context, '/settings/language'),
            tooltip: 'Change Language',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Khasra List',
            onPressed: () {
              ref.invalidate(availableKhasraProvider);
              ref.invalidate(userProfileProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing land data...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null)
            return const Center(child: Text('Profile not found'));

          final loc = (
            state: profile.state,
            district: profile.district,
            village: profile.village,
          );
          final khasrasAsync = ref.watch(availableKhasraProvider(loc));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('1. Select Your Land (Khasra)'),
                  const SizedBox(height: 12),
                  khasrasAsync.when(
                    data: (khasras) {
                      return Column(
                        children: [
                          if (khasras.isNotEmpty) _buildKhasraSelector(khasras),
                          if (khasras.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No available land found in your village.',
                              ),
                            ),
                          const SizedBox(height: 12),
                          _buildAddKhasraButton(profile!),
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading land: $e'),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('2. Select Crop Type'),
                  const SizedBox(height: 12),
                  cropsAsync.when(
                    data: (crops) => _buildCropSelector(crops),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading crops: $e'),
                  ),

                  const SizedBox(height: 48),
                  if (_selectedCrop != null && _selectedKhasra != null) ...[
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    _buildLocationVerificationSection(),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_selectedCrop == null ||
                              _selectedKhasra == null ||
                              !_isLocationVerified ||
                              applicationState.isLoading)
                          ? null
                          : _submitApplication,
                      child: applicationState.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isLocationVerified
                                  ? 'Calculate Premium & Apply'
                                  : 'Verify Location First',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }

  Widget _buildLocationVerificationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isLocationVerified
            ? Colors.green.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isLocationVerified ? Colors.green : Colors.orange,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isLocationVerified ? Icons.check_circle : Icons.location_on,
                color: _isLocationVerified ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                _isLocationVerified
                    ? 'Location Verified'
                    : 'Location Verification Required',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isLocationVerified
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                ),
              ),
            ],
          ),
          if (!_isLocationVerified)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _distanceFromLand != null
                    ? 'You are ${(_distanceFromLand! / 1000).toStringAsFixed(2)}km away from this land. You must be at the farm to apply.'
                    : 'Please tap the button below to verify you are currently at the land.',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isVerifyingLocation ? null : _verifyLocation,
              child: _isVerifyingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify I am at the Farm'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }

  Widget _buildKhasraSelector(List<KhasraModel> khasras) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<KhasraModel>(
          isExpanded: true,
          value: _selectedKhasra,
          hint: const Text('Select Khasra Number'),
          items: khasras
              .map(
                (k) => DropdownMenuItem(
                  value: k,
                  child: Text(
                    'Khasra: ${k.khasraNumber} (${k.areaAcres} Acres)',
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() {
            _selectedKhasra = val;
            _isLocationVerified = false;
            _distanceFromLand = null;
          }),
        ),
      ),
    );
  }

  Widget _buildCropSelector(List<CropModel> crops) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: crops.length,
      itemBuilder: (context, index) {
        final crop = crops[index];
        final isSelected = _selectedCrop?.id == crop.id;
        return InkWell(
          onTap: () => setState(() => _selectedCrop = crop),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.green : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    crop.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.green.shade800
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    crop.nameHindi,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.green.shade600 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    final premium =
        _selectedKhasra!.areaAcres *
        _selectedCrop!.maxCoverage *
        (_selectedCrop!.premiumRate / 100);
    final coverage = _selectedKhasra!.areaAcres * _selectedCrop!.maxCoverage;

    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow(
              'Coverage Amount',
              '₹${coverage.toStringAsFixed(0)}',
            ),
            const Divider(),
            _buildSummaryRow(
              'Premium Payable',
              '₹${premium.toStringAsFixed(2)}',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isBold ? 18 : 16,
            color: isBold ? Colors.blue.shade800 : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _submitApplication() {
    final request = InsuranceApplicationRequest(
      khasraNumber: _selectedKhasra!.khasraNumber,
      cropType: _selectedCrop!.name,
      areaAcres: _selectedKhasra!.areaAcres,
      latitude: _selectedKhasra!.latitude,
      longitude: _selectedKhasra!.longitude,
    );

    ref.read(insuranceApplicationProvider.notifier).apply(request).then((_) {
      final state = ref.read(insuranceApplicationProvider);
      if (state.hasValue && state.value != null) {
        final order = state.value!;

        // Show confirmation dialog with CONFIRMED amount from backend
        _showPaymentConfirmationDialog(order);
      } else if (state.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
      }
    });
  }

  void _showPaymentConfirmationDialog(PaymentOrderResponse order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insurance ID: ${order.insuranceId.substring(0, 8)}...',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Coverage Amount: ₹${(_selectedKhasra!.areaAcres * _selectedCrop!.maxCoverage).toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount to Pay:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '₹${order.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '(This amount will be charged from Razorpay)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _proceedToPayment(order);
            },
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  void _proceedToPayment(PaymentOrderResponse order) {
    _paymentService.startPayment(
      order: order,
      onSuccess: (response) {
        _handlePaymentSuccess(order, response);
      },
      onError: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Failed: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _handlePaymentSuccess(
    PaymentOrderResponse order,
    PaymentSuccessResponse response,
  ) {
    // Show loading indicator while confirming payment
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Confirming payment...'),
              ],
            ),
          ),
        ),
      ),
    );

    ref
        .read(insuranceApplicationProvider.notifier)
        .confirmPayment(response, order.insuranceId, order.orderId)
        .then((result) {
          Navigator.pop(context); // Close loading dialog

          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '✓ Payment Successful! Your insurance is now PAID.',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            // Wait a moment then navigate back to dashboard
            // The policy list will refresh automatically when user returns
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) Navigator.of(context).pop();
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚠ Payment succeeded but confirmation failed: ${result.errorMessage ?? "Unknown error"}. Go back and retry.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 8),
              ),
            );
          }
        })
        .catchError((e) {
          Navigator.pop(context); // Close loading dialog
          print('❌ Payment error: $e');
          // Don't show error - user already knows payment might have succeeded
        });
  }

  // ========================================
  // ADD NEW KHASRA REQUEST
  // ========================================

  Widget _buildAddKhasraButton(dynamic profile) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAddKhasraDialog(profile),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Land not listed? Request to add new Khasra'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange.shade800,
          side: BorderSide(color: Colors.orange.shade300),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showAddKhasraDialog(dynamic profile) {
    final khasraController = TextEditingController();
    final areaController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_location_alt, color: Colors.orange),
              SizedBox(width: 8),
              Text('Add New Khasra'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your request will be sent to the Patwari for verification. Once approved, you can apply for insurance.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: khasraController,
                  decoration: const InputDecoration(
                    labelText: 'Khasra Number',
                    hintText: 'e.g., RN-301/1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: areaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Area (Acres)',
                    hintText: 'e.g., 5.50',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.gps_fixed, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'GPS coordinates will be captured from your current location',
                          style: TextStyle(fontSize: 11, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (khasraController.text.trim().isEmpty ||
                          areaController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      try {
                        // Get current GPS position
                        final position = await Geolocator.getCurrentPosition();

                        final success = await ref
                            .read(insuranceRepositoryProvider)
                            .submitKhasraRequest(
                              village: profile.village,
                              khasraNumber: khasraController.text.trim(),
                              areaAcres: double.parse(
                                areaController.text.trim(),
                              ),
                              latitude: position.latitude,
                              longitude: position.longitude,
                            );

                        if (ctx.mounted) Navigator.pop(ctx);

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '✅ Khasra request submitted! Awaiting Patwari verification.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to submit request'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
