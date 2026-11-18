import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// The big box where the child types a word. Works with the on-screen
/// keyboard on phones and tablets, a physical keyboard on Windows, and the
/// optional colorful letter tiles.
class WriteBox extends StatelessWidget {
  const WriteBox({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.focusNode,
    this.enabled = true,
    this.showTiles = false,
    this.hint = 'Type the word here',
    this.semanticLabel = 'Your answer',
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final FocusNode? focusNode;
  final bool enabled;
  final bool showTiles;
  final String hint;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: semanticLabel,
          textField: true,
          child: TextField(
            key: const ValueKey('write-box'),
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            autocorrect: false,
            enableSuggestions: false,
            smartQuotesType: SmartQuotesType.disabled,
            smartDashesType: SmartDashesType.disabled,
            textCapitalization: TextCapitalization.none,
            keyboardType: TextInputType.visiblePassword, // no predictions that give away spelling
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.center,
            inputFormatters: [LengthLimitingTextInputFormatter(24)],
            style: const TextStyle(
                fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 2),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: AppColors.purple, width: 3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: AppColors.coral, width: 4),
              ),
            ),
            onSubmitted: onSubmit,
          ),
        ),
        if (showTiles && enabled) ...[
          const SizedBox(height: 12),
          LetterTiles(controller: controller),
        ],
      ],
    );
  }
}

/// Colorful A-Z tiles for children who find the normal keyboard hard.
class LetterTiles extends StatelessWidget {
  const LetterTiles({super.key, required this.controller});
  final TextEditingController controller;

  static const _colors = [
    AppColors.coral, AppColors.sunny, AppColors.mint, AppColors.sky,
    AppColors.pink, AppColors.purple, AppColors.leaf,
  ];

  void _type(String ch) {
    final t = controller.text;
    final sel = controller.selection;
    final start = sel.isValid ? sel.start : t.length;
    final end = sel.isValid ? sel.end : t.length;
    final next = t.replaceRange(start, end, ch);
    controller.value = TextEditingValue(
        text: next, selection: TextSelection.collapsed(offset: start + ch.length));
  }

  void _backspace() {
    final t = controller.text;
    if (t.isEmpty) return;
    final sel = controller.selection;
    if (sel.isValid && sel.start != sel.end) {
      controller.value = TextEditingValue(
          text: t.replaceRange(sel.start, sel.end, ''),
          selection: TextSelection.collapsed(offset: sel.start));
      return;
    }
    final at = sel.isValid ? sel.start : t.length;
    if (at == 0) return;
    controller.value = TextEditingValue(
        text: t.replaceRange(at - 1, at, ''),
        selection: TextSelection.collapsed(offset: at - 1));
  }

  @override
  Widget build(BuildContext context) {
    final letters = 'abcdefghijklmnopqrstuvwxyz'.split('');
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < letters.length; i++)
          _Tile(
            label: letters[i],
            color: _colors[i % _colors.length],
            onTap: () => _type(letters[i]),
          ),
        _Tile(label: "'", color: AppColors.soft, onTap: () => _type("'"),
            semantic: 'apostrophe'),
        _Tile(label: '⌫', color: AppColors.ink, onTap: _backspace,
            semantic: 'delete letter', wide: true),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.color,
    required this.onTap,
    this.semantic,
    this.wide = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? semantic;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic ?? 'letter $label',
      excludeSemantics: true,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: wide ? 84 : 46,
            height: 50,
            child: Center(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
    );
  }
}
