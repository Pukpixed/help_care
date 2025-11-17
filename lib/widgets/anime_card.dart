import 'package:flutter/material.dart';

class AnimeCard extends StatelessWidget {
  final String id;
  final String name;
  final int episode;
  final int season;
  final double score;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AnimeCard({
    super.key,
    required this.id,
    required this.name,
    required this.episode,
    required this.season,
    required this.score,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        title: Text(
          name,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
        ),
        subtitle: Text(
          "Episode: $episode | Season: $season\nScore: ${score.toStringAsFixed(2)}",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
