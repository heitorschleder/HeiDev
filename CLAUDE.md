# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

## Arquitetura

Cada feature é um diretório top-level em `lib/` com três camadas: `data/` (DTOs + repositórios Supabase), `domain/` (lógica + estado), `presentation/` (rotas + screens). Features atuais: `auth`, `home`, `expenses`, `income`. Compartilhados em `commons/widgets/`.

**State management**: ViewModels com `ValueNotifier<State>`, obtidos via `getIt<VM>()..init()` no `initState`. States estendem `Equatable` com `copyWith` manual. Não usar `freezed`.

**Routing**: `go_router` com `StatefulShellRoute` de 3 branches — `home`, `expenses` (com sub-rotas `expense_form` e `bill_templates`), `income`. Novas features adicionam rotas em `lib/core/routing/routes/` e as registram em `RouteRepository`.

**DI**: `injectable` + `get_it`. Após modificar `@injectable`/`@singleton`, executar `build_runner`.

## Convenções

- **Formatter**: `page_width: 120`, trailing commas preservadas.
- **Imports**: relativos (`prefer_relative_imports` ativado).
- **Errors**: nenhuma exception raw — mapear para `AppNetworkException` via `ExceptionMapper`.
- **Traduções**: adicionar em `localizations.json`, rodar generator. Nenhum texto hardcoded.
- **Material 3**: sempre `useMaterial3: true`. Nenhum design system customizado.
- **Supabase**: usar `SupabaseConfig.client` para acesso ao cliente; `AuthService` para auth.

## Domínio de despesas

`ExpenseModel` campos-chave: `title`, `category` (`ExpenseCategory` enum), `amount`, `dueDate`, `paid`/`paidAt`, `priority` (`ExpensePriority`), `referenceMonth`, `paymentMethod` (`ExpensePaymentMethod`), `templateId`, `installmentGroupId`/`installmentNumber`/`totalInstallments`.

`reference_month` é sempre o primeiro dia do mês no formato `YYYY-MM-01` (ver `ExpenseRepository._monthKey`).

`saveExpense` marca `paid: true` e `paid_at: dueDate` por padrão — despesas avulsas são consideradas já pagas na inserção.

Categorias disponíveis: `casa`, `transporte`, `alimentacao`, `saude`, `lazer`, `impostos`, `outros`.

## Hooks automáticos

Os hooks em `.claude/settings.json` fazem:
- **SessionStart**: FVM guardrail verifica SDK e deps.
- **PostToolUse (Write|Edit)**: auto-format + analyze em cada arquivo Dart editado.

## Skills disponíveis

- `/verify` — analyze + testes + build_runner.
- `/new-feature <feature/sub>` — scaffold data/domain/presentation + ViewModel, State, Screen, Route, teste.
- `/translate <group> <key> <pt> <en> <es>` — adicionar/atualizar traduções e regen ARBs.
