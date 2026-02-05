import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'otp_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSendOtp() async {
    String phone = _phoneController.text.trim();
    // Sanitize: Remove everything except digits
    phone = phone.replaceAll(RegExp(r'\D'), '');
    
    // If it's a 12 digit number starting with 91, take last 10
    if (phone.length == 12 && phone.startsWith('91')) {
      phone = phone.substring(2);
    }

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final response = await ref.read(authStateProvider.notifier).sendOtp(phone);
    setState(() => _isLoading = false);

    if (response.success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpPage(phoneNumber: phone, debugOtp: response.debugOtp),
        ),
      );
    } else if (mounted) {
      final errorMessage = response.message ?? 'Failed to send OTP';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Details', 
            textColor: Colors.white,
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Connection Error'),
                  content: Text('Technical details: $errorMessage'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.shield_outlined, size: 64, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                'Farmer Shield',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
              ),
              const Text('Secure your harvest with AI intelligence'),
              const SizedBox(height: 48),
              const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Enter 10-digit number',
                  prefixText: '+91 ',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSendOtp,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Get OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
