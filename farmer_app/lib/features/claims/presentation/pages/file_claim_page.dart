import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:farmer_app/features/insurance/data/insurance_models.dart';
import 'package:farmer_app/features/claims/data/claim_model.dart';
import 'package:farmer_app/features/claims/presentation/providers/claim_provider.dart';
import 'package:farmer_app/core/utils/location_utils.dart';
import 'package:farmer_app/core/services/weather_service.dart';
import 'package:farmer_app/l10n/app_localizations.dart';

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
  WeatherData? _weatherData;
  bool _isFetchingWeather = false;
  String? _selectedDamageReason;
  final _damageDetailController = TextEditingController();

  @override
  void dispose() {
    _damageDetailController.dispose();
    super.dispose();
  }

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
        isDemoMode: false,
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
      } else {
        // Fetch weather data for verified location
        _fetchWeather(position.latitude, position.longitude);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _fetchWeather(double lat, double lng) async {
    setState(() => _isFetchingWeather = true);
    try {
      final weather = await WeatherService.getCurrentWeather(lat, lng);
      setState(() => _weatherData = weather);
      if (weather != null) {
        if (weather.rainfall > 50) {
          setState(() => _selectedDamageReason = 'HEAVY_UNSEASONAL_RAIN');
        } else if (weather.temperature < 5) {
          setState(() => _selectedDamageReason = 'FROST_COLD_WAVE');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🌤️ Weather captured: ${weather.condition}, ${weather.temperature.toStringAsFixed(1)}°C'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Weather fetch error: $e');
    } finally {
      setState(() => _isFetchingWeather = false);
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

    if (_selectedDamageReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a damage reason (Step 3)')));
      return;
    }

    ref.read(claimSubmissionProvider.notifier).fileClaim(
      insuranceId: widget.policy.id,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      images: _selectedImages,
      weatherData: _weatherData,
      damageReason: _selectedDamageReason!,
      damageReasonDetail: _damageDetailController.text.isNotEmpty ? _damageDetailController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(claimSubmissionProvider);
    final isLoading = submissionState.isLoading;

    // Listen for success/error
    ref.listen<AsyncValue<ClaimModel?>>(claimSubmissionProvider, (previous, next) {
      next.when(
        data: (claim) {
          if (claim != null && mounted) {
            // Success! Go back to dashboard/previous screen
            Navigator.of(context).pop(); 
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Claim submitted successfully! AI is analyzing...'),
                backgroundColor: Colors.green,
              ),
            );
            // Also invalidate to show fresh data
            ref.invalidate(myClaimsProvider);
          }
        },
        error: (err, stack) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $err'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        loading: () {},
      );
    });

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.fileClaim ?? 'File a Claim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => Navigator.pushNamed(context, '/settings/language'),
            tooltip: 'Change Language',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildPolicySummary(),
            const SizedBox(height: 32),
            _buildLocationSection(),
            const SizedBox(height: 32),
            _buildPhotoSection(),
            const SizedBox(height: 32),
            _buildDamageReasonSection(),
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
    if (!_isLocationVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your GPS location first before taking photos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // Camera only — no gallery option for integrity
    _pickImage(ImageSource.camera);
  }

  final _damageReasons = [
    {'key': 'DROUGHT', 'label': 'Drought', 'hindi': 'सूखा', 'icon': Icons.wb_sunny},
    {'key': 'FLOOD_INUNDATION', 'label': 'Flood', 'hindi': 'बाढ़', 'icon': Icons.water},
    {'key': 'HEAVY_UNSEASONAL_RAIN', 'label': 'Heavy Rain', 'hindi': 'भारी बारिश', 'icon': Icons.thunderstorm},
    {'key': 'HAILSTORM', 'label': 'Hailstorm', 'hindi': 'ओलावृष्टि', 'icon': Icons.ac_unit},
    {'key': 'CYCLONE_STORM', 'label': 'Cyclone', 'hindi': 'चक्रवात', 'icon': Icons.cyclone},
    {'key': 'PEST_ATTACK', 'label': 'Pest Attack', 'hindi': 'कीट हमला', 'icon': Icons.bug_report},
    {'key': 'CROP_DISEASE', 'label': 'Crop Disease', 'hindi': 'फसल रोग', 'icon': Icons.coronavirus},
    {'key': 'FROST_COLD_WAVE', 'label': 'Frost', 'hindi': 'पाला', 'icon': Icons.severe_cold},
    {'key': 'LIGHTNING_FIRE', 'label': 'Fire/Lightning', 'hindi': 'आग/बिजली', 'icon': Icons.local_fire_department},
    {'key': 'LANDSLIDE', 'label': 'Landslide', 'hindi': 'भूस्खलन', 'icon': Icons.landscape},
    {'key': 'POST_HARVEST_LOSS', 'label': 'Post-Harvest', 'hindi': 'कटाई बाद', 'icon': Icons.agriculture},
    {'key': 'OTHER', 'label': 'Other', 'hindi': 'अन्य', 'icon': Icons.more_horiz},
  ];

  Widget _buildDamageReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('3. Damage Reason', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text('Select the primary cause of damage.'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: _damageReasons.length,
          itemBuilder: (context, index) {
            final reason = _damageReasons[index];
            final isSelected = _selectedDamageReason == reason['key'];
            return InkWell(
              onTap: () => setState(() => _selectedDamageReason = reason['key'] as String),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.shade50 : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(reason['icon'] as IconData, color: isSelected ? Colors.green : Colors.grey.shade700, size: 32),
                    const SizedBox(height: 8),
                    Text(reason['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.green : Colors.black87)),
                    Text(reason['hindi'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isSelected ? Colors.green.shade700 : Colors.grey)),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _damageDetailController,
          decoration: InputDecoration(
            labelText: 'Additional Details (Optional)',
            hintText: 'Describe the damage...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
