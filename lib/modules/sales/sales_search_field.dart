import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The sales-history search box.
///
/// The field owns its `TextEditingController`, because the widget that renders
/// a controller must be the one that disposes it. It used to live on
/// `SalesController`, and GetX ties a lazy instance to the route that created
/// it: when that route went away, GetX closed the controller and disposed the
/// text controller underneath a screen that was still mounted, so the next
/// rebuild of the field threw "A TextEditingController was used after being
/// disposed". Nothing outside a widget's own state should hold it.
///
/// [query] stays the shared filter value: typing writes it, and emptying it
/// elsewhere (the "clear filters" button) empties the visible text too, so the
/// box and the list can never disagree.
class SalesSearchField extends StatefulWidget {
  const SalesSearchField({super.key, required this.query});

  /// The value the history list is filtered by.
  final RxString query;

  @override
  State<SalesSearchField> createState() => _SalesSearchFieldState();
}

class _SalesSearchFieldState extends State<SalesSearchField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.query.value,
  );

  /// Keeps the box in step with the shared filter value.
  Worker? _sync;

  @override
  void initState() {
    super.initState();
    _listenToQuery();
  }

  @override
  void didUpdateWidget(SalesSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The screen re-finds its controller on every build, so a rebuild can
    // hand this field a different filter. Follow the new one instead of
    // staying wired to a filter nothing reads any more.
    if (widget.query != oldWidget.query) {
      _sync?.dispose();
      _listenToQuery();
      // Showing the new value writes to the text controller, which marks the
      // field for repaint — not something to start from inside a build, so
      // wait for the frame to finish.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _adoptQuery();
      });
    }
  }

  void _listenToQuery() {
    _sync = ever(widget.query, (_) => _adoptQuery());
  }

  /// Shows the shared filter value, unless the box already shows it — writing
  /// the same text back would move the cursor to the end mid-keystroke.
  void _adoptQuery() {
    final query = widget.query.value;
    if (query == _text.text) return;
    _text.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  @override
  void dispose() {
    _sync?.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TextField(
        controller: _text,
        decoration: InputDecoration(
          hintText: 'Search by invoice no, customer or item...',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          filled: true,
          suffixIcon: Obx(() {
            if (widget.query.value.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                widget.query.value = '';
                _adoptQuery();
              },
            );
          }),
        ),
        onChanged: (value) => widget.query.value = value,
      ),
    );
  }
}
