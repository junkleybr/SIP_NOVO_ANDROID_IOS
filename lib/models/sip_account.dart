/// Conta SIP do usuário. Persistida via SharedPreferences.
class SipAccount {
  final String displayName;
  final String username; // ramal
  final String password;
  final String domain; // servidor SIP (ex: pbx.empresa.com.br)
  final String wsUri; // ex: wss://pbx.empresa.com.br:8089/ws
  final String? authUser; // opcional, se diferente do username
  final String? outboundProxy;
  final int port;
  final SipTransport transport;
  final bool registerOnStart;

  const SipAccount({
    required this.displayName,
    required this.username,
    required this.password,
    required this.domain,
    required this.wsUri,
    this.authUser,
    this.outboundProxy,
    this.port = 5060,
    this.transport = SipTransport.wss,
    this.registerOnStart = true,
  });

  String get sipUri => 'sip:$username@$domain';

  SipAccount copyWith({
    String? displayName,
    String? username,
    String? password,
    String? domain,
    String? wsUri,
    String? authUser,
    String? outboundProxy,
    int? port,
    SipTransport? transport,
    bool? registerOnStart,
  }) {
    return SipAccount(
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      password: password ?? this.password,
      domain: domain ?? this.domain,
      wsUri: wsUri ?? this.wsUri,
      authUser: authUser ?? this.authUser,
      outboundProxy: outboundProxy ?? this.outboundProxy,
      port: port ?? this.port,
      transport: transport ?? this.transport,
      registerOnStart: registerOnStart ?? this.registerOnStart,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'username': username,
        'password': password,
        'domain': domain,
        'wsUri': wsUri,
        'authUser': authUser,
        'outboundProxy': outboundProxy,
        'port': port,
        'transport': transport.name,
        'registerOnStart': registerOnStart,
      };

  factory SipAccount.fromJson(Map<String, dynamic> j) => SipAccount(
        displayName: j['displayName'] as String? ?? '',
        username: j['username'] as String? ?? '',
        password: j['password'] as String? ?? '',
        domain: j['domain'] as String? ?? '',
        wsUri: j['wsUri'] as String? ?? '',
        authUser: j['authUser'] as String?,
        outboundProxy: j['outboundProxy'] as String?,
        port: j['port'] as int? ?? 5060,
        transport: SipTransport.values.firstWhere(
          (t) => t.name == (j['transport'] ?? 'wss'),
          orElse: () => SipTransport.wss,
        ),
        registerOnStart: j['registerOnStart'] as bool? ?? true,
      );

  static const empty = SipAccount(
    displayName: '',
    username: '',
    password: '',
    domain: '',
    wsUri: '',
  );

  bool get isConfigured =>
      username.isNotEmpty &&
      domain.isNotEmpty &&
      password.isNotEmpty &&
      wsUri.isNotEmpty;
}

enum SipTransport { wss, ws, tcp, udp, tls }
