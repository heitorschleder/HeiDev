---
paths:
  - "lib/**/*.dart"
  - "test/**/*.dart"
---

# Arquitetura HeiDev

## Estrutura de módulos

Cada feature é um diretório top-level em `lib/`. Sub-features seguem três camadas:

```
feature/sub_feature/
├── data/
│   ├── models/         # DTOs (@JsonSerializable)
│   └── repositories/   # Acesso ao Supabase / API
├── domain/
│   └── logic/
│       ├── *_view_model.dart   # @injectable, ValueNotifier<State>
│       └── *_state.dart        # Equatable + copyWith manual
└── presentation/
    ├── routes/         # AppNoPayloadRouteConfig ou AppPayloadBoundRouteConfig
    └── screens/        # StatefulWidget
```

## State Management

ViewModels usam `ValueNotifier<State>`. Screens usam `ValueListenableBuilder`. ViewModels são `@injectable` (não singleton), obtidos via `getIt<VM>()..init()` no `initState`.

States estendem `Equatable`. Use `copyWith` manual. **Não use** `freezed`.

## DI

`injectable` + `get_it`. Config em `lib/core/di/`. Após modificar `@injectable`/`@singleton`, execute `build_runner`.

## Routing

`go_router` via `AppRouter`. Rotas declaradas como `part` em `lib/core/routing/routes/`. Features registradas em `RouteRepository`.

## Backend

`supabase_flutter` — cliente via `SupabaseConfig.client` ou injetado via DI (`SupabaseClient`). Auth via `AuthService`. RLS garante isolamento por usuário no banco.

## Localização

Fonte da verdade: `lib/core/l10n/localizations.json`. Rodar `dart run tool/generate_localizations.dart` para gerar ARBs. Acesso via `l10n.<key>`. **Nunca** editar `.arb` manualmente.

## Erros

Mapear exceções para `AppNetworkException` via `ExceptionMapper`. Nenhuma exception raw nos ViewModels.

## Comandos

```bash
fvm flutter pub get
fvm dart run tool/generate_localizations.dart
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze
fvm flutter test
```
