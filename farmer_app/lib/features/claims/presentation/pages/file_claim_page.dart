import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:farmer_app/features/insurance/data/insurance_models.dart';
import 'package:farmer_app/features/claims/presentation/providers/claim_provider.dart';
import 'package:farmer_app/core/utils/location_utils.dart';

class FileClaimPage extends ConsumerStatefulWidget {
  final InsuranceResponse policy;

  const FileClaimPage({super.key, required this.policy});

  @override
  ConsumerState<FileClaimPage> createState() => _FileClaimPageState();
}

class _FileClaimPageState extends ConsumerState<FileClaimPage> {
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  Position? _currentPosition;
  bool _isGettingLocation = false;
  bool _isLocationVerified = false;
  double? _distanceFromLand;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _selectedImages.add(image));
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      final position = await Geolocator.getCurrentPosition();
      final result = LocationUtils.isWithinBoundary(
        position, 
        widget.policy.latitude, 
        widget.policy.longitude,
        isDemoMode: true,
      );

      setState(() {
        _currentPosition = position;
        _isLocationVerified = result.$1;
        _distanceFromLand = result.$2;
      });
      
      if (!_isLocationVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification Failed: You are too far from the insured land.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _submit() {
    if (_selectedImages.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add exactly 4 photos of the damage as required')));
      return;
    }
    if (_currentPosition == null || !_isLocationVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please tag and verify your GPS location near the farm (click Verify)')));
      return;
    }

    ref.read(claimSubmissionProvider.notifier).fileClaim(
      insuranceId: widget.policy.id,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      images: _selectedImages,
    ).then((_) {
      final submissionState = ref.read(claimSubmissionProvider);
      if (submissionState.hasValue && submissionState.value != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Claim filed successfully!')));
      } else if (submissionState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Submission Error: ${submissionState.error}'),
          backgroundColor: Colors.red,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(claimSubmissionProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('File a Claim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildPolicySummary(),
            const SizedBox(height: 32),
            _buildLocationSection(),
            const SizedBox(height: 32),
            _buildPhotoSection(),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Claim for AI Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySummary() {
    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('POLICY DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 8),
            Text('${widget.policy.cropType} - ${widget.policy.khasraNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Policy No: ${widget.policy.policyNumber}'),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. GPS Tagging', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text('Identify the exact location of crop damage.'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isLocationVerified ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isLocationVerified ? Colors.green : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _isLocationVerified ? Icons.check_circle : Icons.location_on, 
                    color: _isLocationVerified ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentPosition != null 
                            ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}'
                            : 'Location not tagged',
                          style: TextStyle(fontWeight: _isLocationVerified ? FontWeight.bold : FontWeight.normal),
                        ),
                        if (_distanceFromLand != null && !_isLocationVerified)
                          Text(
                            'Distance: ${(_distanceFromLand! / 1000).toStringAsFixed(2)}km (Too Far)',
                            style: const TextStyle(fontSize: 10, color: Colors.orange),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _isGettingLocation ? null : _getCurrentLocation,
                    child: _isGettingLocation 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isLocationVerified ? 'Re-verify' : 'Verify'),
                  ),
                ],
              ),
              if (_isLocationVerified)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Verification Success: You are within the farm boundary.',
                    style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('2. Damage Photos (4 Required)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text('Take 4 clear photos of the affected crop areas.'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _selectedImages.length + 1,
          itemBuilder: (context, index) {
            if (index == _selectedImages.length) {
              return InkWell(
                onTap: () => _showImageSourceActionSheet(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none),
                  ),
                  child: const Icon(Icons.add_a_photo, color: Colors.grey),
                ),
              );
            }
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_selectedImages[index].path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: InkWell(
                    onTap: () => setState(() => _selectedImages.removeAt(index)),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
