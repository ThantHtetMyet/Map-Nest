import 'package:flutter/material.dart';

class PostMarker extends StatelessWidget {
  final bool isSelected;
  final String propertyType;

  const PostMarker({
    super.key,
    this.isSelected = false,
    this.propertyType = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow/glow effect
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? Colors.orange : Colors.red).withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1.5,
                ),
              ],
            ),
          ),
          // Main marker circle with gradient
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [Colors.orange.shade400, Colors.orange.shade600]
                    : [Colors.red.shade400, Colors.red.shade600],
              ),
              border: Border.all(
                color: Colors.white,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getIconForPropertyType(propertyType),
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForPropertyType(String propertyType) {
    if (propertyType.toLowerCase().contains('apartment')) {
      return Icons.apartment;
    } else if (propertyType.toLowerCase().contains('land')) {
      return Icons.home;
    } else {
      return Icons.home; // Default icon
    }
  }
}
