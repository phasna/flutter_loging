import 'package:flutter/material.dart';

/// Ligne d'information du profil (icône + libellé + valeur).
class ProfileInfoTile extends StatelessWidget {
  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Icon(icon),
      ),
      title: Text(label),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }
}
