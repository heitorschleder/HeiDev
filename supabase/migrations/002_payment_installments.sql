-- Feature A: Forma de Pagamento
ALTER TABLE expenses
  ADD COLUMN IF NOT EXISTS payment_method text
    CHECK (payment_method IN ('dinheiro','credito','debito','vale_alimentacao','vale_refeicao'));
-- nullable sem DEFAULT: registros existentes ficam NULL → tratado como 'dinheiro' no Dart

-- Feature B: Parcelamento
ALTER TABLE expenses
  ADD COLUMN IF NOT EXISTS installment_group_id uuid,
  ADD COLUMN IF NOT EXISTS installment_number   smallint CHECK (installment_number >= 1),
  ADD COLUMN IF NOT EXISTS total_installments   smallint CHECK (total_installments >= 1);

CREATE INDEX IF NOT EXISTS idx_expenses_installment_group
  ON expenses (installment_group_id)
  WHERE installment_group_id IS NOT NULL;
