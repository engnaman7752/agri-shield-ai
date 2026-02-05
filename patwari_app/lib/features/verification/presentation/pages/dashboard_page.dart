import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patwari_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:patwari_app/features/verification/data/verification_models.dart';
import 'package:patwari_app/features/verification/presentation/providers/verification_provider.dart';
import 'package:patwari_app/features/verification/presentation/pages/verification_detail_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationsAsync = ref.watch(pendingVerificationsProvider);
    final statsAsync = ref.watch(patwariStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patwari Dashboard'),
            Text('Field Verification Only', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(pendingVerificationsProvider);
              ref.invalidate(patwariStatsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout().then((_) {
              Navigator.pushReplacementNamed(context, '/login');
            }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: statsAsync.when(
                data: (stats) => _buildStats(stats),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            verificationsAsync.when(
              data: (list) => list.isEmpty
                  ? const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No pending verifications.'),
                  ))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final v = list[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                tileColor: Colors.blue.shade50,
                                title: Text(v.policyNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(v.farmerName),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _showDetail(context, v),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Crop: ${v.cropType}'),
                                        Text('Area: ${v.areaAcres} Acres'),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Khasra: ${v.khasraNumber}'),
                                        Text('Status: ${v.status}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(Map<String, dynamic> stats) {
    return Row(
      children: [
        _statItem('Pending', stats['pendingVerifications']?.toString() ?? '0', Colors.orange),
        _statItem('Done', stats['totalProcessed']?.toString() ?? '0', Colors.green),
        _statItem('Sensors', stats['availableSensors']?.toString() ?? '0', Colors.blue),
      ],
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, VerificationModel verification) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FieldVerificationPage(verification: verification)),
    );
  }
}
