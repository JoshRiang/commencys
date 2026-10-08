import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/incident.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'urgency_labels.dart';

/// Voice-SOS widget (SOS tab): one tap → speak → auto-send.
///
/// Flow (minimal taps): tap mic → record (max 60 s, tap again to stop
/// early) → GPS auto-attached → multipart POST `/api/sos-voice` with a
/// single honest progress bar → ticket lands with a plain-language
/// urgency pill. Laya triages from the audio + ticket afterwards.
///
/// Glass style matches the home hero; errors stay inline (no dead end).
enum _VoicePhase { idle, recording, uploading, done, error }

class VoiceSosWidget extends StatefulWidget {
  final VoidCallback? onSent;

  const VoiceSosWidget({super.key, this.onSent});

  @override
  State<VoiceSosWidget> createState() => _VoiceSosWidgetState();
}

class _VoiceSosWidgetState extends State<VoiceSosWidget> {
  final _recorder = AudioRecorder();
  final _api = ApiClient();
  final _location = LocationService();

  _VoicePhase _phase = _VoicePhase.idle;
  double _progress = 0;
  int _seconds = 0;
  Timer? _ticker;
  String _hint = 'Tap, speak, we send it.';
  Incident? _ticket;

  static const _maxSeconds = 60;

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<String> _clipPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/sos_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _toggle() async {
    if (_phase == _VoicePhase.recording) {
      await _stopAndSend();
    } else if (_phase == _VoicePhase.idle ||
        _phase == _VoicePhase.error ||
        _phase == _VoicePhase.done) {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      _phase = _VoicePhase.recording;
      _progress = 0;
      _seconds = 0;
      _ticket = null;
      _hint = 'Recording — describe what you see. Tap Stop and send.';
    });
    HapticFeedback.mediumImpact();
    try {
      // Mic permission is asked in context, right when the recorder
      // needs it — the purpose string lives in the manifest.
      if (!await _recorder.hasPermission()) {
        if (!mounted) return;
        setState(() {
          _phase = _VoicePhase.error;
          _hint = 'Mic blocked — allow microphone access, then retry.';
        });
        HapticFeedback.vibrate();
        return;
      }
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 16000,
        ),
        path: await _clipPath(),
      );
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (t) async {
        if (!mounted) return;
        setState(() {
          _seconds = t.tick;
          _progress = (_seconds / _maxSeconds).clamp(0.0, 1.0);
        });
        if (t.tick >= _maxSeconds) {
          await _stopAndSend();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _VoicePhase.error;
        _hint = 'Could not start recording: $e';
      });
    }
  }

  Future<void> _stopAndSend() async {
    _ticker?.cancel();
    final recordedS = _seconds;
    HapticFeedback.selectionClick();
    setState(() {
      _phase = _VoicePhase.uploading;
      _hint = 'Getting your location — nothing to type.';
    });
    try {
      final path = await _recorder.stop();
      if (path == null) {
        throw Exception('no audio captured');
      }
      final pos = await _location.currentPosition();
      if (pos == null) {
        throw Exception('location unavailable — enable GPS and retry');
      }
      setState(() => _hint = 'Sending voice SOS…');
      final ticket = await _api.sendSosVoice(
        audioFile: File(path),
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracyM: pos.accuracy,
        durationS: recordedS.toDouble(),
        reporterName: 'App User',
        onProgress01: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      // Best-effort clip cleanup; the server already acked the ticket.
      try {
        await File(path).delete();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _phase = _VoicePhase.done;
        _ticket = ticket;
        _progress = 1;
        _hint = 'Voice SOS received as ${UrgencyLabels.forUrgency(ticket.urgency)} — volunteers nearby are notified.';
      });
      HapticFeedback.heavyImpact();
      widget.onSent?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _VoicePhase.error;
        _hint = e.toString().contains('location')
            ? 'No location yet — turn on GPS and tap Try again.'
            : 'Could not send — check connection and tap Try again.';
      });
      HapticFeedback.vibrate();
    }
  }

  String get _clock {
    final m = (_seconds ~/ 60).toString();
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s / 1:00';
  }

  @override
  Widget build(BuildContext context) {
    final recording = _phase == _VoicePhase.recording;
    final uploading = _phase == _VoicePhase.uploading;
    final busy = recording || uploading;
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.sosStart, AppColors.sosEnd],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice SOS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'One tap — just speak',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (recording)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _clock,
                        style: const TextStyle(
                          color: AppColors.accentDeep,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (busy || _phase == _VoicePhase.done) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: Colors.black.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            _hint,
            style: TextStyle(
              color: _phase == _VoicePhase.error
                  ? AppColors.accentDeep
                  : AppColors.secondary,
              fontSize: 13,
              fontWeight: _phase == _VoicePhase.error
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          if (ticket != null) ...[
            const SizedBox(height: 8),
            Pill(
              label: UrgencyLabels.forUrgency(ticket.urgency),
              bg: UrgencyLabels.urgencyBg(ticket.urgency),
              fg: UrgencyLabels.urgencyFg(ticket.urgency),
              icon: Icons.bolt_rounded,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              button: true,
              enabled: !uploading,
              // Short label: the 60 s cap is announced while recording
              // via the timer + hint, not crammed onto the button.
              label: uploading
                  ? 'Sending voice SOS'
                  : recording
                      ? 'Stop recording and send voice SOS'
                      : 'Record voice SOS',
              child: FilledButton.icon(
                onPressed: uploading ? null : _toggle,
              icon: uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      recording
                          ? Icons.stop_rounded
                          : _phase == _VoicePhase.done
                              ? Icons.refresh_rounded
                              : Icons.mic_rounded,
                      size: 20,
                    ),
              label: Text(
                uploading
                    ? 'Sending…'
                    : recording
                        ? 'Stop and send'
                        : _phase == _VoicePhase.done
                            ? 'Record again'
                            : _phase == _VoicePhase.error
                                ? 'Try again'
                                : 'Record voice SOS',
              ),
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
