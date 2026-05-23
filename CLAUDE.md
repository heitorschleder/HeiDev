# CLAUDE.md — HeiDev

## Sobre o projeto

Aplicativo Flutter de controle de contas domésticas (água, luz, internet, parcela, etc.).
Multi-usuário — cada usuário vê e gerencia apenas seus próprios lançamentos.
Backend: **Supabase** (Auth e-mail/senha + PostgreSQL com RLS).

## Comandos

```bash
fvm flutter pub get
fvm flutter run                                                # rodar o app
fvm flutter test                                               # todos os testes
fvm flutter test test/home/                                    # testes por módulo
fvm flutter analyze                                            # análise estática
fvm dart run tool/generate_localizations.dart                  # gerar ARBs de l10n
fvm dart run build_runner build --delete-conflicting-outputs   # codegen DI
```

Sempre usar `fvm flutter` / `fvm dart` — nunca `flutter`/`dart` direto. Flutter pinado em `3.35.7`.

## Convenções

- **Formatter**: `page_width: 120`, trailing commas preservadas.
- **Imports**: relativos (`prefer_relative_imports` ativado).
- **Errors**: nenhuma exception raw — mapear para `AppNetworkException` via `ExceptionMapper`.
- **Traduções**: adicionar em `localizations.json`, rodar generator. Nenhum texto hardcoded.
- **DI**: screens obtêm VM via `getIt<VM>()` diretamente no `initState`.
- **Material 3**: sempre `useMaterial3: true`. Nenhum design system customizado.
- **Supabase**: usar `SupabaseConfig.client` para acesso ao cliente; `AuthService` para auth.

## Hooks automáticos

Os hooks em `.claude/settings.json` fazem:
- **SessionStart**: FVM guardrail verifica SDK e deps.
- **PostToolUse (Write|Edit)**: auto-format + analyze em cada arquivo Dart editado.

## Skills disponíveis

- `/verify` — analyze + testes + build_runner.
- `/new-feature <feature/sub>` — scaffold data/domain/presentation + ViewModel, State, Screen, Route, teste.
- `/translate <group> <key> <pt> <en> <es>` — adicionar/atualizar traduções e regen ARBs.

## Arquitetura

Ver `.claude/rules/architecture.md` — carregado automaticamente em edições de arquivos Dart.
