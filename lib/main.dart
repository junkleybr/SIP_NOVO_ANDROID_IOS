import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/call_log_service.dart';
import 'services/contacts_service.dart';
import 'services/sip_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final storage = StorageService();
  final sip = SipService()..init();
  final callLog = CallLogService(storage);
  final contacts = ContactsService(storage);

  await Future.wait([
    callLog.load(),
    contacts.load(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider<SipService>.value(value: sip),
        ChangeNotifierProvider<CallLogService>.value(value: callLog),
        ChangeNotifierProvider<ContactsService>.value(value: contacts),
      ],
      child: const Visual2VozApp(),
    ),
  );
}
