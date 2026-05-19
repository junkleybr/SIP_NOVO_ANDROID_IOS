import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../services/sip_service.dart';
import '../theme/app_theme.dart';

class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  String _number = '';

  void _press(String d) async {
    HapticFeedback.lightImpact();
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 20);
    }
    setState(() => _number += d);
  }

  void _backspace() {
    if (_number.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _number = _number.substring(0, _number.length - 1));
  }

  void _clear() {
    HapticFeedback.mediumImpact();
    setState(() => _number = '');
  }

  Future<void> _call() async {
    if (_number.isEmpty) return;
    final sip = context.read<SipService>();
    if (sip.regState != SipRegState.registered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aguarde o registro SIP completar')),
      );
      return;
    }
    final ok = await sip.dial(_number);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível iniciar a chamada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 14),
        // Display do número discado
        Expanded(
          flex: 3,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      _number.isEmpty ? 'Digite um número' : _number,
                      key: ValueKey(_number.isEmpty),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: _number.isEmpty ? 22 : 44,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                        color: _number.isEmpty
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (_number.isNotEmpty)
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onLongPress: _clear,
                        child: IconButton(
                          onPressed: _backspace,
                          icon: const Icon(Icons.backspace_outlined),
                          tooltip: 'Apagar (segure para limpar)',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Grid de teclas
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                Expanded(child: _row(['1', '2', '3'])),
                Expanded(child: _row(['4', '5', '6'])),
                Expanded(child: _row(['7', '8', '9'])),
                Expanded(child: _row(['*', '0', '#'], plusOnZero: true)),
                const SizedBox(height: 10),
                _callButton(),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(List<String> digits, {bool plusOnZero = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((d) => Expanded(
                child: _DialKey(
                  digit: d,
                  subLabel: _subLabel(d),
                  onPress: () => _press(d),
                  onLongPress: plusOnZero && d == '0'
                      ? () {
                          HapticFeedback.mediumImpact();
                          setState(() => _number += '+');
                        }
                      : null,
                ),
              ))
          .toList(),
    );
  }

  static String? _subLabel(String d) {
    const map = {
      '2': 'ABC',
      '3': 'DEF',
      '4': 'GHI',
      '5': 'JKL',
      '6': 'MNO',
      '7': 'PQRS',
      '8': 'TUV',
      '9': 'WXYZ',
      '0': '+',
    };
    return map[d];
  }

  Widget _callButton() {
    return SizedBox(
      width: 76,
      height: 76,
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: AppColors.primary.withOpacity(0.5),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _call,
          child: const Icon(
            Icons.phone_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _DialKey extends StatefulWidget {
  const _DialKey({
    required this.digit,
    required this.onPress,
    this.subLabel,
    this.onLongPress,
  });
  final String digit;
  final String? subLabel;
  final VoidCallback onPress;
  final VoidCallback? onLongPress;

  @override
  State<_DialKey> createState() => _DialKeyState();
}

class _DialKeyState extends State<_DialKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0,
    upperBound: 0.08,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) => _c.reverse(),
        onTapCancel: () => _c.reverse(),
        onTap: widget.onPress,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) => Transform.scale(
            scale: 1 - _c.value,
            child: child,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.digit,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (widget.subLabel != null)
                  Text(
                    widget.subLabel!,
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.4,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
