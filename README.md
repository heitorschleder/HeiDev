# HeiDev

Aplicativo Flutter de **controle de contas domésticas** para múltiplos usuários. Cada usuário gerencia apenas seus próprios lançamentos, com dados isolados via Row Level Security no Supabase.

---

## Features

### Renda
- Cadastro de renda com múltiplos tipos (CLT, PJ, autônomo)
- Histórico de salário por vigência — mudanças de salário a partir de um mês específico não afetam meses anteriores
- Vale-refeição (VR) e vale-alimentação (VA) configuráveis
- Entradas extras por mês (férias, 13º, comissões, restituição IR) sem alterar o salário base
- Total mensal = salário base + entradas extras

### Despesas
- Lançamento de despesas com título, categoria, data de vencimento, prioridade e mês de referência
- Marcação de pago/não pago
- Suporte a **parcelamento** — gera automaticamente N despesas mensais a partir do valor total
- **Formas de pagamento** por despesa: dinheiro, crédito, débito, VR e VA
  - VR e VA só aparecem se habilitados na configuração de renda do usuário
- Filtros avançados na lista: categoria (multi-seleção), forma de pagamento (multi-seleção), essencial (Todos / Sim / Não), parceladas
- Busca por texto
- Navegação por mês

### Dashboard
- Resumo financeiro do mês: renda total, total de despesas, saldo
- Indicadores de despesas pagas vs. pendentes
- Gráfico de distribuição por categoria
- Pull-to-refresh para recarregar todos os dados

### Autenticação
- Cadastro e login com e-mail e senha via Supabase Auth
- Sessão persistida com armazenamento seguro

---

## Tecnologias

| Camada | Biblioteca |
|--------|-----------|
| Framework | Flutter 3.35.7 (via FVM) |
| Backend / Auth | Supabase (PostgreSQL + RLS) |
| Roteamento | go_router |
| DI | get_it + injectable |
| HTTP | dio |
| Gráficos | fl_chart |
| Localização | intl |
| Design | Material 3 |

---

## Pré-requisitos

- [FVM](https://fvm.app) instalado (`dart pub global activate fvm`)
- Flutter SDK gerenciado pelo FVM (instalado automaticamente no primeiro uso)
- Conta no [Supabase](https://supabase.com) com o projeto configurado

---

## Configuração

### 1. Clonar o repositório

```bash
git clone <url-do-repositorio>
cd HeiDev
```

### 2. Criar o arquivo de ambiente

Copie o arquivo de exemplo e preencha com as credenciais do seu projeto Supabase:

```bash
cp .env.example .env
```

```env
SUPABASE_URL=https://<seu-projeto>.supabase.co
SUPABASE_ANON_KEY=<sua-anon-key>
```

As chaves estão disponíveis em **Project Settings → API** no painel do Supabase.

### 3. Aplicar as migrations no Supabase

Execute os arquivos em ordem no **SQL Editor** do Supabase:

```
supabase/migrations/001_init.sql
supabase/migrations/002_payment_installments.sql
supabase/migrations/003_income_history_events.sql
```

### 4. Instalar dependências

```bash
fvm flutter pub get
```

### 5. Gerar código (DI + serialização)

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart run tool/generate_localizations.dart
```

---

## Rodando o app

```bash
fvm flutter run
```

Para um dispositivo/emulador específico:

```bash
fvm flutter devices                     # listar dispositivos disponíveis
fvm flutter run -d <device-id>
```

---

## Comandos úteis

```bash
fvm flutter analyze                                            # análise estática
fvm flutter test                                               # todos os testes
fvm flutter test test/home/                                    # testes por módulo
fvm dart run tool/generate_localizations.dart                  # regenerar ARBs de l10n
fvm dart run build_runner build --delete-conflicting-outputs   # regenerar DI e serialização
```

---

## Estrutura do projeto

```
lib/
├── auth/            # Autenticação (login, cadastro)
├── core/            # Infraestrutura transversal (DI, routing, l10n, error, theme)
├── commons/         # Widgets e utilitários compartilhados
├── home/            # Dashboard
├── expenses/        # Módulo de despesas
└── income/          # Módulo de renda
```

Cada módulo segue três camadas:

```
feature/
├── data/
│   ├── models/         # DTOs (@JsonSerializable)
│   └── repositories/   # Acesso ao Supabase
├── domain/
│   └── logic/
│       ├── *_view_model.dart   # @injectable, ValueNotifier<State>
│       └── *_state.dart        # Equatable + copyWith
└── presentation/
    ├── routes/
    └── screens/
```
