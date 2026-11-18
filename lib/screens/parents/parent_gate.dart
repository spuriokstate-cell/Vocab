import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'parent_dashboard.dart';

/// Keeps the parent area away from young children: a grown-up question.
class ParentGate extends StatefulWidget {
  const ParentGate({super.key, this.random});
  final Random? random;

  @override
  State<ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<ParentGate> {
  late final Random _rng = widget.random ?? Random();
  late int _a, _b;
  final _answer = TextEditingController();
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    _a = 6 + _rng.nextInt(7); // 6..12
    _b = 3 + _rng.nextInt(7); // 3..9
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _check() {
    if (int.tryParse(_answer.text.trim()) == _a * _b) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ParentDashboard()));
    } else {
      setState(() {
        _wrong = true;
        _answer.clear();
        _newQuestion();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('For Grown-ups')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ContentWidth(
            maxWidth: 480,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_rounded, size: 64, color: AppColors.purple),
                const SizedBox(height: 12),
                const Text('Ask a grown-up to answer:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, color: AppColors.soft)),
                const SizedBox(height: 8),
                Text('What is $_a × $_b ?',
                    key: const ValueKey('gate-question'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                TextField(
                  key: const ValueKey('gate-answer'),
                  controller: _answer,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(hintText: 'Answer'),
                  onSubmitted: (_) => _check(),
                ),
                if (_wrong) ...[
                  const SizedBox(height: 10),
                  const Text('Not quite. Here is a new question.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.coral, fontSize: 16)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('gate-enter'),
                  onPressed: _check,
                  child: const Text('Enter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
