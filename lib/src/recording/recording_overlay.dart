import 'package:flutter/material.dart';

class RecordingOverlay extends StatelessWidget {
  final Duration duration;
  final bool isLocked;
  final VoidCallback onDelete;

  const RecordingOverlay({
    super.key,
    required this.duration,
    required this.onDelete,
    this.isLocked = false,
  });

  String _format(Duration d) =>
      "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
          "${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          // 🗑 DELETE
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          const SizedBox(width: 12),

          // 🌊 WAVE (placeholder animation)
          Expanded(
            child: LinearProgressIndicator(
              value: null,
              color: Colors.red,
              backgroundColor: Colors.grey[700],
            ),
          ),

          const SizedBox(width: 12),

          // 🔒 LOCK / ⏱ TIME
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLocked)
                const Icon(Icons.lock, color: Colors.white, size: 16),
              Text(
                _format(duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
