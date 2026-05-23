#!/bin/bash
# FVM guardrail — validates Flutter tooling is ready at session start
warnings=""

# 1. FVM available?
if ! command -v fvm >/dev/null 2>&1; then
  warnings="FVM não encontrado no PATH. Todos os comandos Flutter exigem prefixo fvm."
fi

# 2. Correct SDK version?
if [ -z "$warnings" ]; then
  expected=$(grep -o '"flutter": "[^"]*"' .fvmrc 2>/dev/null | grep -o '[0-9][0-9.]*')
  if [ -n "$expected" ]; then
    current=$(fvm flutter --version --machine 2>/dev/null | grep frameworkVersion | grep -o '[0-9][0-9.]*')
    if [ "$current" != "$expected" ]; then
      warnings="SDK Flutter incompatível: esperado $expected, encontrado ${current:-nenhum}. Execute: fvm install"
    fi
  fi
fi

# 3. jq available?
if [ -z "$warnings" ] && ! command -v jq >/dev/null 2>&1; then
  warnings="jq não encontrado no PATH. Hooks de auto-format/analyze dependem dele. Instale: sudo apt install jq"
fi

# 4. Dependencies resolved?
if [ -z "$warnings" ] && [ ! -f .dart_tool/package_config.json ]; then
  warnings="Dependências não resolvidas. Execute: fvm flutter pub get"
fi

# Report
if [ -n "$warnings" ]; then
  echo "{\"systemMessage\":\"FVM check: ${warnings}\"}"
else
  echo '{"suppressOutput":true}'
fi
