import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/call_log.dart';
import '../services/call_log_service.dart';
import '../services/sip_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final log = context.watch<CallLogService>();
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text('Histórico',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              if (log.entries.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Limpar histórico?'),
                        content: const Text(
                            'Todas as chamadas serão apagadas deste aparelho.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar')),
                          FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Limpar')),
                        ],
                      ),
                    );
                    if (ok == true) log.clear();
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: log.entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded,
                          size: 64, color: cs.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      Text('Sem chamadas ainda',
                          style: TextStyle(
                              color: cs.onSurface.withOpacity(0.5))),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: log.entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) => _HistoryTile(entry: log.entries[i]),
                ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});
  final CallLogEntry entry;

  IconData get _icon {
    switch (entry.direction) {
      case CallDirection.incoming:
        return Icons.call_received_rounded;
      case CallDirection.outgoing:
        return Icons.call_made_rounded;
      case CallDirection.missed:
        return Icons.call_missed_rounded;
    }
  }

  Color _color(BuildContext c) {
    switch (entry.direction) {
      case CallDirection.incoming:
        return const Color(0xFF22C55E);
      case CallDirection.outgoing:
        return Theme.of(c).colorScheme.primary;
      case CallDirection.missed:
        return const Color(0xFFEF4444);
    }
  }

  String _formatDur(Duration d) {
    if (d.inSeconds == 0) return '—';
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM HH:mm', 'pt_BR');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.read<SipService>().dial(entry.number),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _color(context).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _color(context), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name ?? entry.number,
                        style:
                            Theme.of(context).textTheme.titleMedium),
                    Text(
                      '${df.format(entry.startedAt)}  •  ${_formatDur(entry.duration)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.phone_rounded,
                    color: Theme.of(context).colorScheme.primary),
                onPressed: () =>
                    context.read<SipService>().dial(entry.number),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
