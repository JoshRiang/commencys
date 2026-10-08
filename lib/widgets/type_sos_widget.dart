import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/incident.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'urgency_labels.dart';

/// Type-SOS home widget: one minimal textbox + send, Laya triages.
///
/// Flow (minimal taps): type what happened → send → GPS auto-attached →
/// POST `/api/sos` with the text as description → ticket lands with a
/// plain-language urgency pill. No category / urgency pickers — Laya
/// (AI + coordinator review) decides triage afterwards.
///
/// Glass style matches the home hero; errors stay inline (no dead end).
class TypeSosWidget extends StatefulWidget {
  final VoidCallback? onSent;

  const TypeSosWidget({super.key, this.onSent});

  @override
  State<TypeSosWidget> createState() => _TypeSosWidgetState();
}

class _TypeSosWidgetState extends State<TypeSosWidget> {
  final _ctrl = TextEditingController();
  final _api = ApiClient();
  final _location = LocationService();

  bool _sending = false;
  String? _error;
  Incident? _ticket;

  @override
  void dispose() {
    _ctrl.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
      _ticket = null;
    });
    try {
      final pos = await _location.currentPosition();
      if (pos == null) {
        throw Exception('location unavailable — enable GPS');
      }
      final ticket = await _api.sendSos(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracyM: pos.accuracy,
        description: text,
        reporterName: 'App User',
      );
      if (!mounted) return;
      setState(() => _ticket = ticket);
      _ctrl.clear();
      HapticFeedback.heavyImpact();
      widget.onSent?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().contains('location')
          ? 'No location yet — turn on GPS and tap Send SOS again.'
          : 'Could not send — check connection and tap Send SOS again.');
      HapticFeedback.vibrate();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    return LiquidGlass(
      radius: 24,
      blur: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.keyboard_rounded,
                color: AppColors.info,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type SOS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Can’t talk? Just type — Laya triages it',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                color: AppColors.secondary,
                tooltip: 'Clear text',
                // 44x44 accessible target around the 18 pt glyph.
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                onPressed: _sending
                    ? null
                    : () {
                        _ctrl.clear();
                        setState(() {});
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            minLines: 2,
            maxLines: 4,
            maxLength: 280,
            // Chat-style keyboard with a real Send action — the text
            // is a short incident note, so autocorrect/cap-sentences on.
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.send,
            textCapitalization: TextCapitalization.sentences,
            autocorrect: true,
            onSubmitted: (_) => _send(),
            enabled: !_sending,
            decoration: const InputDecoration(
              // Separate label (persists) + hint (example) — the hint
              // alone must never carry the meaning.
              labelText: 'What happened?',
              hintText: 'e.g. Kebakaran di lantai 2 kos…',
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.accentDeep,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (ticket != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF15803D),
                    size: 16,
                    semanticLabel: 'Sent',
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sent as ${UrgencyLabels.forUrgency(ticket.urgency)} — ticket ${ticket.id}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Pill(
                    label: UrgencyLabels.forUrgency(ticket.urgency),
                    bg: UrgencyLabels.urgencyBg(ticket.urgency),
                    fg: UrgencyLabels.urgencyFg(ticket.urgency),
                    icon: Icons.bolt_rounded,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              button: true,
              enabled: !_sending,
              // Short verb label; the 280-char note limit is visible
              // in the field, not repeated on the button.
              label: _sending ? 'Sending SOS' : 'Send SOS',
              child: FilledButton.icon(
                onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 19),
              label: Text(_sending ? 'Sending…' : 'Send SOS'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
