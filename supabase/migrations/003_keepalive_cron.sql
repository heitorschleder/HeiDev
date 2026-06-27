-- ============================================================
-- HeiDev — Migration 003: Keepalive via pg_cron
-- Previne a pausa automática do Supabase free tier (inatividade de 7 dias).
-- Executar no: Supabase Dashboard → SQL Editor → Run
-- ============================================================

-- Habilita a extensão pg_cron (disponível no Supabase por padrão)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Remove job anterior caso já exista (idempotente)
SELECT cron.unschedule('heidev-keepalive')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'heidev-keepalive'
);

-- Cria o job: roda a cada 12 horas, faz um SELECT leve na tabela incomes
SELECT cron.schedule(
  'heidev-keepalive',
  '0 */12 * * *',
  $$SELECT COUNT(*) FROM public.incomes$$
);
