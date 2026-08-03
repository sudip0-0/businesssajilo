import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/web_palette.dart';
import '../theme/web_tokens.dart';

/// Fixed row height for suggestion tiles. Keeping tiles fixed-height lets the
/// keyboard highlight scroll math stay exact.
const double kWebSearchDropdownTileHeight = 56;

/// A search field with an anchored suggestion dropdown that floats below the
/// field at the field's own width.
///
/// Unlike `DropdownButtonFormField`, the option list is a bounded overlay
/// (max height, scrollable), supports arrow-key navigation, and — critically —
/// the field itself is never unmounted while [items] load, so typing never
/// steals focus. The parent owns async loading and debounce; this widget only
/// renders the latest [items] and reports intent via callbacks.
class WebSearchDropdown<T> extends StatefulWidget {
  const WebSearchDropdown({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.items,
    required this.itemBuilder,
    required this.onSelected,
    required this.onQueryChanged,
    this.loading = false,
    this.emptyLabel,
    this.hintIcon = PhosphorIconsRegular.magnifyingGlass,
    this.openOnFocus = true,
    this.refocusOnSelect = true,
    this.maxHeight = 320,
    this.textInputAction,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;

  /// Latest items to show. May be stale while [loading] is true — the dropdown
  /// keeps showing them with a thin progress strip instead of a spinner.
  final List<T> items;

  /// Builds one suggestion row. Must be [kWebSearchDropdownTileHeight] tall so
  /// keyboard scrolling stays aligned.
  final Widget Function(BuildContext context, T item, bool highlighted)
  itemBuilder;

  final ValueChanged<T> onSelected;

  /// Raw text changes — debounce in the parent before hitting the network.
  final ValueChanged<String> onQueryChanged;

  /// True while the parent is fetching a fresh list for the current query.
  final bool loading;

  /// Shown when [items] is empty and not [loading].
  final String? emptyLabel;

  final IconData hintIcon;

  /// Whether the dropdown opens when the field gains focus.
  final bool openOnFocus;

  /// When true (default), re-focuses the field after a selection so the next
  /// scan/keystroke is ready. Set false when the parent moves focus elsewhere
  /// (e.g. bill line qty after picking a product).
  final bool refocusOnSelect;

  final double maxHeight;
  final TextInputAction? textInputAction;

  @override
  State<WebSearchDropdown<T>> createState() => _WebSearchDropdownState<T>();
}

class _WebSearchDropdownState<T> extends State<WebSearchDropdown<T>> {
  final _link = LayerLink();
  final _fieldKey = GlobalKey();
  final _scrollController = ScrollController();
  OverlayEntry? _entry;
  int _highlighted = 0;
  bool _openUpward = false;
  double _overlayMaxHeight = 320;

  /// After a selection we re-focus the field for the next scan/keystroke, but
  /// must not reopen the list over the newly added row. Cleared on the next
  /// focus-gain once the suppress has been honored, or when the user types.
  bool _suppressOpenOnFocus = false;

  /// Width of the field, captured from this widget's own [LayoutBuilder]
  /// constraints during build. Reading a render box's size from the overlay
  /// entry's builder throws "Cannot get size during build" — layout
  /// constraints are the only legal sizing source at build time.
  double _fieldWidth = 480;

  bool get _isOpen => _entry != null;

  static const _overlayGap = 6.0;
  static const _viewportPadding = 8.0;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _removeEntry();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (widget.focusNode.hasFocus) {
      if (_suppressOpenOnFocus) {
        _suppressOpenOnFocus = false;
        return;
      }
      if (widget.openOnFocus) _open();
    } else {
      // Selections use onTapDown, which fires before the focus loss, so by the
      // time we get here a tap on an option has already been handled.
      _close();
    }
  }

  /// Prefer opening below the field; flip above when the viewport has more
  /// room there (e.g. search pinned near the bottom of a long bill).
  void _updateOverlayPlacement() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      _openUpward = false;
      _overlayMaxHeight = widget.maxHeight;
      return;
    }
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final spaceBelow =
        screenHeight - (offset.dy + size.height) - _viewportPadding - _overlayGap;
    final spaceAbove = offset.dy - _viewportPadding - _overlayGap;
    final preferBelow =
        spaceBelow >= widget.maxHeight || spaceBelow >= spaceAbove;
    _openUpward = !preferBelow;
    _overlayMaxHeight = (preferBelow ? spaceBelow : spaceAbove)
        .clamp(80.0, widget.maxHeight);
  }

  void _open() {
    if (_isOpen || !mounted) return;
    _highlighted = 0;
    _updateOverlayPlacement();
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
  }

  void _close() {
    _removeEntry();
  }

  void _removeEntry() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  void _refreshOverlay() {
    if (!_isOpen) return;
    // didUpdateWidget runs during the parent build; markNeedsBuild() on an
    // OverlayEntry in that phase throws. Defer to the next frame whenever the
    // scheduler is already building.
    final phase = SchedulerBinding.instance.schedulerPhase;
    void refresh() {
      if (!mounted || !_isOpen) return;
      _updateOverlayPlacement();
      _entry?.markNeedsBuild();
    }

    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      refresh();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
    }
  }

  void _select(T item) {
    widget.onSelected(item);
    _close();
    if (!widget.refocusOnSelect) return;
    // A pointer-selected option also triggers the field's tap-outside unfocus
    // later in the same pointer-down dispatch, so re-assert focus after this
    // frame. Keeps the POS flow keyboard-first: the caret stays in the search
    // field ready for the next scan/keystroke — but skip opening the list so
    // it doesn't cover the row that was just added. Typing / arrow keys still
    // open it. (No-op if the parent swapped the field out, e.g. a customer chip.)
    _suppressOpenOnFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.focusNode.hasFocus) {
        widget.focusNode.requestFocus();
      } else {
        // Field never lost focus (keyboard Enter). Drop the suppress so a
        // later blur→focus still opens normally.
        _suppressOpenOnFocus = false;
      }
    });
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final items = widget.items;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (items.isEmpty) return KeyEventResult.handled;
      // Don't browse the full list from an empty product-search field.
      if (!widget.openOnFocus && widget.controller.text.trim().isEmpty) {
        return KeyEventResult.ignored;
      }
      if (!_isOpen) {
        _open();
        return KeyEventResult.handled;
      }
      final delta = event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1;
      setState(() {
        _highlighted = (_highlighted + delta) % items.length;
        if (_highlighted < 0) _highlighted += items.length;
      });
      _refreshOverlay();
      _scrollHighlightedIntoView();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_isOpen) {
        _close();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  void _scrollHighlightedIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _highlighted * kWebSearchDropdownTileHeight;
      final position = _scrollController.position;
      final top = position.pixels;
      final bottom = top + position.viewportDimension;
      if (target < top) {
        _scrollController.jumpTo(target);
      } else if (target + kWebSearchDropdownTileHeight > bottom) {
        _scrollController.jumpTo(
          target + kWebSearchDropdownTileHeight - position.viewportDimension,
        );
      }
    });
  }

  void _handleSubmitted(String _) {
    if (_isOpen &&
        widget.items.isNotEmpty &&
        _highlighted < widget.items.length) {
      _select(widget.items[_highlighted]);
    }
  }

  @override
  void didUpdateWidget(covariant WebSearchDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
    }
    // Items/loading changed while open — repaint the floating list.
    if (_isOpen) {
      if (_highlighted >= widget.items.length) {
        _highlighted = widget.items.isEmpty ? 0 : widget.items.length - 1;
      }
      _refreshOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The TextField fills this widget's width, so the constraints are the
        // field's width — captured legally during build for the overlay.
        if (constraints.hasBoundedWidth) {
          _fieldWidth = constraints.maxWidth;
        }
        return CompositedTransformTarget(
          link: _link,
          child: Focus(
            onKeyEvent: _handleKey,
            child: TextField(
              key: _fieldKey,
              controller: widget.controller,
              focusNode: widget.focusNode,
              textInputAction: widget.textInputAction ?? TextInputAction.done,
              onChanged: (value) {
                widget.onQueryChanged(value);
                final hasQuery = value.trim().isNotEmpty;
                if (!hasQuery) {
                  // With openOnFocus: false (product search), don't keep a
                  // full catalog list open after the query is cleared.
                  if (!widget.openOnFocus) _close();
                } else if (!_isOpen && widget.focusNode.hasFocus) {
                  _open();
                }
                _refreshOverlay();
              },
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: Icon(widget.hintIcon, size: 20),
                isDense: true,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final tokens = context.webTokens;
    final items = widget.items;

    Widget content;
    if (items.isNotEmpty) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.loading) const LinearProgressIndicator(minHeight: 2),
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemExtent: kWebSearchDropdownTileHeight,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final highlighted = index == _highlighted;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // onTapDown fires before the field's focus is lost, so the
                  // selection lands even though the tap dismisses the field.
                  onTapDown: (_) => _select(items[index]),
                  child: MouseRegion(
                    onEnter: (_) {
                      if (_highlighted == index) return;
                      _highlighted = index;
                      _refreshOverlay();
                    },
                    child: widget.itemBuilder(
                      context,
                      items[index],
                      highlighted,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else if (widget.loading) {
      content = const _DropdownMessage(
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (widget.emptyLabel != null) {
      content = _DropdownMessage(child: Text(widget.emptyLabel!));
    } else {
      return const SizedBox.shrink();
    }

    return Positioned(
      width: _fieldWidth,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: _openUpward ? Alignment.topLeft : Alignment.bottomLeft,
        followerAnchor: _openUpward ? Alignment.bottomLeft : Alignment.topLeft,
        offset: Offset(0, _openUpward ? -_overlayGap : _overlayGap),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: _overlayMaxHeight),
          child: Container(
            decoration: BoxDecoration(
              color: WebPalette.cardBright,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(color: WebPalette.hairline),
              boxShadow: WebPalette.modalShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(color: Colors.transparent, child: content),
          ),
        ),
      ),
    );
  }
}

class _DropdownMessage extends StatelessWidget {
  const _DropdownMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: DefaultTextStyle(
        style: Theme.of(
          context,
        ).textTheme.bodySmall!.copyWith(color: WebPalette.inkSoft),
        child: IconTheme.merge(
          data: const IconThemeData(color: WebPalette.inkSoft),
          child: Center(child: child),
        ),
      ),
    );
  }
}
