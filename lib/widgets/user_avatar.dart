import 'package:flutter/material.dart';

/// Círculo con las iniciales del usuario.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.initials, this.radius = 40});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(fontSize: radius * 0.7),
      ),
    );
  }
}
