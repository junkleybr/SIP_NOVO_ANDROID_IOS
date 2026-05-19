import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact_entry.dart';
import '../services/contacts_service.dart';
import '../services/sip_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ContactsService>();
    final cs = Theme.of(context).colorScheme;
    final filtered = svc.contacts
        .where((c) =>
            c.name.toLowerCase().contains(_q.toLowerCase()) ||
            c.number.contains(_q))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text('Contatos',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => _showEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Novo'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Buscar contato',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.contacts_outlined,
                          size: 64, color: cs.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      Text(
                        svc.contacts.isEmpty
                            ? 'Nenhum contato adicionado'
                            : 'Nada encontrado',
                        style:
                            TextStyle(color: cs.onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (_, i) => _Tile(
                    c: filtered[i],
                    onEdit: () => _showEditor(context, contact: filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  void _showEditor(BuildContext context, {ContactEntry? contact}) {
    final nameC = TextEditingController(text: contact?.name);
    final numC = TextEditingController(text: contact?.number);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(contact == null ? 'Novo contato' : 'Editar contato',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numC,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Número/ramal',
                  prefixIcon: Icon(Icons.dialpad_rounded),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (contact != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<ContactsService>().remove(contact.id);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Excluir'),
                      ),
                    ),
                  if (contact != null) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final svc = context.read<ContactsService>();
                        if (contact == null) {
                          svc.add(nameC.text.trim(), numC.text.trim());
                        } else {
                          svc.update(contact.copyWith(
                            name: nameC.text.trim(),
                            number: numC.text.trim(),
                          ));
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.c, required this.onEdit});
  final ContactEntry c;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.read<SipService>().dial(c.number),
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.primary.withOpacity(0.15),
                child: Text(
                  c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: cs.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(c.number,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  c.favorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: c.favorite
                      ? const Color(0xFFF59E0B)
                      : cs.onSurface.withOpacity(0.4),
                ),
                onPressed: () =>
                    context.read<ContactsService>().toggleFavorite(c.id),
              ),
              IconButton(
                icon: Icon(Icons.phone_rounded, color: cs.primary),
                onPressed: () => context.read<SipService>().dial(c.number),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
