import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.EventListener? _listener;

/// Enables the browser's native "leave site?" prompt on refresh/close.
void setWebBeforeUnloadGuard(bool enabled) {
  if (enabled) {
    _listener ??= ((web.Event event) {
      event.preventDefault();
      // Chrome ignores custom strings; a non-empty returnValue still triggers
      // the generic leave confirmation.
      (event as web.BeforeUnloadEvent).returnValue = '';
    }).toJS;
    web.window.addEventListener('beforeunload', _listener!);
    return;
  }
  if (_listener != null) {
    web.window.removeEventListener('beforeunload', _listener!);
    _listener = null;
  }
}
