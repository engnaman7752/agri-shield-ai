import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:farmer_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:farmer_app/features/insurance/presentation/providers/insurance_provider.dart';
import 'package:farmer_app/features/insurance/data/insurance_models.dart';
import 'package:farmer_app/features/insurance/data/insurance_repository.dart';
import 'package:farmer_app/features/insurance/presentation/providers/payment_service.dart';
import 'package:farmer_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:farmer_app/features/claims/data/claim_model.dart';
import 'package:farmer_app/features/claims/presentation/pages/file_claim_page.dart';
import 'package:farmer_app/features/claims/presentation/providers/claim_provider.dart';
import 'package:farmer_app/features/chat/presentation/pages/chat_page.dart';
import 'package:farmer_app/l10n/app_localizations.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final policiesAsync = ref.watch(myPoliciesProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(l10n?.appName ?? 'Farmer Shield'),
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
            icon: const Icon(Icons.language),
            onPressed: () => Navigator.pushNamed(context, '/settings/language'),
            tooltip: 'Change Language',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authStateProvider.notifier).logout().then((_) {
                  Navigator.pushReplacementNamed(context, '/login');
                }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatPage()),
          );
        },
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text('AI Agent', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade700,
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
                data: (profile) =>
                    _buildHeader(context, profile?.name ?? 'Farmer'),
                loading: () => const Text('Loading...'),
                error: (_, __) => const Text('Error loading profile'),
              ),
              const SizedBox(height: 24),
              profileAsync.when(
                data: (profile) => _buildStats(profile),
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.myPolicies ?? 'My Policies',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/apply-insurance'),
                    child: Text(l10n?.applyInsurance ?? 'Apply New'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              policiesAsync.when(
                data: (policies) => policies.isEmpty
                    ? _buildEmptyState(context)
                    : _buildPolicyList(context, ref, policies),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading policies: $e'),
              ),

              const SizedBox(height: 32),
              const Text(
                'Recent Claims',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ref
                  .watch(myClaimsProvider)
                  .when(
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
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Namaste, $name!',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Text('Ready to protect your crops today?'),
      ],
    );
  }

  Widget _buildStats(dynamic profile) {
    return Row(
      children: [
        _buildStatCard(
          'Active',
          profile?.activeInsurances.toString() ?? '0',
          Colors.blue,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Claims',
          profile?.pendingClaims.toString() ?? '0',
          Colors.orange,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Lands',
          profile?.totalLands.toString() ?? '0',
          Colors.green,
        ),
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
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
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
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No insurance policies yet',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Protect your harvest by applying for a policy.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyList(
    BuildContext context,
    WidgetRef ref,
    List<InsuranceResponse> policies,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: policies.length,
      itemBuilder: (context, index) {
        final policy = policies[index];
        final status = policy.status.toUpperCase();
        final canClaim = status == 'ACTIVE';
        final isRejected = policy.isRejected;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isRejected ? Colors.red.shade300 : Colors.grey.shade200,
              width: isRejected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  '${policy.cropType} - ${policy.khasraNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Policy: ${policy.policyNumber}'),
                    Text(
                      'Coverage: ₹${policy.coverageAmount.toStringAsFixed(0)}',
                    ),
                  ],
                ),
                trailing: _buildStatusBadge(
                  isRejected ? 'REJECTED' : policy.status,
                ),
              ),
              // Show rejection reason
              if (isRejected && policy.verificationRemarks != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rejected: ${policy.verificationRemarks}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Show pending payment status with retry button
              if (status == 'PENDING')
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payment,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Payment Pending - Payment not completed',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _retryPayment(context, ref, policy),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Show pending verification status
              if (policy.isPending && status == 'PAID')
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Awaiting Patwari verification...',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (canClaim)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FileClaimPage(policy: policy),
                        ),
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
          leading: const Icon(
            Icons.assignment_late_outlined,
            color: Colors.orange,
          ),
          title: Text(claim.policyNumber),
          subtitle: Text('Status: ${claim.status}'),
          trailing: claim.damagePercentage != null
              ? Text('${claim.damagePercentage}% Damage')
              : null,
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'ACTIVE':
        color = Colors.green;
        break;
      case 'PAID':
        color = Colors.blue;
        break;
      case 'PENDING_VERIFICATION':
        color = Colors.orange;
        break;
      case 'CLAIMED':
        color = Colors.purple;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
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
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _retryPayment(
    BuildContext context,
    WidgetRef ref,
    InsuranceResponse policy,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Retry Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Policy: ${policy.policyNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Amount: ₹${policy.premiumAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('Would you like to retry payment for this insurance?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _proceedRetryPayment(context, ref, policy);
            },
            child: const Text('Retry Payment'),
          ),
        ],
      ),
    );
  }

  void _proceedRetryPayment(
    BuildContext context,
    WidgetRef ref,
    InsuranceResponse policy,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing payment...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final repository = ref.read(insuranceRepositoryProvider);
      final order = await repository.retryPayment(policy.id);

      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }

      if (order != null) {
        // Start payment
        ref
            .read(paymentServiceProvider)
            .startPayment(
              order: order,
              onSuccess: (response) {
                _handleRetryPaymentSuccess(context, ref, order, response);
              },
              onError: (response) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment Failed: ${response.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not prepare payment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleRetryPaymentSuccess(
    BuildContext context,
    WidgetRef ref,
    PaymentOrderResponse order,
    PaymentSuccessResponse response,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Confirming payment...'),
              ],
            ),
          ),
        ),
      ),
    );

    ref
        .read(insuranceApplicationProvider.notifier)
        .confirmPayment(response, order.insuranceId, order.orderId)
        .then((result) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Close loading dialog
          }

          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '✓ Payment Successful! Your insurance is now PAID.',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            // Refresh policies
            ref.invalidate(myPoliciesProvider);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚠ Payment succeeded but confirmation failed: ${result.errorMessage ?? "Unknown error"}. Please check your policies.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 8),
              ),
            );
          }
        })
        .catchError((e) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Close loading dialog
          }
          print('❌ Retry payment error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error confirming payment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }
}
