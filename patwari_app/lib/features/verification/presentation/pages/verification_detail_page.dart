import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patwari_app/features/verification/data/verification_models.dart';
import 'package:patwari_app/features/verification/presentation/providers/verification_provider.dart';

class FieldVerificationPage extends ConsumerStatefulWidget {
  final VerificationModel verification;

  const FieldVerificationPage({super.key, required this.verification});

  @override
  ConsumerState<FieldVerificationPage> createState() => _FieldVerificationPageState();
}

class _FieldVerificationPageState extends ConsumerState<FieldVerificationPage> {
  final _remarksController = TextEditingController();
  SensorModel? _selectedSensor;
  bool _isProcessing = false;

  void _process(String action) async {
    if (action == 'APPROVE' && _selectedSensor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please assign a sensor before approval')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final success = await ref.read(verificationRepositoryProvider).processVerification(
        verificationId: widget.verification.id,
        action: action,
        remarks: _remarksController.text,
        sensorCode: _selectedSensor?.uniqueCode,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Claim ${action == 'APPROVE' ? 'Approved' : 'Rejected'} Successfully')),
        );
        ref.invalidate(pendingVerificationsProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensorsAsync = ref.watch(availableSensorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Field Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 32),
            const Text('Assign IoT Sensor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Select an available sensor to install at the site.'),
            const SizedBox(height: 12),
            sensorsAsync.when(
              data: (sensors) => _buildSensorDropdown(sensors),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading sensors: $e'),
            ),
            const SizedBox(height: 32),
            const Text('Verification Remarks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your findings from field visit...',
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => _process('REJECT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Reject Application'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _process('APPROVE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isProcessing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Approve Application'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('POLICY: ${widget.verification.policyNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
             const Divider(),
             _infoRow('Farmer', widget.verification.farmerName),
             _infoRow('Khasra', widget.verification.khasraNumber),
             _infoRow('Crop', widget.verification.cropType),
             _infoRow('Area', '${widget.verification.areaAcres} Acres'),
             const SizedBox(height: 8),
             Text('Location: ${widget.verification.latitude}, ${widget.verification.longitude}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSensorDropdown(List<SensorModel> sensors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SensorModel>(
          isExpanded: true,
          value: _selectedSensor,
          hint: const Text('Select Sensor Code'),
          items: sensors.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s.uniqueCode),
          )).toList(),
          onChanged: (val) => setState(() => _selectedSensor = val),
        ),
      ),
    );
  }
}
