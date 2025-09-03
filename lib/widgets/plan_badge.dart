import 'package:flutter/material.dart';

class PlanBadge extends StatelessWidget {
  final String planType;
  final double size;
  final bool showLabel;

  const PlanBadge({
    super.key,
    required this.planType,
    this.size = 24.0,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final badgeData = _getBadgeData(planType.toLowerCase());
    
    if (planType.toLowerCase() == 'free') {
      return const SizedBox.shrink(); // Don't show badge for free plan
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.3,
        vertical: size * 0.15,
      ),
      decoration: BoxDecoration(
        gradient: badgeData['gradient'],
        borderRadius: BorderRadius.circular(size * 0.3),
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

  Map<String, dynamic> _getBadgeData(String plan) {
    switch (plan) {
      case 'starter':
        return {
          'icon': Icons.rocket_launch,
          'label': 'STARTER',
          'gradient': const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': Colors.green.withValues(alpha: 0.3),
        };
      
      case 'basic':
        return {
          'icon': Icons.star,
          'label': 'BASIC',
          'gradient': const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': Colors.blue.withValues(alpha: 0.3),
        };
      
      case 'premium':
        return {
          'icon': Icons.diamond,
          'label': 'PREMIUM',
          'gradient': const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': Colors.purple.withValues(alpha: 0.3),
        };
      
      case 'business':
        return {
          'icon': Icons.business_center,
          'label': 'BUSINESS',
          'gradient': const LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFE65100)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': Colors.orange.withValues(alpha: 0.3),
        };
      
      case 'top':
        return {
          'icon': Icons.emoji_events,
          'label': 'TOP',
          'gradient': const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': Colors.amber.withValues(alpha: 0.4),
        };
      
      case 'top_featured':
      case 'top featured':
        return {
          'icon': Icons.auto_awesome,
          'label': 'TOP FEATURED',
          'gradient': const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': Colors.pink.withValues(alpha: 0.4),
        };
      
      default:
        return {
          'icon': Icons.label,
          'label': plan.toUpperCase(),
          'gradient': const LinearGradient(
            colors: [Color(0xFF757575), Color(0xFF424242)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': Colors.grey.withValues(alpha: 0.3),
        };
    }
  }
}

class PlanBadgeIcon extends StatelessWidget {
  final String planType;
  final double size;

  const PlanBadgeIcon({
    super.key,
    required this.planType,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    if (planType.toLowerCase() == 'free') {
      return const SizedBox.shrink();
    }

    final badgeData = _getBadgeData(planType.toLowerCase());
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: badgeData['gradient'],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: badgeData['shadowColor'],
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Icon(
        badgeData['icon'],
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }

  Map<String, dynamic> _getBadgeData(String plan) {
    switch (plan) {
      case 'starter':
        return {
          'icon': Icons.rocket_launch,
          'gradient': const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ),
          'shadowColor': Colors.green.withValues(alpha: 0.3),
        };
      
      case 'basic':
        return {
          'icon': Icons.star,
          'gradient': const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
          ),
          'shadowColor': Colors.blue.withValues(alpha: 0.3),
        };
      
      case 'premium':
        return {
          'icon': Icons.diamond,
          'gradient': const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
          ),
          'shadowColor': Colors.purple.withValues(alpha: 0.3),
        };
      
      case 'business':
        return {
          'icon': Icons.business_center,
          'gradient': const LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFE65100)],
          ),
          'shadowColor': Colors.orange.withValues(alpha: 0.3),
        };
      
      case 'top':
        return {
          'icon': Icons.emoji_events,
          'gradient': const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
          ),
          'shadowColor': Colors.amber.withValues(alpha: 0.4),
        };
      
      case 'top_featured':
      case 'top featured':
        return {
          'icon': Icons.auto_awesome,
          'gradient': const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
          ),
          'shadowColor': Colors.pink.withValues(alpha: 0.4),
        };
      
      default:
        return {
          'icon': Icons.label,
          'gradient': const LinearGradient(
            colors: [Color(0xFF757575), Color(0xFF424242)],
          ),
          'shadowColor': Colors.grey.withValues(alpha: 0.3),
        };
    }
  }
}
