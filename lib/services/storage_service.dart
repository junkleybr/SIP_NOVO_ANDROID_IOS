import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/call_log.dart';
import '../models/contact_entry.dart';
import '../models/sip_account.dart';

/// Persistência leve em SharedPreferences.
class StorageService {
  static const _kAccount = 'sip_account_v2';
  static const _kCallLog = 'call_log_v2';
  static const _kContacts = 'contacts_v2';
  static const _kThemeMode = 'theme_mode';

  Future<SipAccount> loadAccount() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kAccount);
    if (raw == null) return SipAccount.empty;
    try {
      return SipAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return SipAccount.empty;
    }
  }

  Future<void> saveAccount(SipAccount a) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccount, jsonEncode(a.toJson()));
  }

  Future<void> clearAccount() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccount);
  }

  Future<List<CallLogEntry>> loadCallLog() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_kCallLog) ?? const [];
    return raw
        .map((s) =>
            CallLogEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCallLog(List<CallLogEntry> entries) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _kCallLog,
      entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<List<ContactEntry>> loadContacts() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_kContacts) ?? const [];
    return raw
        .map((s) =>
            ContactEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveContacts(List<ContactEntry> contacts) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _kContacts,
      contacts.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  Future<String> loadThemeMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kThemeMode) ?? 'system';
  }

  Future<void> saveThemeMode(String mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kThemeMode, mode);
  }
}
