// lib/repos/pedometer_repository.dart
import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:miocardio_app/model/atividade.dart';
import 'package:sqflite/sqflite.dart';
import 'package:miocardio_app/database/db.dart';
import 'package:daily_pedometer2/daily_pedometer2.dart';

class pedometerRepository extends ChangeNotifier {
  late Database db;
  List<Atividade> _atividades = [];
  List<Atividade> _ultimasSeteHoras = [];
  List<Atividade> _atividadesHoje = []; // ✅ NOVO: Todas as horas do dia

  Queue<StepCount> history = Queue<StepCount>();
  String ritmoAtual = 'Indefinido';

  int? _horaAtual;
  int? _idRegistroAtual;

  List<Atividade> get atividades => _atividades;
  List<Atividade> get ultimasSeteHoras => _ultimasSeteHoras;
  List<Atividade> get atividadesHoje => _atividadesHoje; // ✅ NOVO

  pedometerRepository() {
    _initRepository();
  }

  _initRepository() async {
    db = await DB.instance.database;
    await getUltimasSeteHoras();
    await getAtividadesHoje(); // ✅ NOVO
  }

  // Busca todas as atividades entre duas datas
  Future<List<Atividade>> getAtividade(DateTime inicio, DateTime fim) async {
    db = await DB.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'historicoAtividade',
      where: 'data >= ? AND data <= ?',
      whereArgs: [inicio.toIso8601String(), fim.toIso8601String()],
      orderBy: 'data DESC',
    );

    _atividades = List.generate(maps.length, (i) {
      return Atividade(
        passos: maps[i]['passos'],
        data: DateTime.parse(maps[i]['data']),
      );
    });

    notifyListeners();
    return _atividades;
  }

  // ✅ Busca as últimas 7 horas (para o gráfico)
  Future<List<Atividade>> getUltimasSeteHoras() async {
    try {
      db = await DB.instance.database;

      DateTime seteHorasAtras = DateTime.now().subtract(Duration(hours: 7));

      final List<Map<String, dynamic>> maps = await db.query(
        'historicoAtividade',
        where: 'data >= ?',
        whereArgs: [seteHorasAtras.toIso8601String()],
        orderBy: 'data ASC',
        limit: 7,
      );

      _ultimasSeteHoras = List.generate(maps.length, (i) {
        return Atividade(
          passos: maps[i]['passos'],
          data: DateTime.parse(maps[i]['data']),
        );
      });

      print("📊 Carregadas ${_ultimasSeteHoras.length} horas para o gráfico");
      notifyListeners();
      return _ultimasSeteHoras;
    } catch (e) {
      print("❌ Erro em getUltimasSeteHoras: $e");
      return [];
    }
  }

  // ✅ NOVO: Busca todas as atividades do dia (para a lista de detalhes)
  Future<List<Atividade>> getAtividadesHoje() async {
    try {
      db = await DB.instance.database;

      DateTime agora = DateTime.now();
      DateTime inicioDoDia = DateTime(agora.year, agora.month, agora.day);
      DateTime fimDoDia = inicioDoDia.add(Duration(days: 1));

      final List<Map<String, dynamic>> maps = await db.query(
        'historicoAtividade',
        where: 'data >= ? AND data < ?',
        whereArgs: [inicioDoDia.toIso8601String(), fimDoDia.toIso8601String()],
        orderBy: 'data DESC', // Mais recente primeiro
      );

      _atividadesHoje = List.generate(maps.length, (i) {
        return Atividade(
          passos: maps[i]['passos'],
          data: DateTime.parse(maps[i]['data']),
        );
      });

      print("📋 Carregadas ${_atividadesHoje.length} horas de hoje para detalhes");
      notifyListeners();
      return _atividadesHoje;
    } catch (e) {
      print("❌ Erro em getAtividadesHoje: $e");
      return [];
    }
  }

  // ✅ Busca o último registro de uma hora específica
  Future<Map<String, dynamic>?> _buscarRegistroHora(int hora, int dia, int mes, int ano) async {
    try {
      db = await DB.instance.database;

      DateTime inicioDaHora = DateTime(ano, mes, dia, hora);
      DateTime fimDaHora = inicioDaHora.add(Duration(hours: 1));

      final List<Map<String, dynamic>> resultado = await db.query(
        'historicoAtividade',
        where: 'data >= ? AND data < ?',
        whereArgs: [inicioDaHora.toIso8601String(), fimDaHora.toIso8601String()],
        orderBy: 'data DESC',
        limit: 1,
      );

      if (resultado.isNotEmpty) {
        return resultado.first;
      }
      return null;
    } catch (e) {
      print("❌ Erro ao buscar registro da hora: $e");
      return null;
    }
  }

  // ✅ Busca passos totais acumulados até determinada hora
  Future<int> _buscarPassosTotaisAteHora(DateTime dataHora) async {
    try {
      db = await DB.instance.database;

      DateTime inicioDoDia = DateTime(dataHora.year, dataHora.month, dataHora.day);
      DateTime inicioProximaHora = DateTime(
          dataHora.year,
          dataHora.month,
          dataHora.day,
          dataHora.hour
      );

      final List<Map<String, dynamic>> resultado = await db.query(
        'historicoAtividade',
        where: 'data >= ? AND data < ?',
        whereArgs: [inicioDoDia.toIso8601String(), inicioProximaHora.toIso8601String()],
        orderBy: 'data DESC',
        limit: 1,
      );

      if (resultado.isNotEmpty) {
        return resultado.first['passos'] as int;
      }
      return 0;
    } catch (e) {
      print("❌ Erro ao buscar passos até hora: $e");
      return 0;
    }
  }

  // ✅ Insere novo registro
  Future<int> _inserirRegistro(int passos, DateTime data) async {
    try {
      db = await DB.instance.database;

      int id = await db.insert(
        'historicoAtividade',
        {
          'passos': passos,
          'data': data.toIso8601String(),
        },
      );

      print("✅ INSERT - ID: $id | $passos passos | ${data.hour}:${data.minute}h");
      await getUltimasSeteHoras();
      await getAtividadesHoje(); // ✅ Atualiza também a lista do dia
      return id;
    } catch (e) {
      print("❌ Erro ao inserir: $e");
      return -1;
    }
  }

  // ✅ Atualiza registro existente
  Future<void> _atualizarRegistro(int id, int passos, DateTime data) async {
    try {
      db = await DB.instance.database;

      await db.update(
        'historicoAtividade',
        {
          'passos': passos,
          'data': data.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      print("🔄 UPDATE - ID: $id | $passos passos | ${data.hour}:${data.minute}h");
      await getUltimasSeteHoras();
      await getAtividadesHoje(); // ✅ Atualiza também a lista do dia
    } catch (e) {
      print("❌ Erro ao atualizar: $e");
    }
  }

  // ✅ Agrupa passos por hora usando BD
  void agrupaHora(StepCount event) async {
    try {
      int horaEvento = event.timeStamp.hour;
      int diaEvento = event.timeStamp.day;
      int mesEvento = event.timeStamp.month;
      int anoEvento = event.timeStamp.year;

      print("🔵 Evento recebido: ${event.steps} passos às ${horaEvento}:${event.timeStamp.minute}h");

      Map<String, dynamic>? registroExistente = await _buscarRegistroHora(
          horaEvento,
          diaEvento,
          mesEvento,
          anoEvento
      );

      if (registroExistente != null) {
        int idExistente = registroExistente['id'] as int;
        int passosAteHoraAnterior = await _buscarPassosTotaisAteHora(event.timeStamp);
        int passosNestaHora = event.steps - passosAteHoraAnterior;

        print("   📌 Registro encontrado - ID: $idExistente");
        print("   📊 Passos até hora anterior: $passosAteHoraAnterior");
        print("   ➕ Passos nesta hora: $passosNestaHora");

        await _atualizarRegistro(idExistente, passosNestaHora, event.timeStamp);

        _horaAtual = horaEvento;
        _idRegistroAtual = idExistente;

      } else {
        int passosAteHoraAnterior = await _buscarPassosTotaisAteHora(event.timeStamp);
        int passosNestaHora = event.steps - passosAteHoraAnterior;

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        print("🆕 NOVA HORA: ${horaEvento}h");
        print("   📊 Passos até hora anterior: $passosAteHoraAnterior");
        print("   ➕ Passos nesta hora: $passosNestaHora");
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

        int novoId = await _inserirRegistro(passosNestaHora, event.timeStamp);

        _horaAtual = horaEvento;
        _idRegistroAtual = novoId;
      }

    } catch (e) {
      print("❌ Erro em agrupaHora: $e");
      print("   Stack: ${StackTrace.current}");
    }
  }

  // ✅ Calcula ritmo
  void calcRitmo(StepCount event) {
    try {
      history.addFirst(event);
      StepCount first = history.first;
      StepCount last = history.last;
      int tempo = 0;
      int tInicial = 0;
      int tFinal = 0;

      if (first.timeStamp.hour == last.timeStamp.hour) {
        if (last.timeStamp.minute == first.timeStamp.minute) {
          tempo = first.timeStamp.second;
        } else {
          tInicial = last.timeStamp.minute.toInt();
          tFinal = first.timeStamp.minute.toInt();
          tempo = (tFinal - tInicial) * 60;
        }
      } else {
        tInicial = 60 - last.timeStamp.minute.toInt();
        tFinal = first.timeStamp.minute.toInt();
        tempo = (tFinal + tInicial) * 60;
      }

      if (tempo <= 600) {
        int passosInicio = last.steps.toInt();
        int passosFim = first.steps.toInt();
        double pace = (passosFim - passosInicio) / tempo;

        String novoRitmo;
        if (pace <= 80 / 60) {
          novoRitmo = 'Leve';
        } else if (pace > 80 / 60 && pace <= 110 / 60) {
          novoRitmo = 'Moderado';
        } else {
          novoRitmo = 'Intenso';
        }

        if (ritmoAtual != novoRitmo) {
          ritmoAtual = novoRitmo;
          notifyListeners();
        }
      } else {
        history.clear();
        if (ritmoAtual != 'Leve') {
          ritmoAtual = 'Leve';
          notifyListeners();
        }
      }
    } catch (e) {
      print("❌ Erro em calcRitmo: $e");
    }
  }

  // ✅ DEBUG: Listar todos os registros
  Future<void> listarTodosRegistros() async {
    try {
      db = await DB.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'historicoAtividade',
        orderBy: 'data DESC',
      );

      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      print("📋 REGISTROS NO BD: ${maps.length}");
      for (var map in maps) {
        DateTime data = DateTime.parse(map['data']);
        print("   ID: ${map['id']} | ${map['passos']} passos | ${data.day}/${data.month} às ${data.hour}:${data.minute.toString().padLeft(2, '0')}h");
      }
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    } catch (e) {
      print("❌ Erro ao listar: $e");
    }
  }

  // ✅ LIMPAR: Remove todos os dados
  Future<void> limparTodosDados() async {
    try {
      db = await DB.instance.database;
      int count = await db.delete('historicoAtividade');
      print("🗑️ $count registros deletados");

      history.clear();
      _horaAtual = null;
      _idRegistroAtual = null;

      await getUltimasSeteHoras();
      await getAtividadesHoje();
    } catch (e) {
      print("❌ Erro ao limpar: $e");
    }
  }

  // ✅ TESTE: Simular dados
  Future<void> testarSalvamento() async {
    print("🧪 INICIANDO TESTE");

    DateTime agora = DateTime.now();

    List<Map<String, dynamic>> dadosTeste = [
      {'passos': 250, 'hora': agora.subtract(Duration(hours: 9))},
      {'passos': 380, 'hora': agora.subtract(Duration(hours: 8))},
      {'passos': 450, 'hora': agora.subtract(Duration(hours: 7))},
      {'passos': 680, 'hora': agora.subtract(Duration(hours: 6))},
      {'passos': 320, 'hora': agora.subtract(Duration(hours: 5))},
      {'passos': 890, 'hora': agora.subtract(Duration(hours: 4))},
      {'passos': 550, 'hora': agora.subtract(Duration(hours: 3))},
      {'passos': 420, 'hora': agora.subtract(Duration(hours: 2))},
      {'passos': 760, 'hora': agora.subtract(Duration(hours: 1))},
    ];

    for (var dado in dadosTeste) {
      await _inserirRegistro(dado['passos'] as int, dado['hora'] as DateTime);
    }

    print("🧪 TESTE CONCLUÍDO!");
    await listarTodosRegistros();
  }
}