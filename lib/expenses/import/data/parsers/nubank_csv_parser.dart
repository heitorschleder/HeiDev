import 'package:csv/csv.dart';

import '../../../domain/expense_category.dart';
import '../../../domain/expense_payment_method.dart';
import '../models/imported_expense_model.dart';

abstract final class NubankCsvParser {
  static List<ImportedExpenseModel> parse(String content) {
    final cleaned = content.startsWith('﻿') ? content.substring(1) : content;
    final normalized = cleaned.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final firstLine = normalized.split('\n').first;
    final separator = firstLine.contains(';') ? ';' : ',';

    final rows = CsvToListConverter(fieldDelimiter: separator, eol: '\n').convert(normalized);
    if (rows.length < 2) return [];

    final header = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    final dateIdx = _findIndex(header, ['date', 'data']);
    final titleIdx = _findIndex(header, ['title', 'descrição', 'descricao', 'description']);
    final amountIdx = _findIndex(header, ['amount', 'valor', 'value']);

    if (dateIdx == -1 || titleIdx == -1 || amountIdx == -1) {
      throw const FormatException('Colunas obrigatórias não encontradas');
    }

    // Formato conta Nubank: débitos são negativos, créditos são positivos.
    // Formato cartão Nubank: compras são positivas, estornos são negativos.
    // Identificador presente → formato conta.
    final isAccountFormat = header.any((h) => h.contains('identificador'));

    final result = <ImportedExpenseModel>[];
    for (final row in rows.skip(1)) {
      if (row.length <= amountIdx || row.length <= titleIdx) continue;

      final rawTitle = row[titleIdx].toString().trim();
      final rawAmountStr = row[amountIdx].toString().trim().replaceAll(',', '.');
      final rawDateStr = row[dateIdx].toString().trim();

      if (rawTitle.isEmpty) continue;

      final rawAmount = double.tryParse(rawAmountStr);
      if (rawAmount == null || rawAmount == 0) continue;

      final double expenseAmount;
      if (isAccountFormat) {
        // Conta: valor negativo = despesa, positivo = crédito/recebimento → ignorar
        if (rawAmount > 0) continue;
        expenseAmount = rawAmount.abs();
      } else {
        // Cartão: valor positivo = compra, negativo = estorno/crédito → ignorar
        if (rawAmount <= 0) continue;
        expenseAmount = rawAmount;
      }

      if (_isCredit(rawTitle)) continue;

      final date = _parseDate(rawDateStr);
      if (date == null) continue;

      result.add(
        ImportedExpenseModel(
          rawTitle: rawTitle,
          rawAmount: expenseAmount,
          rawDate: date,
          title: _cleanTitle(rawTitle),
          category: _suggestCategory(rawTitle),
          amount: expenseAmount,
          date: date,
          paymentMethod: ExpensePaymentMethod.debito,
        ),
      );
    }

    return result;
  }

  // Remove prefixos padrão do Nubank e simplifica o título para exibição.
  static String _cleanTitle(String description) {
    const prefixes = [
      'Compra no débito via NuPay - ',
      'Compra no débito - ',
      'Compra no crédito - ',
      'Transferência enviada pelo Pix - ',
      'Transferência enviada - ',
      'Pagamento de boleto - ',
      'Pagamento via boleto - ',
    ];

    var s = description;
    for (final prefix in prefixes) {
      if (s.toLowerCase().startsWith(prefix.toLowerCase())) {
        s = s.substring(prefix.length);
        break;
      }
    }

    // Para Pix com CNPJ/CPF: "NOME - 00.000.000/0001-00 - BANCO..."  → manter só NOME
    s = s.replaceFirst(RegExp(r'\s*-\s*[\d]{2,3}[\.\d]*[\./\-][\d]+.*$'), '');

    return _toTitleCase(s.trim());
  }

  static int _findIndex(List<String> header, List<String> candidates) {
    for (final candidate in candidates) {
      final idx = header.indexWhere((h) => h.contains(candidate));
      if (idx != -1) return idx;
    }
    return -1;
  }

  static DateTime? _parseDate(String s) {
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final br = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');

    var match = iso.firstMatch(s);
    if (match != null) {
      return DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!), int.parse(match.group(3)!));
    }
    match = br.firstMatch(s);
    if (match != null) {
      return DateTime(int.parse(match.group(3)!), int.parse(match.group(2)!), int.parse(match.group(1)!));
    }
    return null;
  }

  static String _toTitleCase(String s) {
    return s
        .split(' ')
        .map((word) {
          if (word.length <= 1) return word.toUpperCase();
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static ExpenseCategory _suggestCategory(String title) {
    final lower = title.toLowerCase();

    if (_any(lower, [
      'mercado',
      'supermercado',
      'ifood',
      'rappi',
      'restaurante',
      'lanchonete',
      'padaria',
      'pizza',
      'burger',
      'mcdonald',
      'subway',
      'delivery',
      'açaí',
      'acai',
      'hortifruti',
      'sushi',
      'ze delivery',
      'bk ',
    ])) {
      return ExpenseCategory.alimentacao;
    }
    if (_any(lower, [
      'uber',
      '99 ',
      'taxi',
      'combustivel',
      'posto ',
      'shell ',
      'ipiranga',
      'petrobras',
      'estacionamento',
      'pedagio',
      'passagem',
      'metro ',
      'bilhete',
      'nupay',
    ])) {
      return ExpenseCategory.transporte;
    }
    if (_any(lower, [
      'netflix',
      'spotify',
      'steam',
      'cinema',
      'amazon prime',
      'disney',
      'hbo',
      'prime video',
      'youtube premium',
      'playstation',
      'xbox',
      'nintendo',
      'ingresso',
      'teatro',
    ])) {
      return ExpenseCategory.lazer;
    }
    if (_any(lower, [
      'farmacia',
      'drogaria',
      'laboratorio',
      'clinica',
      'hospital',
      'medico',
      'dentista',
      'panvel',
      'ultrafarma',
      'raia',
      'pacheco',
      'droga',
    ])) {
      return ExpenseCategory.saude;
    }
    if (_any(lower, [
      'aluguel',
      'condominio',
      'energia eletrica',
      'conta de luz',
      'saneamento',
      'agua ',
      'internet',
      'net ',
      'vivo ',
      'claro ',
      'tim ',
      'leroy',
      'telhanorte',
      'sodimac',
    ])) {
      return ExpenseCategory.casa;
    }
    if (_any(lower, ['receita federal', 'detran', 'iptu', 'ipva', 'inss', 'imposto', 'tributo', 'carne'])) {
      return ExpenseCategory.impostos;
    }
    return ExpenseCategory.outros;
  }

  // Segurança extra: filtra títulos que claramente indicam recebimento mesmo em formatos positivos.
  static bool _isCredit(String rawTitle) {
    final lower = rawTitle.toLowerCase();
    return _any(lower, [
      'transferência recebida',
      'transferencia recebida',
      'pix recebido',
      'pix recebida',
      'ted recebida',
      'doc recebido',
      'pagamento recebido',
      'estorno',
      'cashback',
      'reembolso',
      'devolução',
      'devolucao',
      'rendimento',
      'resgate',
    ]);
  }

  static bool _any(String text, List<String> keywords) => keywords.any(text.contains);
}
