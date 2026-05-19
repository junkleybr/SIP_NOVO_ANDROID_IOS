import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../services/sip_service.dart';
import 'config_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sip = context.watch<SipService>();
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text('Ajustes', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        _card(context, [
          ListTile(
            leading: Icon(Icons.account_circle_outlined, color: cs.primary),
            title: const Text('Conta SIP'),
            subtitle: Text(sip.account.isConfigured
                ? '${sip.account.username}@${sip.account.domain}'
                : 'Não configurada'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ConfigScreen())),
          ),
          const Divider(height: 0),
          ListTile(
            leading: Icon(Icons.refresh_rounded, color: cs.primary),
            title: const Text('Reconectar agora'),
            subtitle: const Text('Forçar novo registro SIP'),
            onTap: () => sip.register(sip.account),
          ),
        ]),
        const SizedBox(height: 16),
        _card(context, [
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: cs.primary),
            title: const Text('Sobre'),
            subtitle: const Text('visual2.voz — Visual2 Voz'),
            onTap: () => _showAbout(context),
          ),
          const Divider(height: 0),
          ListTile(
            leading: Icon(Icons.help_outline_rounded, color: cs.primary),
            title: const Text('Como configurar o servidor SIP'),
            onTap: () => _showHelp(context),
          ),
        ]),
      ],
    );
  }

  Widget _card(BuildContext context, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(children: children),
      ),
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'visual2.voz',
      applicationVersion: '${info.version} (${info.buildNumber})',
      applicationLegalese: '© Visual2 Voz',
      children: const [
        SizedBox(height: 8),
        Text('Aplicativo SIP Mobile da Visual2 Voz para Android e iOS, '
            'construído em Flutter sobre sip_ua e WebRTC.'),
      ],
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Configuração do servidor SIP',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text(
              'Este app conecta no seu PABX via WebSocket Seguro (WSS). '
              'Em FreePBX/Asterisk, habilite o WebRTC no chan_pjsip e '
              'aponte o WSS para a porta 8089 (padrão). Exemplo:\n\n'
              '  wss://pbx.empresa.com.br:8089/ws\n\n'
              'Certificado: deve ser válido (Let\'s Encrypt funciona). '
              'O ramal precisa estar com transport=ws ou wss e DTLS habilitado.',
            ),
          ],
        ),
      ),
    );
  }
}
