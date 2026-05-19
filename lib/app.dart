import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/call_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/sip_service.dart';
import 'theme/app_theme.dart';

/// Navigator global — usado pelo observador de chamadas para empurrar
/// a tela de chamada de qualquer lugar do app.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

class Visual2VozApp extends StatelessWidget {
  const Visual2VozApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'visual2.voz',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      // Observer fica fora da árvore de rotas — não some quando o
      // splash dá pushReplacement.
      builder: (context, child) =>
          _CallObserver(child: child ?? const SizedBox.shrink()),
      home: const SplashScreen(),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/call': (_) => const CallScreen(),
      },
    );
  }
}

/// Envolve a árvore inteira observando o `SipService`. Quando uma
/// chamada começa (entrada ou saída), empurra a tela de chamada
/// no Navigator raiz — funciona em qualquer ponto do app.
class _CallObserver extends StatefulWidget {
  const _CallObserver({required this.child});
  final Widget child;

  @override
  State<_CallObserver> createState() => _CallObserverState();
}

class _CallObserverState extends State<_CallObserver> {
  bool _onCallScreen = false;
  SipService? _sip;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sip = context.read<SipService>();
    if (_sip != sip) {
      _sip?.removeListener(_onSipChanged);
      _sip = sip;
      _sip!.addListener(_onSipChanged);
    }
  }

  @override
  void dispose() {
    _sip?.removeListener(_onSipChanged);
    super.dispose();
  }

  void _onSipChanged() {
    if (_sip == null) return;
    final s = _sip!.callState;
    final hasActiveCall = _sip!.currentCall != null &&
        (s == SipCallState.ringing ||
            s == SipCallState.calling ||
            s == SipCallState.connecting ||
            s == SipCallState.active);

    if (hasActiveCall && !_onCallScreen) {
      _onCallScreen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = rootNavigatorKey.currentState;
        if (nav == null) return;
        nav
            .push(MaterialPageRoute(builder: (_) => const CallScreen()))
            .then((_) => _onCallScreen = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
