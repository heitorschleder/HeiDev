-- ============================================================
-- HeiDev — Migration 001: Schema inicial
-- Executar no: Supabase Dashboard → SQL Editor → Run
-- ============================================================

-- ------------------------------------------------------------
-- INCOMES
-- Um registro por usuário, atualizado conforme necessário.
-- Impostos (INSS, Simples, IRRF) são lançados como despesas.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS incomes (
  id           uuid          DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      uuid          NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type         text          NOT NULL CHECK (type IN ('CLT', 'PJ', 'autonomo')),
  gross_salary numeric(12,2) NOT NULL DEFAULT 0,
  receives_vr  boolean       NOT NULL DEFAULT false,
  vr_amount    numeric(12,2) NOT NULL DEFAULT 0,
  receives_va  boolean       NOT NULL DEFAULT false,
  va_amount    numeric(12,2) NOT NULL DEFAULT 0,
  commission   numeric(12,2) NOT NULL DEFAULT 0,
  bonus        numeric(12,2) NOT NULL DEFAULT 0,
  other_income numeric(12,2) NOT NULL DEFAULT 0,
  created_at   timestamptz   NOT NULL DEFAULT now(),
  updated_at   timestamptz   NOT NULL DEFAULT now(),
  UNIQUE (user_id)
);

-- ------------------------------------------------------------
-- BILL TEMPLATES
-- Catálogo de contas recorrentes do usuário (ex: aluguel, luz).
-- Serve como base para lançamentos mensais.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bill_templates (
  id             uuid          DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id        uuid          NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title          text          NOT NULL,
  category       text          NOT NULL CHECK (category IN (
                   'casa', 'transporte', 'alimentacao',
                   'saude', 'lazer', 'impostos', 'outros')),
  is_essential   boolean       NOT NULL DEFAULT true,
  default_amount numeric(12,2) NOT NULL DEFAULT 0,
  created_at     timestamptz   NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- EXPENSES
-- Lançamentos mensais de despesas.
-- Podem ser criados manualmente ou a partir de bill_templates.
-- reference_month = primeiro dia do mês (ex: 2025-06-01).
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS expenses (
  id              uuid          DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         uuid          NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  template_id     uuid          REFERENCES bill_templates(id) ON DELETE SET NULL,
  title           text          NOT NULL,
  category        text          NOT NULL CHECK (category IN (
                    'casa', 'transporte', 'alimentacao',
                    'saude', 'lazer', 'impostos', 'outros')),
  is_essential    boolean       NOT NULL DEFAULT true,
  amount          numeric(12,2) NOT NULL CHECK (amount >= 0),
  due_date        date          NOT NULL,
  paid            boolean       NOT NULL DEFAULT false,
  paid_at         timestamptz,
  priority        text          NOT NULL DEFAULT 'media' CHECK (priority IN ('alta', 'media', 'baixa')),
  reference_month date          NOT NULL,
  notes           text,
  created_at      timestamptz   NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- SIMULATIONS (reservado para fase futura)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS simulations (
  id         uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type       text        NOT NULL,
  payload    jsonb       NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- ÍNDICES — para queries frequentes
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_expenses_user_month
  ON expenses (user_id, reference_month);

CREATE INDEX IF NOT EXISTS idx_expenses_user_due
  ON expenses (user_id, due_date);

CREATE INDEX IF NOT EXISTS idx_bill_templates_user
  ON bill_templates (user_id);

-- ------------------------------------------------------------
-- ROW LEVEL SECURITY
-- Cada usuário vê e altera apenas os próprios dados.
-- ------------------------------------------------------------
ALTER TABLE incomes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses       ENABLE ROW LEVEL SECURITY;
ALTER TABLE simulations    ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own income"
  ON incomes FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own templates"
  ON bill_templates FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own expenses"
  ON expenses FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own simulations"
  ON simulations FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ------------------------------------------------------------
-- TRIGGER — atualiza updated_at em incomes automaticamente
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER incomes_updated_at
  BEFORE UPDATE ON incomes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
