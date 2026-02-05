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
  final _addressController = TextEditingController();

  StateModel? _selectedState;
  DistrictModel? _selectedDistrict;
  VillageModel? _selectedVillage;

  @override
  Widget build(BuildContext context) {
    final statesAsync = ref.watch(statesProvider);
    final registrationState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: SingleChildScrollView(
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
              
              const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Enter your name'),
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),
              
              const Text('Full Address', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(hintText: 'House no, Street name...'),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 20),
              
              // State Dropdown
              const Text('State', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              statesAsync.when(
                data: (states) => DropdownButtonFormField<StateModel>(
                  value: _selectedState,
                  items: states.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedState = val;
                      _selectedDistrict = null;
                      _selectedVillage = null;
                    });
                  },
                  decoration: const InputDecoration(hintText: 'Select State'),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading states: $e'),
              ),
              const SizedBox(height: 20),
              
              // District Dropdown
              if (_selectedState != null) ...[
                const Text('District', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ref.watch(districtsProvider(_selectedState!.id)).when(
                  data: (districts) => DropdownButtonFormField<DistrictModel>(
                    value: _selectedDistrict,
                    items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedDistrict = val;
                        _selectedVillage = null;
                      });
                    },
                    decoration: const InputDecoration(hintText: 'Select District'),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading districts: $e'),
                ),
                const SizedBox(height: 20),
              ],
              
              // Village Dropdown
              if (_selectedDistrict != null) ...[
                const Text('Village', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ref.watch(villagesProvider(_selectedDistrict!.id)).when(
                  data: (villages) => DropdownButtonFormField<VillageModel>(
                    value: _selectedVillage,
                    items: villages.map((v) => DropdownMenuItem(value: v, child: Text(v.name))).toList(),
                    onChanged: (val) => setState(() => _selectedVillage = val),
                    decoration: const InputDecoration(hintText: 'Select Village'),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading villages: $e'),
                ),
                const SizedBox(height: 32),
              ],
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: registrationState.isLoading ? null : _submit,
                  child: registrationState.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Complete Registration'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null || _selectedDistrict == null || _selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select all locations')));
      return;
    }

    ref.read(profileProvider.notifier).register(
      phone: widget.phoneNumber,
      name: _nameController.text.trim(),
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
