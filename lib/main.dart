import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const WordLinkApp());

class WordLinkApp extends StatelessWidget {
  const WordLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Word Link',
      tagline: 'Swipe, link, and unleash your inner word wizard!',
      emoji: '🔗',
      slug: 'wordlink',
      howToPlay:
          '• 60 levels: swipe through touching letters (any direction!) to spell words.\n• Find every hidden word to clear the level — grids grow from 3×3 to 5×5.\n• Swipes work forwards or backwards, and you can backtrack mid-swipe.\n• Stuck? Hit 🔀 Shuffle for a fresh letter layout with the same words.\n• Every word is +10 pts, every level +25. Link them all! 🔗',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          WordLinkScreen(players: players, callbacks: cb),
    );
  }
}
