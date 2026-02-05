import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:farmer_app/features/profile/presentation/pages/register_page.dart';
import '../providers/auth_provider.dart';

class OtpPage extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String? debugOtp;

  const OtpPage({super.key, required this.phoneNumber, this.debugOtp});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  bool _isLoading = false;

  Future<void> _handleVerify(String code) async {
    setState(() => _isLoading = true);
    final response = await ref.read(authStateProvider.notifier).verifyOtp(
          widget.phoneNumber,
          code,
        );
    setState(() => _isLoading = false);

    if (response.success && mounted) {
      if (response.requiresRegistration) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterPage(phoneNumber: widget.phoneNumber),
          ),
        );
      } else {
        // Navigate to Dashboard
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Account')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text('Enter OTP sent to +91 ${widget.phoneNumber}'),
            const SizedBox(height: 24),
            Pinput(
              length: 6,
              onCompleted: _handleVerify,
              defaultPinTheme: PinTheme(
                width: 56,
                height: 56,
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (widget.debugOtp != null)
              Text('DEBUG OTP: ${widget.debugOtp}', style: const TextStyle(color: Colors.red)),
            const Spacer(),
            ElevatedButton(
              onPressed: () {}, // Handled by pinput completion
              child: const Text('Verify OTP'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
