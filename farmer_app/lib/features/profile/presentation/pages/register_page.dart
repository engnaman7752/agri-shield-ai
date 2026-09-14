import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/core/providers/location_providers.dart';
import 'package:farmer_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:farmer_app/core/models/location_models.dart';

class RegisterPage extends ConsumerStatefulWidget {
  final String phoneNumber;

  const RegisterPage({super.key, required this.phoneNumber});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _addressController = TextEditingController();

  StateModel? _selectedState;
  DistrictModel? _selectedDistrict;
  VillageModel? _selectedVillage;

  bool _isAadhaarVerified = false;
  bool _isVerifyingAadhaar = false;

  /// Simulate Aadhaar verification (always passes for demo)
  Future<void> _verifyAadhaar() async {
    final aadhaar = _aadhaarController.text.trim();
    if (aadhaar.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 12-digit Aadhaar number')),
      );
      return;
    }

    setState(() => _isVerifyingAadhaar = true);

    // Simulate UIDAI API call (1.5s delay)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    setState(() {
      _isVerifyingAadhaar = false;
      _isAadhaarVerified = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Aadhaar verified by UIDAI'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statesAsync = ref.watch(statesProvider);
    final registrationState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.red.shade100, // DEBUG: Physical layout proof
      appBar: AppBar(title: const Text('Complete Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help us secure your journey',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Enter your details to register as a farmer.'),
                const SizedBox(height: 32),
                
                // ======== AADHAAR SECTION ========
                const Text('Aadhaar Number *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _aadhaarController,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  enabled: !_isAadhaarVerified,
                  decoration: InputDecoration(
                    hintText: '12-digit Aadhaar number',
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: _isAadhaarVerified 
                      ? const Icon(Icons.verified, color: Colors.green)
                      : null,
                  ),
                  onChanged: (_) {
                    if (_isAadhaarVerified) setState(() => _isAadhaarVerified = false);
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Aadhaar is required';
                    if (v.trim().length != 12) return 'Must be 12 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isVerifyingAadhaar || _isAadhaarVerified ? null : _verifyAadhaar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAadhaarVerified ? Colors.green : Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: _isVerifyingAadhaar 
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isAadhaarVerified ? 'Verified ✅' : 'Verify'),
                  ),
                ),
                if (_isAadhaarVerified) ...[
                  const SizedBox(height: 8),
                  const Text('✅ Identity verified via UIDAI database', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 20),

                // ======== NAME ========
                const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),
                
                // ======== ADDRESS ========
                const Text('Full Address', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: 'House no, Street name...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 2,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
                ),
                const SizedBox(height: 20),
                
                // State Dropdown
                const Text('State', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                statesAsync.when(
                  data: (states) {
                    if (states.isEmpty) return const Text('No states available at the moment.');
                    if (_selectedState != null && !states.any((s) => s.id == _selectedState!.id)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _selectedState = null);
                      });
                    }
                    return DropdownButtonFormField<int>(
                      value: _selectedState?.id,
                      items: states.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) {
                        setState(() {
                          if (val != null) _selectedState = states.firstWhere((s) => s.id == val);
                          _selectedDistrict = null;
                          _selectedVillage = null;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Select State',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) => v == null ? 'State is required' : null,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading states: $e', style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 20),
                
                // District Dropdown
                if (_selectedState != null) ...[
                  const Text('District', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ref.watch(districtsProvider(_selectedState!.id)).when(
                    data: (districts) {
                      if (districts.isEmpty) return const Text('No districts found for this state.');
                      if (_selectedDistrict != null && !districts.any((d) => d.id == _selectedDistrict!.id)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _selectedDistrict = null);
                        });
                      }
                      return DropdownButtonFormField<int>(
                        value: _selectedDistrict?.id,
                        items: districts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                        onChanged: (val) {
                          setState(() {
                            if (val != null) _selectedDistrict = districts.firstWhere((d) => d.id == val);
                            _selectedVillage = null;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Select District',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (v) => v == null ? 'District is required' : null,
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading districts: $e', style: const TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Village Dropdown
                if (_selectedDistrict != null) ...[
                  const Text('Village', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ref.watch(villagesProvider(_selectedDistrict!.id)).when(
                    data: (villages) {
                      if (villages.isEmpty) return const Text('No villages found for this district.');
                      if (_selectedVillage != null && !villages.any((v) => v.id == _selectedVillage!.id)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _selectedVillage = null);
                        });
                      }
                      return DropdownButtonFormField<int>(
                        value: _selectedVillage?.id,
                        items: villages.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedVillage = villages.firstWhere((v) => v.id == val));
                        },
                        decoration: InputDecoration(
                          hintText: 'Select Village',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (v) => v == null ? 'Village is required' : null,
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading villages: $e', style: const TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 32),
                ],
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (registrationState.isLoading || !_isAadhaarVerified) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: registrationState.isLoading 
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : Text(_isAadhaarVerified ? 'Complete Registration' : 'Verify Aadhaar First', style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAadhaarVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify your Aadhaar first')));
      return;
    }
    if (_selectedState == null || _selectedDistrict == null || _selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select all locations')));
      return;
    }

    ref.read(profileProvider.notifier).register(
      phone: widget.phoneNumber,
      name: _nameController.text.trim(),
      aadhaarNumber: _aadhaarController.text.trim(),
      address: _addressController.text.trim(),
      stateRegion: _selectedState!.name,
      district: _selectedDistrict!.name,
      village: _selectedVillage!.name,
    ).then((_) {
      if (ref.read(profileProvider).hasError == false) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else {
        final error = ref.read(profileProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });
  }
}
