import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB {
  // Construtor com acesso privado

  DB._();

  //Criar uma instância de DB

  static final DB instance = DB._();

  static Database? _database;

  get database async{
    if(_database != null) return _database;

    return await _initDatabase();
  }

  _initDatabase() async{
    return await openDatabase(
      join( await getDatabasesPath(), 'mioCardio.db'),
      version: 1,
      onCreate: _onCreate,
    );
  }

  _onCreate( db, version) async{
    await db.execute(_historicoAfericoes);
    await db.execute(_usuario);
    await db.execute(_historicoAtividade);
  }

  String get _historicoAfericoes => '''
    CREATE TABLE historicoAfericoes(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bpm INTEGER,
      data_afericao TEXT
    );
  ''';

  String get _usuario => '''
    CREATE TABLE usuario(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT,
      sexo INT,
      altura REAL,
      peso REAL,
      data_nascimento TEXT
    );
  ''';

  String get _historicoAtividade => '''
    CREATE TABLE historicoAtividade(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      passos INTEGER,
      data TEXT
    );
  ''';
}