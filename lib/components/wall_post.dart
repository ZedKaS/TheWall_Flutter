import 'package:flutter/material.dart';

class WallPost extends StatelessWidget {
  final String message;
  final String user;
  final DateTime? createdAt;  // optionnel si tu veux l’heure plus tard

  const WallPost({
    super.key,
    required this.message,
    required this.user,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // avatar utilisateur
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.person, size: 28),
          ),

          const SizedBox(width: 16),

          // contenu du post
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // username ou email
                Text(
                  user,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),

                const SizedBox(height: 8),

                // message
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 10),

                // timestamp si disponible
                if (createdAt != null)
                  Text(
                    "${createdAt!.day}/${createdAt!.month}/${createdAt!.year}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
