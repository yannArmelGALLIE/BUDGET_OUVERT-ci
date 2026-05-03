// lib/models/blockchain_model.dart
//
// Une transaction blockchain = un "projet" financier de la commune.
// type "recette" → argent entrant (impôts, taxes, subventions)
// type "dépense" → argent sortant (travaux, services, salaires)

class BlockchainTxModel {
  final int id;
  final String commune;
  final String type; // "recette" ou "dépense"
  final String category;
  final int amount; // FCFA, entier
  final String date; // "dd/mm/yyyy"
  final int timestamp; // Unix timestamp
  final String description;
  final String recorder; // adresse wallet 0x...
  final String hash; // hash transaction blockchain

  BlockchainTxModel({
    required this.id,
    required this.commune,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    required this.timestamp,
    required this.description,
    required this.recorder,
    this.hash = '',
  });

  factory BlockchainTxModel.fromJson(Map<String, dynamic> j) {
    final timestampStr = j['timestamp'] as String?;
    final dt = timestampStr != null ? DateTime.parse(timestampStr) : null;
    final typeStr = j['txType'] as String? ?? '';
    final type = typeStr == 'EXPENSE'
        ? 'dépense'
        : typeStr == 'REVENUE'
            ? 'recette'
            : typeStr;

    return BlockchainTxModel(
      id: int.tryParse(j['id']!.toString()) ?? 0,
      commune: j['communeName'] ?? '',
      type: type,
      category: j['category'] ?? '',
      amount: int.tryParse(j['amount']!.toString()) ?? 0,
      timestamp: dt?.millisecondsSinceEpoch ?? 0,
      description: j['description'] ?? '',
      recorder: j['recorder'] ?? '',
      hash: '', // pas dans API
      date: dt != null
          ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}'
          : '',
    );
  }

  bool get isRevenue => type == 'recette';

  // Icône selon la catégorie
  String get categoryIcon {
    switch (category.toLowerCase()) {
      case 'voirie & travaux':
      case 'infrastructure':
        return '🏗️';
      case 'santé':
        return '🏥';
      case 'éducation':
        return '🎓';
      case 'taxe foncière':
      case 'taxes & impôts':
        return '🏛️';
      case 'environnement':
        return '🌿';
      default:
        return isRevenue ? '📥' : '📤';
    }
  }

  // Montant formaté : 50.000.000
  String get amountFormatted {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // Hash tronqué : 0xaeba...3da
  String get hashShort {
    if (hash.length < 12) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 3)}';
  }
}

// ─── BALANCE ──────────────────────────────────────────────────────────────
class CommuneBalanceModel {
  final String commune;
  final int balance;
  final String currency;

  CommuneBalanceModel({
    required this.commune,
    required this.balance,
    required this.currency,
  });

  factory CommuneBalanceModel.fromJson(Map<String, dynamic> j) {
    final rawBalance = j['balance'];
    final parsedBalance = rawBalance is int
        ? rawBalance
        : int.tryParse(rawBalance?.toString() ?? '') ?? 0;

    return CommuneBalanceModel(
      commune: j['commune']?.toString() ?? '',
      balance: parsedBalance,
      currency: j['currency']?.toString() ?? 'FCFA',
    );
  }

  bool get isDeficit => balance < 0;

  // ✅ Bug corrigé : pousse le chiffre, pas un point
  String get balanceFormatted {
    final isNeg = balance < 0;
    final s = balance.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${isNeg ? '-' : ''}${buf.toString()} $currency';
  }
}
