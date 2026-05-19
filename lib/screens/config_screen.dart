import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sip_account.dart';
import '../services/sip_service.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key, this.firstSetup = false});
  final bool firstSetup;

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _display = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _domain = TextEditingController();
  final _ws = TextEditingController();
  final _authUser = TextEditingController();
  final _outbound = TextEditingController();
  bool _registerOnStart = true;
  bool _showPass = false;
  bool _showAdvanced = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = context.read<StorageService>();
    final a = await storage.loadAccount();
    setState(() {
      _display.text = a.displayName;
      _user.text = a.username;
      _pass.text = a.password;
      _domain.text = a.domain;
      _ws.text = a.wsUri;
      _authUser.text = a.authUser ?? '';
      _outbound.text = a.outboundProxy ?? '';
      _registerOnStart = a.registerOnStart;
    });
  }

  @override
  void dispose() {
    _display.dispose();
    _user.dispose();
    _pass.dispose();
    _domain.dispose();
    _ws.dispose();
    _authUser.dispose();
    _outbound.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final account = SipAccount(
      displayName: _display.text.trim(),
      username: _user.text.trim(),
      password: _pass.text,
      domain: _domain.text.trim(),
      wsUri: _ws.text.trim(),
      authUser: _authUser.text.trim().isEmpty ? null : _authUser.text.trim(),
      outboundProxy:
          _outbound.text.trim().isEmpty ? null : _outbound.text.trim(),
      registerOnStart: _registerOnStart,
    );

    final storage = context.read<StorageService>();
    final sip = context.read<SipService>();
    await storage.saveAccount(account);
    await sip.register(account);

    if (!mounted) return;
    setState(() => _saving = false);

    if (widget.firstSetup) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.firstSetup
            ? 'Configurar conta SIP'
            : 'Conta SIP'),
        leading: widget.firstSetup ? const SizedBox.shrink() : null,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (widget.firstSetup) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Informe os dados do seu PABX SIP. O servidor precisa '
                          'expor WebSocket Seguro (WSS) — padrão em FreePBX/Asterisk.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _section('Identidade'),
              TextFormField(
                controller: _display,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nome de exibição',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _user,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ramal (usuário)',
                  prefixIcon: Icon(Icons.dialpad_rounded),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe o ramal' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pass,
                obscureText: !_showPass,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_showPass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Informe a senha' : null,
              ),
              const SizedBox(height: 22),
              _section('Servidor'),
              TextFormField(
                controller: _domain,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Domínio / IP',
                  hintText: 'pbx.empresa.com.br',
                  prefixIcon: Icon(Icons.dns_outlined),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe o domínio' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _ws,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'WebSocket (WSS) URI',
                  hintText: 'wss://pbx.empresa.com.br:8089/ws',
                  prefixIcon: Icon(Icons.cable_rounded),
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Informe o WSS';
                  if (!s.startsWith('wss://') && !s.startsWith('ws://')) {
                    return 'Deve começar com wss:// ou ws://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _registerOnStart,
                onChanged: (v) => setState(() => _registerOnStart = v),
                title: const Text('Registrar ao iniciar'),
                subtitle: const Text('Conectar automaticamente quando o app abrir'),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        _showAdvanced
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Avançado',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _showAdvanced
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _authUser,
                      decoration: const InputDecoration(
                        labelText: 'Usuário de autenticação (opcional)',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _outbound,
                      decoration: const InputDecoration(
                        labelText: 'Outbound proxy (opcional)',
                        prefixIcon: Icon(Icons.alt_route_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_saving ? 'Conectando…' : 'Salvar e conectar'),
              ),
              if (!widget.firstSetup) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<SipService>().unregister();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Desconectado')),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Desconectar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(
          t.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1.3,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
        ),
      );
}
