import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  final String verificationLevel;
  final double size;
  final bool showLabel;

  const VerifiedBadge({
    super.key,
    required this.verificationLevel,
    this.size = 20.0,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    if (verificationLevel == 'none' || verificationLevel.isEmpty) {
      return const SizedBox.shrink();
    }

    final badgeData = _getBadgeData(verificationLevel.toLowerCase());

    return Container(
      padding: showLabel 
          ? EdgeInsets.symmetric(
              horizontal: size * 0.3,
              vertical: size * 0.15,
            )
          : EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        gradient: badgeData['gradient'],
        shape: showLabel ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: showLabel ? BorderRadius.circular(size * 0.3) : null,
        boxShadow: [
          BoxShadow(
            color: badgeData['shadowColor'],
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeData['icon'],
            size: size,
            color: Colors.white,
          ),
          if (showLabel) ...[
            SizedBox(width: size * 0.2),
            Text(
              badgeData['label'],
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getBadgeData(String level) {
    switch (level) {
      case 'basic':
        return {
          'icon': Icons.verified,
          'label': 'VERIFIED',
          'gradient': const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': Colors.blue.withValues(alpha: 0.3),
        };
      
      case 'premium':
        return {
          'icon': Icons.verified_user,
          'label': 'PREMIUM VERIFIED',
          'gradient': const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': Colors.amber.withValues(alpha: 0.4),
        };
      
      case 'business':
        return {
          'icon': Icons.business_center,
          'label': 'BUSINESS VERIFIED',
          'gradient': const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': Colors.green.withValues(alpha: 0.3),
        };
      
      default:
        return {
          'icon': Icons.verified,
          'label': 'VERIFIED',
          'gradient': const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': Colors.blue.withValues(alpha: 0.3),
        };
    }
  }
}

class VerificationStatusWidget extends StatelessWidget {
  final String status;
  final String? verificationLevel;
  final VoidCallback? onTap;

  const VerificationStatusWidget({
    super.key,
    required this.status,
    this.verificationLevel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getStatusColor(status).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getStatusColor(status).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(status),
              size: 16,
              color: _getStatusColor(status),
            ),
            const SizedBox(width: 6),
            Text(
              _getStatusText(status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(status),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: _getStatusColor(status),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'not_verified':
      case 'none':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Icons.verified;
      case 'pending':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.cancel;
      case 'not_verified':
      case 'none':
        return Icons.help_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return verificationLevel != null 
            ? '${verificationLevel!.toUpperCase()} VERIFIED'
            : 'VERIFIED';
      case 'pending':
        return 'VERIFICATION PENDING';
      case 'rejected':
        return 'VERIFICATION REJECTED';
      case 'not_verified':
      case 'none':
        return 'NOT VERIFIED';
      default:
        return 'UNKNOWN STATUS';
    }
  }
}

class VerificationBenefitsWidget extends StatelessWidget {
  final String verificationLevel;

  const VerificationBenefitsWidget({
    super.key,
    required this.verificationLevel,
  });

  @override
  Widget build(BuildContext context) {
    final benefits = _getBenefits(verificationLevel.toLowerCase());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                VerifiedBadge(
                  verificationLevel: verificationLevel,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '${verificationLevel.toUpperCase()} Verification Benefits',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...benefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  List<String> _getBenefits(String level) {
    switch (level) {
      case 'basic':
        return [
          'Verified badge on your profile',
          'Increased buyer trust',
          'Priority in search results',
          'Access to basic seller tools',
        ];
      
      case 'premium':
        return [
          'Premium verified badge',
          'Highest buyer trust level',
          'Top priority in search results',
          'Advanced seller analytics',
          'Priority customer support',
          'Featured listing opportunities',
        ];
      
      case 'business':
        return [
          'Business verified badge',
          'Corporate seller status',
          'Bulk listing tools',
          'Advanced business analytics',
          'Dedicated account manager',
          'Custom branding options',
        ];
      
      default:
        return [
          'Verified badge on your profile',
          'Increased buyer trust',
          'Priority in search results',
        ];
    }
  }
}
