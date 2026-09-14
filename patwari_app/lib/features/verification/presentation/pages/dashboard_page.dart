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
    final khasraRequestsAsync = ref.watch(pendingKhasraRequestsProvider);
    final claimReviewsAsync = ref.watch(pendingClaimReviewsProvider);
    final statsAsync = ref.watch(patwariStatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patwari Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Field Verification Portal', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(pendingVerificationsProvider);
              ref.invalidate(pendingKhasraRequestsProvider);
              ref.invalidate(pendingClaimReviewsProvider);
              ref.invalidate(patwariStatsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingVerificationsProvider);
          ref.invalidate(pendingKhasraRequestsProvider);
          ref.invalidate(pendingClaimReviewsProvider);
          ref.invalidate(patwariStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Header with gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: statsAsync.when(
                    data: (stats) => _buildStatsCards(stats),
                    loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.white))),
                    error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              
              // NEW: Claim Reviews Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.psychology_alt, color: Colors.purple.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Pending AI Claim Reviews',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              
              claimReviewsAsync.when(
                data: (list) => list.isEmpty
                    ? const SizedBox.shrink() // Hide if empty
                    : SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: list.length,
                          itemBuilder: (context, index) => _buildClaimReviewCard(context, ref, list[index]),
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const SizedBox.shrink(),
              ),

              // Pending Verifications Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.pending_actions, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Pending Insurance Verifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Verifications List
              verificationsAsync.when(
                data: (list) => list.isEmpty
                    ? _buildEmptyState('All Caught Up!', 'No pending insurance verifications')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: list.length,
                        itemBuilder: (context, index) => _buildVerificationCard(context, list[index]),
                      ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text('Error loading data', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Pending Khasra Requests Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.landscape, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Pending Land (Khasra) Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Khasra Requests List
              khasraRequestsAsync.when(
                data: (list) => list.isEmpty
                    ? _buildEmptyState('No Land Requests', 'No pending khasra additions')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: list.length,
                        itemBuilder: (context, index) => _buildKhasraRequestCard(context, ref, list[index]),
                      ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text('Error loading data', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return Row(
      children: [
        _statCard(
          'Pending',
          stats['pendingVerifications']?.toString() ?? '0',
          Icons.hourglass_empty,
          Colors.orange,
        ),
        const SizedBox(width: 12),
        _statCard(
          'Approved',
          stats['approvedVerifications']?.toString() ?? '0',
          Icons.check_circle,
          Colors.green,
        ),
        const SizedBox(width: 12),
        _statCard(
          'Sensors',
          stats['availableSensors']?.toString() ?? '0',
          Icons.sensors,
          Colors.cyan,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationCard(BuildContext context, VerificationModel v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetail(context, v),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with policy number and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.description, color: Colors.blue.shade700, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.policyNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(v.farmerName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        v.status,
                        style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 24),
                
                // Details row
                Row(
                  children: [
                    _detailChip(Icons.grass, v.cropType),
                    const SizedBox(width: 12),
                    _detailChip(Icons.square_foot, '${v.areaAcres} Acres'),
                    const SizedBox(width: 12),
                    _detailChip(Icons.location_on, v.khasraNumber),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDetail(context, v),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View & Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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

  // =====================================
  // KHASRA REQUEST WIDGETS
  // =====================================

  Widget _buildKhasraRequestCard(BuildContext context, WidgetRef ref, KhasraRequestModel r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.landscape, color: Colors.orange.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Khasra: ${r.khasraNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(r.farmerName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _detailChip(Icons.location_city, r.village),
                const SizedBox(width: 12),
                _detailChip(Icons.square_foot, '${r.areaAcres} Ac'),
                const SizedBox(width: 12),
                _detailChip(Icons.gps_fixed, '${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showKhasraActionDialog(context, ref, r),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Approve or Reject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showKhasraActionDialog(BuildContext context, WidgetRef ref, KhasraRequestModel r) {
    showDialog(
      context: context,
      builder: (ctx) {
        final commentController = TextEditingController();
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Khasra Verification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Are you sure you want to process Khasra ${r.khasraNumber} for ${r.farmerName}?'),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (Optional for Approval)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (commentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remarks required for rejection')));
                    return;
                  }
                  setState(() => isSubmitting = true);
                  final success = await ref.read(verificationRepositoryProvider).processKhasraRequest(
                    requestId: r.id, action: 'REJECTED', remarks: commentController.text.trim()
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (success) {
                    ref.invalidate(pendingKhasraRequestsProvider);
                    ref.invalidate(patwariStatsProvider);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Reject', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  setState(() => isSubmitting = true);
                  final success = await ref.read(verificationRepositoryProvider).processKhasraRequest(
                    requestId: r.id, action: 'APPROVED', remarks: commentController.text.trim()
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (success) {
                    ref.invalidate(pendingKhasraRequestsProvider);
                    ref.invalidate(patwariStatsProvider);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Approve', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  // =====================================
  // CLAIM REVIEW WIDGETS
  // =====================================

  Widget _buildClaimReviewCard(BuildContext context, WidgetRef ref, ClaimReviewModel c) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showClaimReviewDialog(context, ref, c),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.purple.shade50,
                      child: Icon(Icons.psychology, color: Colors.purple.shade700, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.farmerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Severity: ${c.damagePercentage.toStringAsFixed(1)}%', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Policy: ${c.policyNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Text('Disease: ${c.diseaseDetected}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showClaimReviewDialog(context, ref, c),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.purple.shade700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text('Review', style: TextStyle(color: Colors.purple.shade700, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClaimReviewDialog(BuildContext context, WidgetRef ref, ClaimReviewModel c) {
    showDialog(
      context: context,
      builder: (ctx) {
        final commentController = TextEditingController();
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('AI Claim Review'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Assessment:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${c.diseaseDetected} (${c.damagePercentage.toStringAsFixed(1)}% damage)'),
                  const SizedBox(height: 16),
                  const Text('Policy Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Farmer: ${c.farmerName}'),
                  Text('Policy: ${c.policyNumber}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Review Remarks (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  setState(() => isSubmitting = true);
                  final success = await ref.read(verificationRepositoryProvider).processClaimReview(
                    claimId: c.id, action: 'REJECT', remarks: commentController.text.trim()
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (success) {
                    ref.invalidate(pendingClaimReviewsProvider);
                    ref.invalidate(patwariStatsProvider);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Reject Final', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  setState(() => isSubmitting = true);
                  final success = await ref.read(verificationRepositoryProvider).processClaimReview(
                    claimId: c.id, action: 'RETRY', remarks: commentController.text.trim()
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (success) {
                    ref.invalidate(pendingClaimReviewsProvider);
                    ref.invalidate(patwariStatsProvider);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Retry Chance', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
