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
        SnackBar(
          content: const Text('Please assign a sensor before approval'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
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
          SnackBar(
            content: Row(
              children: [
                Icon(action == 'APPROVE' ? Icons.check_circle : Icons.cancel, color: Colors.white),
                const SizedBox(width: 8),
                Text('Application ${action == 'APPROVE' ? 'Approved' : 'Rejected'} Successfully'),
              ],
            ),
            backgroundColor: action == 'APPROVE' ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(pendingVerificationsProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensorsAsync = ref.watch(availableSensorsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: const Text('Field Verification'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Policy Info Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.verification.status,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.verification.policyNumber,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.verification.farmerName,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Land Details Card
                  _buildCard(
                    title: 'Land Details',
                    icon: Icons.landscape,
                    child: Column(
                      children: [
                        _infoRow('Khasra Number', widget.verification.khasraNumber),
                        _infoRow('Crop Type', widget.verification.cropType),
                        _infoRow('Area', '${widget.verification.areaAcres} Acres'),
                        _infoRow('Location', '${widget.verification.latitude.toStringAsFixed(4)}, ${widget.verification.longitude.toStringAsFixed(4)}'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sensor Assignment Card
                  _buildCard(
                    title: 'IoT Sensor Assignment',
                    icon: Icons.sensors,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select an available sensor to install at the field site:',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        sensorsAsync.when(
                          data: (sensors) => sensors.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                                      const SizedBox(width: 12),
                                      const Expanded(child: Text('No sensors available')),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
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
                                        child: Row(
                                          children: [
                                            Icon(Icons.memory, color: Colors.blue.shade700, size: 20),
                                            const SizedBox(width: 12),
                                            Text(s.uniqueCode),
                                          ],
                                        ),
                                      )).toList(),
                                      onChanged: (val) => setState(() => _selectedSensor = val),
                                    ),
                                  ),
                                ),
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Remarks Card
                  _buildCard(
                    title: 'Verification Remarks',
                    icon: Icons.note_alt,
                    child: TextField(
                      controller: _remarksController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter your observations from field visit...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : () => _process('REJECT'),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : () => _process('APPROVE'),
                          icon: _isProcessing
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle),
                          label: const Text('Approve & Assign'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade700, size: 22),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
