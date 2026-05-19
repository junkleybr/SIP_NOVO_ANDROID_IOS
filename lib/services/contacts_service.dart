import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/contact_entry.dart';
import 'storage_service.dart';

class ContactsService extends ChangeNotifier {
  ContactsService(this._storage);

  final StorageService _storage;
  final _uuid = const Uuid();
  List<ContactEntry> _contacts = <ContactEntry>[];

  List<ContactEntry> get contacts => List.unmodifiable(_contacts);
  List<ContactEntry> get favorites =>
      _contacts.where((c) => c.favorite).toList();

  Future<void> load() async {
    _contacts = await _storage.loadContacts();
    _contacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
  }

  Future<void> add(String name, String number) async {
    final c = ContactEntry(id: _uuid.v4(), name: name, number: number);
    _contacts = [..._contacts, c];
    _contacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await _storage.saveContacts(_contacts);
    notifyListeners();
  }

  Future<void> update(ContactEntry c) async {
    _contacts = _contacts.map((x) => x.id == c.id ? c : x).toList();
    await _storage.saveContacts(_contacts);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _contacts = _contacts.where((c) => c.id != id).toList();
    await _storage.saveContacts(_contacts);
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    _contacts = _contacts
        .map((c) => c.id == id ? c.copyWith(favorite: !c.favorite) : c)
        .toList();
    await _storage.saveContacts(_contacts);
    notifyListeners();
  }
}
