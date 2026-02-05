import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:farmer_app/features/insurance/presentation/providers/insurance_provider.dart';
import 'package:farmer_app/features/insurance/data/insurance_models.dart';
import 'package:farmer_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:farmer_app/features/claims/data/claim_model.dart';
import 'package:farmer_app/features/claims/presentation/pages/file_claim_page.dart';
import 'package:farmer_app/features/claims/presentation/providers/claim_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final policiesAsync = ref.watch(myPoliciesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Farmer Shield'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userProfileProvider);
              ref.invalidate(myPoliciesProvider);
              ref.invalidate(myClaimsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout().then((_) {
              Navigator.pushReplacementNamed(context, '/login');
            }),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(myPoliciesProvider);
          ref.invalidate(myClaimsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileAsync.when(
                data: (profile) => _buildHeader(context, profile?.name ?? 'Farmer'),
                loading: () => const Text('Loading...'),
                error: (_, __) => const Text('Error loading profile'),
              ),
              const SizedBox(height: 24),
              profileAsync.when(
                data: (profile) => _buildStats(profile),
                loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Policies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/apply-insurance'),
                    child: const Text('Apply New'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              policiesAsync.when(
                data: (policies) => policies.isEmpty 
                  ? _buildEmptyState(context)
                  : _buildPolicyList(context, policies),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading policies: $e'),
              ),
              
              const SizedBox(height: 32),
              const Text('Recent Claims', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ref.watch(myClaimsProvider).when(
                data: (claims) => claims.isEmpty 
                  ? const Text('No recent claims.')
                  : _buildClaimList(claims),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/apply-insurance'),
        label: const Text('New Insurance'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Namaste, $name!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Text('Ready to protect your crops today?'),
      ],
    );
  }

  Widget _buildStats(dynamic profile) {
    return Row(
      children: [
        _buildStatCard('Active', profile?.activeInsurances.toString() ?? '0', Colors.blue),
        const SizedBox(width: 12),
        _buildStatCard('Claims', profile?.pendingClaims.toString() ?? '0', Colors.orange),
        const SizedBox(width: 12),
        _buildStatCard('Lands', profile?.totalLands.toString() ?? '0', Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No insurance policies yet', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Protect your harvest by applying for a policy.', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPolicyList(BuildContext context, List<InsuranceResponse> policies) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: policies.length,
      itemBuilder: (context, index) {
        final policy = policies[index];
        final status = policy.status.toUpperCase();
        final canClaim = status == 'ACTIVE';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text('${policy.cropType} - ${policy.khasraNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Policy: ${policy.policyNumber}'),
                    Text('Coverage: ₹${policy.coverageAmount.toStringAsFixed(0)}'),
                  ],
                ),
                trailing: _buildStatusBadge(policy.status),
              ),
              if (canClaim)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FileClaimPage(policy: policy)),
                      ),
                      icon: const Icon(Icons.error_outline),
                      label: const Text('File a Claim'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClaimList(List<ClaimModel> claims) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: claims.length,
      itemBuilder: (context, index) {
        final claim = claims[index];
        return ListTile(
          leading: const Icon(Icons.assignment_late_outlined, color: Colors.orange),
          title: Text(claim.policyNumber),
          subtitle: Text('Status: ${claim.status}'),
          trailing: claim.damagePercentage != null ? Text('${claim.damagePercentage}% Damage') : null,
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'ACTIVE': color = Colors.green; break;
      case 'PAID': color = Colors.blue; break;
      case 'PENDING_VERIFICATION': color = Colors.orange; break;
      case 'CLAIMED': color = Colors.purple; break;
      case 'REJECTED': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
