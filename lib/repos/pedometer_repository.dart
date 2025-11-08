import 'package:flutter/cupertino.dart';
import 'package:miocardio_app/model/atividade.dart';
import 'package:sqflite/sqflite.dart';
import 'package:miocardio_app/database/db.dart';

class pedometerRepository extends ChangeNotifier {
  late Database db;
  List<Atividade> _atividades = [];
  int _ultimaHora = 0;


  get ultimaHora => _ultimaHora;
  List<Atividade> get atividades => _atividades;

  pedometerRepository() {
    _initRepository();
  }

  _initRepository() async {
    await _getAtividade;
  }

  _getAtividade(DateTime inicio, DateTime fim) async{
    db = await DB.instance.database;
  }

  setAtividade(int passos, DateTime data) async{
    db = await DB.instance.database;

    db.insert('historicoAtividade', {
      'passos': passos,
      'data' : data
    });

  }

}