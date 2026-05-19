import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sip_ua/sip_ua.dart';

import '../models/sip_account.dart';

/// Estado simplificado da chamada para a UI.
enum SipCallState {
  none,
  ringing, // tocando (de entrada)
  calling, // discando (de saída)
  connecting, // estabelecendo mídia
  active, // conversação ativa
  held, // em espera
  ended, // encerrada
  failed,
}

/// Estado de registro SIP.
enum SipRegState { unregistered, registering, registered, registrationFailed }

/// Camada de aplicação que envolve o sip_ua e expõe um ChangeNotifier
/// fácil de consumir pela UI (via Provider).
class SipService extends ChangeNotifier implements SipUaHelperListener {
  SipService();

  final SIPUAHelper _helper = SIPUAHelper();

  SipAccount _account = SipAccount.empty;
  SipAccount get account => _account;

  SipRegState _regState = SipRegState.unregistered;
  SipRegState get regState => _regState;
  String? _regError;
  String? get registrationError => _regError;

  Call? _currentCall;
  Call? get currentCall => _currentCall;

  SipCallState _callState = SipCallState.none;
  SipCallState get callState => _callState;

  String? _remoteIdentity;
  String? get remoteIdentity => _remoteIdentity;

  DateTime? _callStartedAt;
  DateTime? get callStartedAt => _callStartedAt;

  /// Duração da última chamada encerrada (preservada após reset).
  Duration _lastDuration = Duration.zero;
  Duration get lastCallDuration => _lastDuration;
  String? _lastRemote;
  String? get lastRemoteIdentity => _lastRemote;

  bool _muted = false;
  bool get muted => _muted;
  bool _speaker = false;
  bool get speakerOn => _speaker;
  bool _onHold = false;
  bool get onHold => _onHold;

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _helper.addSipUaHelperListener(this);
    _initialized = true;
  }

  @override
  void dispose() {
    _helper.removeSipUaHelperListener(this);
    super.dispose();
  }

  /// Conecta e registra com a conta SIP fornecida.
  Future<void> register(SipAccount account) async {
    _account = account;
    _regError = null;
    _regState = SipRegState.registering;
    notifyListeners();

    final settings = UaSettings();
    settings.webSocketUrl = account.wsUri;
    settings.webSocketSettings.allowBadCertificate = true;
    settings.uri = account.sipUri;
    settings.authorizationUser = account.authUser ?? account.username;
    settings.password = account.password;
    settings.displayName =
        account.displayName.isEmpty ? account.username : account.displayName;
    settings.userAgent = 'visual2.voz/2.0 (Flutter)';
    settings.transportType = TransportType.WSS;
    settings.register = account.registerOnStart;
    settings.sessionTimers = false;
    settings.iceServers = const [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ];

    try {
      _helper.start(settings);
    } catch (e) {
      _regState = SipRegState.registrationFailed;
      _regError = e.toString();
      notifyListeners();
    }
  }

  Future<void> unregister() async {
    try {
      _helper.unregister();
    } catch (_) {}
    _regState = SipRegState.unregistered;
    notifyListeners();
  }

  /// Disca para `target` (apenas dígitos ou SIP URI).
  Future<bool> dial(String target, {bool video = false}) async {
    if (target.trim().isEmpty) return false;
    final dest = target.contains('@')
        ? target
        : 'sip:${target.trim()}@${_account.domain}';
    try {
      return await _helper.call(dest, voiceOnly: !video);
    } catch (e) {
      debugPrint('Erro ao discar: $e');
      return false;
    }
  }

  void hangup() {
    _currentCall?.hangup({'status_code': 603});
  }

  void answer({bool video = false}) {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': video,
    };
    _currentCall?.answer(_helper.buildCallOptions(!video),
        mediaConstraints: mediaConstraints);
  }

  void reject() {
    _currentCall?.hangup({'status_code': 486});
  }

  void toggleMute() {
    final call = _currentCall;
    if (call == null) return;
    if (_muted) {
      call.unmute(true, false);
    } else {
      call.mute(true, false);
    }
    _muted = !_muted;
    notifyListeners();
  }

  void toggleHold() {
    final call = _currentCall;
    if (call == null) return;
    if (_onHold) {
      call.unhold();
      _callState = SipCallState.active;
    } else {
      call.hold();
      _callState = SipCallState.held;
    }
    _onHold = !_onHold;
    notifyListeners();
  }

  void toggleSpeaker() {
    // O ajuste de saída é feito pelo flutter_webrtc; aqui só guardamos o flag
    // e a UI chama Helper.enableSpeakerphone via wrapper específico se desejar.
    _speaker = !_speaker;
    notifyListeners();
  }

  void sendDtmf(String digit) {
    _currentCall?.sendDTMF(digit, {'duration': 160});
  }

  Duration get currentDuration {
    if (_callStartedAt == null) return Duration.zero;
    return DateTime.now().difference(_callStartedAt!);
  }

  // ===== SipUaHelperListener =====

  @override
  void registrationStateChanged(RegistrationState state) {
    switch (state.state) {
      case RegistrationStateEnum.REGISTERED:
        _regState = SipRegState.registered;
        _regError = null;
        break;
      case RegistrationStateEnum.UNREGISTERED:
        _regState = SipRegState.unregistered;
        break;
      case RegistrationStateEnum.REGISTRATION_FAILED:
        _regState = SipRegState.registrationFailed;
        _regError = state.cause?.cause ?? 'Falha no registro';
        break;
      case RegistrationStateEnum.NONE:
      default:
        break;
    }
    notifyListeners();
  }

  @override
  void callStateChanged(Call call, CallState state) {
    _currentCall = call;
    _remoteIdentity = call.remote_identity ?? call.remote_display_name;

    switch (state.state) {
      case CallStateEnum.CALL_INITIATION:
        _callState = call.direction == 'OUTGOING'
            ? SipCallState.calling
            : SipCallState.ringing;
        break;
      case CallStateEnum.PROGRESS:
        _callState = SipCallState.calling;
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        _callState = SipCallState.active;
        _callStartedAt ??= DateTime.now();
        break;
      case CallStateEnum.HOLD:
        _callState = SipCallState.held;
        _onHold = true;
        break;
      case CallStateEnum.UNHOLD:
        _callState = SipCallState.active;
        _onHold = false;
        break;
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        _callState = state.state == CallStateEnum.FAILED
            ? SipCallState.failed
            : SipCallState.ended;
        _resetCallState();
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void _resetCallState() {
    if (_callStartedAt != null) {
      _lastDuration = DateTime.now().difference(_callStartedAt!);
    }
    _lastRemote = _remoteIdentity;
    _currentCall = null;
    _callStartedAt = null;
    _muted = false;
    _speaker = false;
    _onHold = false;
  }

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}
}
