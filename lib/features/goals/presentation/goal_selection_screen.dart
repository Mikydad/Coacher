import 'package:flutter/material.dart';

class GoalSelectionScreen extends StatelessWidget {
  const GoalSelectionScreen({super.key});

  static const routeName = '/goals';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goal Selection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('What do you want to improve?', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Choose your path to excellence.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _GoalTile(title: 'Study', selected: true),
              _GoalTile(title: 'Fitness'),
              _GoalTile(title: 'Productivity'),
              _GoalTile(title: 'Focus'),
              _GoalTile(title: 'Habits'),
              _GoalTile(title: 'Mental Clarity'),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Create your first goal', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(hintText: 'e.g. Study 1 hour daily')),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'daily', label: Text('Daily')),
              ButtonSegment(value: 'weekly', label: Text('Weekly')),
              ButtonSegment(value: 'custom', label: Text('Custom')),
            ],
            selected: const {'daily'},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: 16),
          const Text('INTENSITY', style: TextStyle(letterSpacing: 1.2, color: Colors.white60)),
          const SizedBox(height: 8),
          const LinearProgressIndicator(value: 0.75),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: const Color(0xFFB7FF00),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Create My Goal'),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.title, this.selected = false});

  final String title;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 130,
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFB7FF00) : const Color(0xFF1A1C1F),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: selected ? Colors.black : Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
