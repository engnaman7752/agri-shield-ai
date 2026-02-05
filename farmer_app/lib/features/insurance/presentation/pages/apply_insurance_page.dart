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
        isDemoMode: true, // Enabled for presentation
      );
      
      setState(() {
        _currentPosition = position;
        _isLocationVerified = result.$1;
        _distanceFromLand = result.$2;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location Error: $e')));
    } finally {
      setState(() => _isVerifyingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final cropsAsync = ref.watch(cropsProvider);
    final applicationState = ref.watch(insuranceApplicationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Insurance')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));
          
          final loc = (state: profile.state, district: profile.district, village: profile.village);
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
                      if (khasras.isEmpty) return const Text('No available land found in your village.');
                      return _buildKhasraSelector(khasras);
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
                      onPressed: (_selectedCrop == null || _selectedKhasra == null || !_isLocationVerified || applicationState.isLoading) 
                        ? null 
                        : _submitApplication,
                      child: applicationState.isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isLocationVerified ? 'Calculate Premium & Apply' : 'Verify Location First'),
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
        color: _isLocationVerified ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isLocationVerified ? Colors.green : Colors.orange),
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
                _isLocationVerified ? 'Location Verified' : 'Location Verification Required',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isLocationVerified ? Colors.green.shade800 : Colors.orange.shade800,
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
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
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
          items: khasras.map((k) => DropdownMenuItem(
            value: k,
            child: Text('Khasra: ${k.khasraNumber} (${k.areaAcres} Acres)'),
          )).toList(),
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
                  Text(crop.name, style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.green.shade800 : Colors.black87,
                  )),
                  Text(crop.nameHindi, style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.green.shade600 : Colors.grey,
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    final premium = _selectedKhasra!.areaAcres * _selectedCrop!.maxCoverage * (_selectedCrop!.premiumRate / 100);
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
            _buildSummaryRow('Coverage Amount', '₹${coverage.toStringAsFixed(0)}'),
            const Divider(),
            _buildSummaryRow('Premium Payable', '₹${premium.toStringAsFixed(2)}', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isBold ? 18 : 16,
          color: isBold ? Colors.blue.shade800 : Colors.black87,
        )),
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
        
        _paymentService.startPayment(
          order: order,
          onSuccess: (response) {
            ref.read(insuranceApplicationProvider.notifier).confirmPayment(response).then((success) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment Successful! Insurance Active.'), backgroundColor: Colors.green),
                );
                Navigator.of(context).pop(); // Return to dashboard
              }
            });
          },
          onError: (response) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
            );
          },
        );
      } else if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${state.error}')),
        );
      }
    });
  }
}
