# visual2.voz — SIP Mobile (Flutter)

Versão **2.0** do aplicativo SIP da Visual2 Voz, agora multiplataforma: **um único código** roda em Android e iPhone.

## O que mudou em relação à v1 (Java/Android)

| Aspecto              | v1 (Java)                      | v2 (Flutter)                                       |
|----------------------|--------------------------------|----------------------------------------------------|
| Plataformas          | Apenas Android                 | **Android + iOS**                                  |
| SIP real             | Não (só UI mockada)            | **Sim** — `sip_ua` + `flutter_webrtc` (WSS)        |
| Visual               | Telas básicas, laranja sólido  | **Material 3** com cores dinâmicas, tema escuro    |
| Discador             | Estático                       | **Háptico + animado**, sublabels ABC/DEF, long-press `0` → `+` |
| Tela de chamada      | Inexistente                    | Cheia com avatar, timer, mute/hold/DTMF/speaker    |
| Histórico            | —                              | Persistido, com ícones de entrada/saída/perdida    |
| Contatos             | —                              | CRUD + favoritos + busca                           |
| Status de registro   | —                              | Indicador ao vivo no topo + erro com retry         |
| Reconectar           | —                              | Automático no boot + botão manual                  |
| Background           | —                              | Permissões VoIP (iOS) + foreground service (Android) |
| Build                | GitHub Actions só Android      | Workflow gera **APK e IPA** automaticamente        |

## Pré-requisitos

- **Flutter 3.19+** (testado em 3.24.x)
- Android: Android Studio + SDK 34, JDK 17
- iOS: macOS + Xcode 15+ + CocoaPods

## Como rodar localmente

```bash
cd flutter_visual2_voz
flutter pub get

# Android (com dispositivo/emulador plugado)
flutter run

# iOS
cd ios && pod install && cd ..
flutter run -d <device-id>
```

## Como gerar APK

```bash
flutter build apk --release
# Arquivo: build/app/outputs/flutter-apk/app-release.apk
```

Ou pelo **GitHub Actions** — basta dar push em `main` e baixar o artifact `visual2-voz-release-apk` da aba *Actions*.

## Como gerar IPA (iOS)

Sem certificado de assinatura (apenas para testes em simulador / TestFlight não funciona sem assinar):

```bash
flutter build ios --release --no-codesign
```

Com assinatura — abra `ios/Runner.xcworkspace` no Xcode, configure Team + Bundle ID `com.visual2.voz`, e archive normalmente.

## Pré-requisito do servidor SIP

O `sip_ua` usa **SIP sobre WebSocket Seguro (WSS)** — é o transporte recomendado pela Apple e Google para apps SIP modernos. Seu PABX precisa:

- **FreePBX / Asterisk 13+**: habilite WebRTC no `chan_pjsip`, transport `transport-wss` na porta `8089`, certificado TLS válido (Let's Encrypt funciona).
- **3CX**: WebMeeting/WebClient já expõe WSS — use a URL informada no painel.
- **Outros (Yate, Kamailio, OpenSIPS)**: ative o módulo de WebSocket.

URL típica preenchida na tela de configuração:

```
wss://pbx.empresa.com.br:8089/ws
```

## Estrutura do código

```
flutter_visual2_voz/
├── lib/
│   ├── main.dart              # Bootstrap + Providers
│   ├── app.dart               # MaterialApp + roteamento p/ chamada ativa
│   ├── theme/app_theme.dart   # Material 3 com seed laranja Visual2
│   ├── models/                # SipAccount, CallLogEntry, ContactEntry
│   ├── services/
│   │   ├── sip_service.dart   # Wrapper do SIPUAHelper (sip_ua)
│   │   ├── storage_service.dart
│   │   ├── call_log_service.dart
│   │   └── contacts_service.dart
│   └── screens/
│       ├── splash_screen.dart
│       ├── config_screen.dart # Cadastro/edição da conta SIP
│       ├── home_screen.dart   # Bottom-nav: discar/histórico/contatos/ajustes
│       ├── dialer_screen.dart
│       ├── call_screen.dart   # Tela de chamada ativa
│       ├── history_screen.dart
│       ├── contacts_screen.dart
│       └── settings_screen.dart
├── android/                   # Manifest, gradle, MainActivity Kotlin
├── ios/                       # Info.plist, AppDelegate Swift, Podfile
└── .github/workflows/build.yml # CI: gera APK + IPA
```

## Personalização da marca

Cores em `lib/theme/app_theme.dart` (`AppColors`). Para trocar o ícone:

1. Coloque um PNG 1024x1024 em `assets/icons/app_icon.png`
2. Rode `flutter pub run flutter_launcher_icons`

## Próximos passos sugeridos

- [ ] Transferência cega + atendida (já temos esqueleto no `call_screen.dart`)
- [ ] Push notifications via FCM/APNs para chamadas em background
- [ ] Importar contatos do celular (já incluímos `flutter_contacts` no pubspec)
- [ ] Vídeo chamadas (já temos `flutter_webrtc`, falta UI dedicada)
- [ ] Gravação de chamadas (servidor-side via Asterisk MixMonitor)
