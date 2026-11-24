import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../layout/web_sidebar.dart';
import '../theme/web_palette.dart';
import '../theme/web_typography.dart';

/// Shows the Digital Ledger keyboard shortcuts cheatsheet modal.
Future<void> showWebShortcutsDialog(
  BuildContext context, {
  required List<WebNavItem> navItems,
  required bool canCreateBill,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) =>
        WebShortcutsDialog(navItems: navItems, canCreateBill: canCreateBill),
  );
}

/// Digital Ledger keyboard shortcuts reference modal for the web shell.
class WebShortcutsDialog extends StatefulWidget {
  const WebShortcutsDialog({
    super.key,
    required this.navItems,
    required this.canCreateBill,
  });

  final List<WebNavItem> navItems;
  final bool canCreateBill;

  @override
  State<WebShortcutsDialog> createState() => _WebShortcutsDialogState();
}

class _WebShortcutsDialogState extends State<WebShortcutsDialog> {
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (_closing || !mounted || event is! KeyDownEvent) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    final kb = HardwareKeyboard.instance;
    final key = event.logicalKey;
    final isEscape = key == LogicalKeyboardKey.escape;
    final isQuestion =
        !kb.isControlPressed &&
        !kb.isMetaPressed &&
        !kb.isAltPressed &&
        (event.character == '?' ||
            key == LogicalKeyboardKey.question ||
            (key == LogicalKeyboardKey.slash && kb.isShiftPressed));

    if (isEscape || isQuestion) {
      _close();
      return true;
    }
    return false;
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final maxDialogHeight = math.min(620.0, size.height * 0.85);
    final primaryNavCount = math.min(widget.navItems.length, 7);

    return Dialog(
      backgroundColor: WebPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: WebPalette.hairlineStrong),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Focus(
        autofocus: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: maxDialogHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 14, 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: WebPalette.brassWash,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: WebPalette.brass.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.keyboard,
                        size: 19,
                        color: WebPalette.brassDeep,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.keyboardShortcuts,
                        style: WebTypography.serif(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: WebPalette.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.close,
                      onPressed: _close,
                      icon: const Icon(
                        PhosphorIconsRegular.x,
                        size: 18,
                        color: WebPalette.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: WebPalette.hairline),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ShortcutSection(
                        title: l10n.shortcutsNavigation,
                        rows: [
                          _ShortcutEntry(
                            label: l10n.shortcutGlobalSearch,
                            combos: const [
                              ['Ctrl', 'K'],
                              ['/'],
                            ],
                          ),
                          if (widget.canCreateBill)
                            _ShortcutEntry(
                              label: l10n.shortcutNewBill,
                              combos: const [
                                ['Alt', 'N'],
                                ['Alt', 'B'],
                              ],
                            ),
                          for (var i = 0; i < primaryNavCount; i++)
                            _ShortcutEntry(
                              label: l10n.shortcutGoToSection(
                                widget.navItems[i].label,
                              ),
                              combos: [
                                ['Alt', '${i + 1}'],
                              ],
                            ),
                        ],
                      ),
                      if (widget.canCreateBill) ...[
                        const SizedBox(height: 18),
                        _ShortcutSection(
                          title: l10n.shortcutsBillingForms,
                          rows: [
                            _ShortcutEntry(
                              label: l10n.shortcutSaveBill,
                              combos: const [
                                ['Ctrl', 'S'],
                              ],
                            ),
                            _ShortcutEntry(
                              label: l10n.shortcutFocusProductSearch,
                              combos: const [
                                ['Ctrl', 'L'],
                              ],
                            ),
                            _ShortcutEntry(
                              label: l10n.shortcutNextOrAdd,
                              combos: const [
                                ['Enter'],
                              ],
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      _ShortcutSection(
                        title: l10n.shortcutsGeneral,
                        rows: [
                          _ShortcutEntry(
                            label: l10n.shortcutShowCheatsheet,
                            combos: const [
                              ['?'],
                            ],
                          ),
                          _ShortcutEntry(
                            label: l10n.shortcutCloseModal,
                            combos: const [
                              ['Esc'],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: WebPalette.hairline),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.shortcutHintTip,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: WebPalette.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(onPressed: _close, child: Text(l10n.close)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutEntry {
  const _ShortcutEntry({required this.label, required this.combos});

  final String label;
  final List<List<String>> combos;
}

class _ShortcutSection extends StatelessWidget {
  const _ShortcutSection({required this.title, required this.rows});

  final String title;
  final List<_ShortcutEntry> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title.toUpperCase(), style: WebTypography.eyebrow()),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: WebPalette.paper.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: WebPalette.hairline),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: WebPalette.hairline),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          rows[i].label,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: WebPalette.ink),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (var c = 0; c < rows[i].combos.length; c++) ...[
                            if (c > 0)
                              Text(
                                '/',
                                style: WebTypography.mono(
                                  fontSize: 11,
                                  color: WebPalette.inkFaint,
                                ),
                              ),
                            _KeyCombo(keys: rows[i].combos[c]),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyCombo extends StatelessWidget {
  const _KeyCombo({required this.keys});

  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Text(
                '+',
                style: WebTypography.mono(
                  fontSize: 10.5,
                  color: WebPalette.inkFaint,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: WebPalette.cardBright,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: WebPalette.hairlineStrong),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x122A2416),
                  offset: Offset(0, 1),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Text(
              keys[i],
              style: WebTypography.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: WebPalette.ink,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
