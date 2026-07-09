import 'package:flutter/material.dart';

/// Loads a deferred library, then builds the page.
///
/// Use with Flutter deferred imports:
/// ```dart
/// DeferredPage(
///   load: bill_list.loadLibrary,
///   builder: () => bill_list.WebBillListPage(...),
/// )
/// ```
class DeferredPage extends StatefulWidget {
  const DeferredPage({super.key, required this.load, required this.builder});

  final Future<void> Function() load;
  final Widget Function() builder;

  @override
  State<DeferredPage> createState() => _DeferredPageState();
}

class _DeferredPageState extends State<DeferredPage> {
  late final Future<void> _loading;

  @override
  void initState() {
    super.initState();
    _loading = widget.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Failed to load page: ${snapshot.error}')),
          );
        }
        return widget.builder();
      },
    );
  }
}
