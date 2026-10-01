import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/incident.dart';
import 'app_config.dart';

/// WebSocket coordination channel for live incident alerts.
///
/// Implements the spec §3 trade-off: auto-reconnect with exponential backoff
/// on flaky mobile networks, plus REST re-sync via [fetchIncidents].
/// Server frames follow docs/api-contract.md (`incident.*` events).
class CoordinationSocket {
  final String url;
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<IncidentStatus>.broadcast();
  Timer? _reconnectTimer;
  int _attempt = 0;
  bool _disposed = false;

  CoordinationSocket({String? url}) : url = url ?? AppConfig.wsUrl;

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  /// Parsed lifecycle transitions from `incident.*` frames.
  Stream<IncidentStatus> get statuses => _statusController.stream;

  bool get isConnected => _channel != null;

  void connect() {
    if (_disposed) return;
    disconnect();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _attempt = 0;
      _channel!.stream.listen(
        (event) {
          try {
            final decoded = jsonDecode(event as String);
            if (decoded is Map<String, dynamic>) {
              _controller.add(decoded);
              final status = _statusFromFrame(decoded);
              if (status != null) _statusController.add(status);
            }
          } catch (_) {
            // Ignore malformed frames.
          }
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  IncidentStatus? _statusFromFrame(Map<String, dynamic> frame) {
    final type = frame['type']?.toString() ?? '';
    if (type == 'incident.sos' || type == 'incident.created') {
      return IncidentStatus.acknowledged;
    }
    final status = frame['status']?.toString();
    if (status == null) return null;
    for (final s in IncidentStatus.values) {
      if (s.name == status) return s;
    }
    return null;
  }

  void _scheduleReconnect() {
    _channel = null;
    if (_disposed) return;
    _reconnectTimer?.cancel();
    // Exponential backoff capped at 30 s (flaky-network trade-off, spec D3).
    final delay = Duration(seconds: min(1 << min(_attempt, 5), 30));
    _attempt++;
    _reconnectTimer = Timer(delay, connect);
  }

  void send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _controller.close();
    _statusController.close();
  }
}
