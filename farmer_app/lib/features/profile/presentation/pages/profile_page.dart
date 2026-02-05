import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:farmer_app/features/profile/data/profile_model.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Profile Controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  
  // Bank Controllers
  late TextEditingController _holderController;
  late TextEditingController _bankController;
  late TextEditingController _accountController;
  late TextEditingController _ifscController;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    _nameController = TextEditingController(text: profile?.name);
    _addressController = TextEditingController(text: profile?.address);
    _holderController = TextEditingController(text: profile?.accountHolderName);
    _bankController = TextEditingController(text: profile?.bankName);
    _accountController = TextEditingController(text: profile?.accountNumber);
    _ifscController = TextEditingController(text: profile?.ifscCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _holderController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success = await ref.read(profileRepositoryProvider).updateProfile(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      state: ref.read(userProfileProvider).value!.state,
      district: ref.read(userProfileProvider).value!.district,
      village: ref.read(userProfileProvider).value!.village,
      accountHolderName: _holderController.text.trim(),
      bankName: _bankController.text.trim(),
      accountNumber: _accountController.text.trim(),
      ifscCode: _ifscController.text.trim(),
    );

    setState(() => _isLoading = false);
    if (success) {
      ref.invalidate(userProfileProvider);
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Personal Information'),
              _buildField('Full Name', _nameController, Icons.person, enabled: _isEditing),
              _buildField('Address', _addressController, Icons.location_on, enabled: _isEditing),
              const SizedBox(height: 32),
              _buildSectionTitle('Bank Details (For Claim Payouts)'),
              const Text('Ensure these details are correct to receive insurance payouts direct to your account.', 
                style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              _buildField('Account Holder Name', _holderController, Icons.badge, enabled: _isEditing),
              _buildField('Bank Name', _bankController, Icons.account_balance, enabled: _isEditing),
              _buildField('Account Number', _accountController, Icons.numbers, enabled: _isEditing),
              _buildField('IFSC Code', _ifscController, Icons.password, enabled: _isEditing),
              
              const SizedBox(height: 48),
              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: !enabled,
          fillColor: enabled ? Colors.white : Colors.grey.shade50,
        ),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }
}
