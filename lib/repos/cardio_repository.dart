import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:miocardio_app/model/afericao.dart';
import 'package:miocardio_app/database/db.dart';

class cardioRepository extends ChangeNotifier {
  late Database db;
  List<Afericao> _afericoes = [];
  int _ultimaAfericao = 0;

  get ultimaAfericao => _ultimaAfericao;
  List<Afericao> get afericoes => _afericoes;

  cardioRepository() {
    _initRepository();
  }

  _initRepository() async {
    await _getAfericao();
  }

  _getAfericao() async {
    db = await DB.instance.database;
    List<Map<String, dynamic>> tableAfericoes = await db.query('historicoAfericoes');

    // ✅ Verifica se há registros antes de acessar .last
    if (tableAfericoes.isNotEmpty) {
      _ultimaAfericao = tableAfericoes.last['bpm'] as int;

      // ✅ Popula a lista de aferições (se sua model Afericao suportar)
      _afericoes = tableAfericoes.map((row) => Afericao(
        id: row['id'] as int,
        bpm: row['bpm'] as int,
        dataAfericao: DateTime.parse(row['data_afericao'] as String),
      )).toList();
    } else {
      _ultimaAfericao = 0;
      _afericoes = [];
    }

    notifyListeners();
  }

  setAfericao(int bpm, DateTime momento) async {
    db = await DB.instance.database;

    // Usa INSERT em vez de UPDATE
    await db.insert('historicoAfericoes', {
      'bpm': bpm,
      'data_afericao': momento.toIso8601String(), // ✅ Nome correto da coluna
    });

    _ultimaAfericao = bpm;

    // Recarrega as aferições após inserir
    await _getAfericao();
  }

  // ✅ Método adicional para limpar histórico (útil para testes)
  Future<void> limparHistorico() async {
    db = await DB.instance.database;
    await db.delete('historicoAfericoes');
    _afericoes = [];
    _ultimaAfericao = 0;
    notifyListeners();
  }
}