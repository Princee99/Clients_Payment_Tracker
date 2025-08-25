class LedgerEntry {
  final int? id;
  final int clientId;
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final double runningBalance;
  final String? reference;
  final String? notes;

  LedgerEntry({
    this.id,
    required this.clientId,
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    this.reference,
    this.notes,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    try {
      return LedgerEntry(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : null,
        clientId: int.tryParse(json['client_id'].toString()) ?? 0,
        date: DateTime.tryParse(json['date'].toString()) ?? DateTime.now(),
        description: json['description']?.toString() ?? '',
        debit: double.tryParse(json['debit'].toString()) ?? 0.0,
        credit: double.tryParse(json['credit'].toString()) ?? 0.0,
        runningBalance: double.tryParse(json['running_balance'].toString()) ?? 0.0,
        reference: json['reference']?.toString(),
        notes: json['notes']?.toString(),
      );
    } catch (e) {
      print('Error parsing LedgerEntry from JSON: $e');
      print('JSON data: $json');
      // Return a default entry if parsing fails
      return LedgerEntry(
        clientId: 0,
        date: DateTime.now(),
        description: 'Error parsing entry',
        debit: 0.0,
        credit: 0.0,
        runningBalance: 0.0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'client_id': clientId,
      'date': date.toIso8601String(),
      'description': description,
      'debit': debit,
      'credit': credit,
      'running_balance': runningBalance,
      'reference': reference,
      'notes': notes,
    };
  }

  LedgerEntry copyWith({
    int? id,
    int? clientId,
    DateTime? date,
    String? description,
    double? debit,
    double? credit,
    double? runningBalance,
    String? reference,
    String? notes,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      description: description ?? this.description,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      runningBalance: runningBalance ?? this.runningBalance,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
    );
  }
} 