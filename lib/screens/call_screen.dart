import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/call_log.dart';
import '../services/call_log_service.dart';
import '../services/sip_service.dart';
import '../theme/app_theme.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? _ticker;
  DateTime? _loggedStart;
  bool _logged = false;
  bool _popping = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _loggedStart = DateTime.now();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
    }
    return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }

  Future<void> _logCall(SipService sip, CallDirection dir) async {
    final remote = sip.remoteIdentity ?? sip.lastRemoteIdentity ?? '';
    // Tenta extrair só o número da URI (sip:1234@dominio)
    final match = RegExp(r'sip:([^@]+)@').firstMatch(remote);
    final number =
        match?.group(1) ?? remote.replaceAll('"', '').trim();
    final dur = sip.callStartedAt != null
        ? DateTime.now().difference(sip.callStartedAt!)
        : sip.lastCallDuration;
    await context.read<CallLogService>().add(
          number: number,
          duration: dur,
          direction: dir,
          startedAt: _loggedStart ?? DateTime.now(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final sip = context.watch<SipService>();
    final state = sip.callState;
    final isIncoming = sip.currentCall?.direction == 'INCOMING' &&
        state == SipCallState.ringing;

    // Encerrou enquanto estávamos na tela.
    if ((state == SipCallState.ended || state == SipCallState.failed) &&
        !_popping) {
      _popping = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (!_logged) {
          _logged = true;
          final isOutgoing = !isIncoming;
          await _logCall(
            sip,
            state == SipCallState.failed && isIncoming
                ? CallDirection.missed
                : (isOutgoing
                    ? CallDirection.outgoing
                    : CallDirection.incoming),
          );
        }
        if (mounted) Navigator.of(context).maybePop();
      });
    }

    final cs = Theme.of(context).colorScheme;
    final remote = sip.remoteIdentity ?? 'Desconhecido';
    final number = RegExp(r'sip:([^@]+)@').firstMatch(remote)?.group(1) ??
        remote.replaceAll('"', '').trim();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: state == SipCallState.active
                ? [
                    cs.surface,
                    cs.surfaceContainerHighest,
                  ]
                : [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _statusText(state, isIncoming, sip),
              const SizedBox(height: 36),
              _avatar(number, state == SipCallState.active),
              const SizedBox(height: 22),
              Text(
                number,
                style: TextStyle(
                  color: state == SipCallState.active
                      ? cs.onSurface
                      : Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              if (state == SipCallState.active && sip.callStartedAt != null)
                Text(
                  _formatDuration(
                    DateTime.now().difference(sip.callStartedAt!),
                  ),
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.7),
                    fontSize: 18,
                  ),
                ),
              const Spacer(),
              if (state == SipCallState.active) _activeControls(sip),
              if (state == SipCallState.calling ||
                  state == SipCallState.connecting)
                _outgoingControls(sip),
              if (isIncoming) _incomingControls(sip),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusText(SipCallState s, bool incoming, SipService sip) {
    String t;
    switch (s) {
      case SipCallState.ringing:
        t = incoming ? 'Chamada recebida' : 'Tocando…';
        break;
      case SipCallState.calling:
        t = 'Chamando…';
        break;
      case SipCallState.connecting:
        t = 'Conectando…';
        break;
      case SipCallState.active:
        t = 'Em chamada';
        break;
      case SipCallState.held:
        t = 'Em espera';
        break;
      case SipCallState.failed:
        t = 'Falha na chamada';
        break;
      case SipCallState.ended:
        t = 'Chamada encerrada';
        break;
      default:
        t = '';
    }
    return Text(
      t,
      style: TextStyle(
        color: s == SipCallState.active
            ? Theme.of(context).colorScheme.primary
            : Colors.white.withOpacity(0.85),
        fontSize: 15,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _avatar(String number, bool active) {
    final initial = number.isNotEmpty ? number[0].toUpperCase() : '?';
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primary.withOpacity(0.12) : Colors.white24,
        border: Border.all(
          color: active ? AppColors.primary : Colors.white,
          width: 3,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: active ? AppColors.primary : Colors.white,
          fontSize: 56,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _activeControls(SipService sip) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ToggleAction(
                icon: sip.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: 'Mute',
                active: sip.muted,
                onTap: sip.toggleMute,
              ),
              _ToggleAction(
                icon: Icons.dialpad_rounded,
                label: 'Teclado',
                onTap: () => _showDtmfPad(sip),
              ),
              _ToggleAction(
                icon: sip.speakerOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_down_rounded,
                label: 'Alto-falante',
                active: sip.speakerOn,
                onTap: sip.toggleSpeaker,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ToggleAction(
                icon: sip.onHold
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                label: sip.onHold ? 'Retomar' : 'Espera',
                active: sip.onHold,
                onTap: sip.toggleHold,
              ),
              _ToggleAction(
                icon: Icons.swap_calls_rounded,
                label: 'Transferir',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transferência em breve'),
                    ),
                  );
                },
              ),
              _ToggleAction(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Adicionar',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Conferência em breve')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        _endCallButton(sip),
      ],
    );
  }

  Widget _outgoingControls(SipService sip) {
    return _endCallButton(sip);
  }

  Widget _incomingControls(SipService sip) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _RoundActionButton(
            color: AppColors.danger,
            icon: Icons.call_end_rounded,
            label: 'Recusar',
            onTap: () => sip.reject(),
          ),
          _RoundActionButton(
            color: AppColors.success,
            icon: Icons.call_rounded,
            label: 'Atender',
            onTap: () => sip.answer(),
          ),
        ],
      ),
    );
  }

  Widget _endCallButton(SipService sip) {
    return _RoundActionButton(
      color: AppColors.danger,
      icon: Icons.call_end_rounded,
      label: 'Encerrar',
      onTap: () => sip.hangup(),
    );
  }

  void _showDtmfPad(SipService sip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: ['1','2','3','4','5','6','7','8','9','*','0','#']
                  .map((d) => SizedBox(
                        width: 72,
                        height: 72,
                        child: Material(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              sip.sendDtmf(d);
                            },
                            child: Center(
                              child: Text(d,
                                  style: const TextStyle(fontSize: 26)),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleAction extends StatelessWidget {
  const _ToggleAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          shape: const CircleBorder(),
          color: active
              ? AppColors.primary
              : cs.surfaceContainerHighest.withOpacity(0.55),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Icon(
                icon,
                color: active ? Colors.white : cs.onSurface,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withOpacity(0.7))),
      ],
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.color,
    required this.icon,
    required this.onTap,
    required this.label,
  });
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 78,
          height: 78,
          child: Material(
            color: color,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: color.withOpacity(0.5),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Icon(icon, color: Colors.white, size: 34),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
