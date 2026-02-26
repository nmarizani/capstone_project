import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../features/prediction/pph_prediction_service.dart';

/// Manages the local SQLite database for offline-first operation.
/// All patient data and assessments are saved locally first.
/// Predictions are queued when offline and synced when connectivity returns.
class LocalDbService {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ruvimbo_offline.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        full_name TEXT,
        id_number TEXT,
        station_id TEXT,
        phone_number TEXT,
        role TEXT DEFAULT 'midwife',
        login_method TEXT DEFAULT 'email',
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE patients (
        local_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age REAL,
        heart_rate REAL,
        hemoglobin REAL,
        systolic_bp INTEGER,
        diastolic_bp INTEGER,
        blood_sugar REAL,
        bmi REAL,
        gestational_age INTEGER,
        prev_complications INTEGER DEFAULT 0,
        preexist_diabetes INTEGER DEFAULT 0,
        gest_diabetes INTEGER DEFAULT 0,
        mental_health INTEGER DEFAULT 0,
        hypertension INTEGER DEFAULT 0,
        blood_type TEXT,
        postpartum_minutes INTEGER,
        status TEXT DEFAULT 'active',
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE assessment_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_local_id TEXT NOT NULL,
        visit_id TEXT NOT NULL,
        request_json TEXT NOT NULL,
        response_json TEXT,
        status TEXT DEFAULT 'pending',
        risk_band TEXT,
        probability REAL,
        sync_attempts INTEGER DEFAULT 0,
        created_at TEXT,
        synced_at TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // migrations here
  }

  // USERS

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final db = await database;
    final rows =
        await db.query('users', where: 'uid = ?', whereArgs: [uid]);
    return rows.isNotEmpty ? rows.first : null;
  }

  // PATIENTS

  static Future<void> savePatient(Map<String, dynamic> patient) async {
    final db = await database;
    patient['updated_at'] = DateTime.now().toIso8601String();
    await db.insert('patients', patient,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    final db = await database;
    return db.query('patients', orderBy: 'created_at DESC');
  }

  static Future<Map<String, dynamic>?> getPatient(String localId) async {
    final db = await database;
    final rows = await db.query('patients',
        where: 'local_id = ?', whereArgs: [localId]);
    return rows.isNotEmpty ? rows.first : null;
  }

  // ASSESSMENT QUEUE

  /// Save a prediction request locally (always done first, before API call)
  static Future<int> enqueueAssessment({
    required String patientLocalId,
    required String visitId,
    required PPHPredictionRequest request,
  }) async {
    final db = await database;
    return db.insert('assessment_queue', {
      'patient_local_id': patientLocalId,
      'visit_id': visitId,
      'request_json': jsonEncode(request.toJson()),
      'status': 'pending',
      'sync_attempts': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Update a queued assessment with the API response
  static Future<void> saveAssessmentResult({
    required int queueId,
    required PPHPredictionResult result,
  }) async {
    final db = await database;
    await db.update(
      'assessment_queue',
      {
        'response_json': jsonEncode(result.modelInfo),
        'status': 'synced',
        'risk_band': result.prediction.riskBand.name,
        'probability': result.prediction.pphProxyProbability,
        'synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [queueId],
    );
  }

  static Future<void> markAssessmentFailed(int queueId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE assessment_queue SET status = ?, sync_attempts = sync_attempts + 1 WHERE id = ?',
      ['failed', queueId],
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingAssessments() async {
    final db = await database;
    return db.query('assessment_queue',
        where: 'status = ?', whereArgs: ['pending']);
  }

  static Future<List<Map<String, dynamic>>> getAssessmentsForPatient(
      String patientLocalId) async {
    final db = await database;
    return db.query(
      'assessment_queue',
      where: 'patient_local_id = ?',
      whereArgs: [patientLocalId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<Map<String, dynamic>?> getLatestAssessment(
      String patientLocalId) async {
    final db = await database;
    final rows = await db.query(
      'assessment_queue',
      where: 'patient_local_id = ? AND status = ?',
      whereArgs: [patientLocalId, 'synced'],
      orderBy: 'synced_at DESC',
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }
}