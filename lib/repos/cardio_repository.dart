// lib/repos/cardio_repository.dart
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:miocardio_app/model/afericao.dart';
import 'package:miocardio_app/database/db.dart';

class cardioRepository extends ChangeNotifier {
  late Database db;
  List<Afericao> _afericoes = [];
  List<Afericao> _afericoesHoje = [];
  int _ultimaAfericao = 0;

  get ultimaAfericao => _ultimaAfericao;
  List<Afericao> get afericoes => _afericoes;
  List<Afericao> get afericoesHoje => _afericoesHoje;

  cardioRepository() {
    _initRepository();
  }

  _initRepository() async {
    db = await DB.instance.database;
    await _getAfericao();
    await getAfericoesHoje();
  }

  _getAfericao() async {
    db = await DB.instance.database;
    List<Map<String, dynamic>> tableAfericoes = await db.query(
      'historicoAfericoes',
      orderBy: 'data_afericao DESC',
    );

    if (tableAfericoes.isNotEmpty) {
      _ultimaAfericao = tableAfericoes.first['bpm'] as int;

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

  // ✅ NOVO: Busca aferições de hoje
  Future<List<Afericao>> getAfericoesHoje() async {
    try {
      db = await DB.instance.database;

      DateTime hoje = DateTime.now();
      DateTime inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
      DateTime fimDia = inicioDia.add(Duration(days: 1));

      final List<Map<String, dynamic>> maps = await db.query(
        'historicoAfericoes',
        where: 'data_afericao >= ? AND data_afericao < ?',
        whereArgs: [inicioDia.toIso8601String(), fimDia.toIso8601String()],
        orderBy: 'data_afericao ASC',
      );

      _afericoesHoje = maps.map((row) => Afericao(
        id: row['id'] as int,
        bpm: row['bpm'] as int,
        dataAfericao: DateTime.parse(row['data_afericao'] as String),
      )).toList();

      print("💓 Carregadas ${_afericoesHoje.length} aferições de hoje");
      notifyListeners();
      return _afericoesHoje;
    } catch (e) {
      print("❌ Erro em getAfericoesHoje: $e");
      return [];
    }
  }

  setAfericao(int bpm, DateTime momento) async {
    try {
      db = await DB.instance.database;

      int id = await db.insert('historicoAfericoes', {
        'bpm': bpm,
        'data_afericao': momento.toIso8601String(),
      });

      print("✅ Aferição salva com ID: $id - $bpm bpm");

      _ultimaAfericao = bpm;
      await _getAfericao();
      await getAfericoesHoje();
    } catch (e) {
      print("❌ Erro ao salvar aferição: $e");
    }
  }

  Future<void> limparHistorico() async {
    db = await DB.instance.database;
    await db.delete('historicoAfericoes');
    _afericoes = [];
    _afericoesHoje = [];
    _ultimaAfericao = 0;
    notifyListeners();
  }

  // ✅ MÉTODO DE TESTE: Adiciona aferições simuladas
  Future<void> testarAfericoes() async {
    print("🧪 TESTE: Adicionando aferições simuladas");

    DateTime agora = DateTime.now();

    List<Map<String, dynamic>> dadosTeste = [
      {'bpm': 72, 'momento': agora.subtract(Duration(hours: 6))},
      {'bpm': 85, 'momento': agora.subtract(Duration(hours: 4))},
      {'bpm': 68, 'momento': agora.subtract(Duration(hours: 2))},
      {'bpm': 95, 'momento': agora.subtract(Duration(hours: 1))},
      {'bpm': 78, 'momento': agora},
    ];

    for (var dado in dadosTeste) {
      await setAfericao(dado['bpm'] as int, dado['momento'] as DateTime);
      await Future.delayed(Duration(milliseconds: 100));
    }

    print("🧪 TESTE CONCLUÍDO!");
  }
}