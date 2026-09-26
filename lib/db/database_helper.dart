import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/member.dart';
import '../models/attendance_record.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sr_no INTEGER NOT NULL,
        name TEXT NOT NULL,
        per_no TEXT,
        snsd_no TEXT,
        category TEXT NOT NULL,
        sub_category TEXT DEFAULT '',
        active INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        day TEXT,
        status TEXT,
        pv_time TEXT,
        UNIQUE(member_id, date),
        FOREIGN KEY (member_id) REFERENCES members (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sewadal_hajari.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedMembers(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Re-seed with the full/updated member list.
          await db.delete('members');
          await _seedMembers(db);
        }
      },
    );
  }

  // ---------------- Seed data (from the printed chart) ----------------
  // NOTE: This is a starter set transcribed from the printed columns of the
  // uploaded chart (Sr.No / Name / Per.No). Add the remaining members via
  // the in-app "Add Member" screen or bulk-import them with CSV Import,
  // so names are 100% accurate rather than guessed from handwriting.
  Future<void> _seedMembers(Database db) async {
    final gents = <Map<String, dynamic>>[
      {'sr': 1, 'name': 'Ashok G. Jagtap', 'per': 'SNSD2015', 'snsd': '14879'},
      {
        'sr': 2,
        'name': 'Nankuram A. Jaiswar',
        'per': 'SNSD2015',
        'snsd': '14882'
      },
      {
        'sr': 3,
        'name': 'Sikandar S. Benvash',
        'per': 'SNSD2015',
        'snsd': '14883'
      },
      {
        'sr': 4,
        'name': 'Udaynath S. Saroj',
        'per': 'SNSD2015',
        'snsd': '14887'
      },
      {
        'sr': 5,
        'name': 'Ashok M. Maragaje',
        'per': 'SNSD2015',
        'snsd': '14889'
      },
      {
        'sr': 6,
        'name': 'Raghuveer O. Sharma',
        'per': 'SNSD2015',
        'snsd': '14890'
      },
      {
        'sr': 7,
        'name': 'VijayAnand P. Jaiswal',
        'per': 'SNSD2015',
        'snsd': '14893'
      },
      {
        'sr': 8,
        'name': 'Lalchand S. Prajapati',
        'per': 'SNSD2015',
        'snsd': '14894'
      },
      {
        'sr': 9,
        'name': 'Krishna N. Nishad',
        'per': 'SNSD2015',
        'snsd': '14895'
      },
      {
        'sr': 10,
        'name': 'Navnath G. Jadhav',
        'per': 'SNSD2015',
        'snsd': '14897'
      },
      {
        'sr': 11,
        'name': 'Prakash G. Gaikwad',
        'per': 'SNSD2015',
        'snsd': '14898'
      },
      {
        'sr': 12,
        'name': 'Yashwant G. Gurav',
        'per': 'SNSD2015',
        'snsd': '14901'
      },
      {'sr': 13, 'name': 'Sachin U. Kewat', 'per': 'SNSD2015', 'snsd': '14902'},
      {
        'sr': 14,
        'name': 'Govind B. Kokare',
        'per': 'SNSD2015',
        'snsd': '14905'
      },
      {
        'sr': 15,
        'name': 'Ramchandra B. Kokare',
        'per': 'SNSD2015',
        'snsd': '14906'
      },
      {
        'sr': 16,
        'name': 'Dinesh H. Govalkar (S/Shikshak)',
        'per': 'SNSD2015',
        'snsd': '14908'
      },
      {
        'sr': 17,
        'name': 'Nitin R.Ghegadmal',
        'per': 'SNSD2015',
        'snsd': '14909'
      },
      {'sr': 18, 'name': 'Sachin R Gholap', 'per': 'SNSD2015', 'snsd': '14912'},
      {
        'sr': 19,
        'name': 'Kishan N. Nishad',
        'per': 'SNSD2015',
        'snsd': '14913'
      },
      {
        'sr': 20,
        'name': 'Nitesh M. Gawade (Shikshak)',
        'per': 'SNSD2015',
        'snsd': '14914'
      },
      {
        'sr': 21,
        'name': 'Sanjay A. Gaikwad',
        'per': 'SNSD2015',
        'snsd': '14915'
      },
      {
        'sr': 22,
        'name': 'Shivkumar R. Rajak',
        'per': 'SNSD2015',
        'snsd': '14916'
      },
      {
        'sr': 23,
        'name': 'Gulabrao G. Pawar',
        'per': 'SNSD2015',
        'snsd': '14918'
      },
      {
        'sr': 24,
        'name': 'Ashok Kumar Gaud',
        'per': 'SNSD2015',
        'snsd': '14919'
      },
      {
        'sr': 25,
        'name': 'Bhimrao G. Ghante',
        'per': 'SNSD2015',
        'snsd': '14921'
      },
      {
        'sr': 26,
        'name': 'Kalpesh D. Golambade',
        'per': 'SNSD2015',
        'snsd': '14922'
      },
      {
        'sr': 27,
        'name': 'Navratan L. Nishad',
        'per': 'SNSD2015',
        'snsd': '14923'
      },
      {
        'sr': 28,
        'name': 'Chandrakant K. Pimple',
        'per': 'SNSD2015',
        'snsd': '14924'
      },
      {'sr': 29, 'name': 'Rau M. Sawant', 'per': 'SNSD2015', 'snsd': '14925'},
      {
        'sr': 30,
        'name': 'Pradip H. Jaiswar',
        'per': 'SNSD2015',
        'snsd': '14929'
      },
      {
        'sr': 31,
        'name': 'Vishal M. Bandal',
        'per': 'SNSD2015',
        'snsd': '14931'
      },
      {'sr': 32, 'name': 'Gautam L. Gupta', 'per': 'SNSD2015', 'snsd': '14933'},
      {
        'sr': 33,
        'name': 'Ramsaran R. Gupta',
        'per': 'SNSD2015',
        'snsd': '14935'
      },
      {
        'sr': 34,
        'name': 'Ganesh N. Jadhav',
        'per': 'SNSD2015',
        'snsd': '14936'
      },
      {'sr': 35, 'name': 'Amar A. Sharma', 'per': 'SNSD2015', 'snsd': '14937'},
      {'sr': 36, 'name': 'Vinod N. Jadhav', 'per': 'SNSD2015', 'snsd': '14938'},
      {'sr': 37, 'name': 'Arun G. Kokare', 'per': 'SNSD2015', 'snsd': '14939'},
      {'sr': 38, 'name': 'Vijay R. Sawant', 'per': 'SNSD2015', 'snsd': '14940'},
      {
        'sr': 39,
        'name': 'Gaurav S. Sharma',
        'per': 'SNSD2015',
        'snsd': '14941'
      },
      {'sr': 40, 'name': 'Ravi C. Pimple', 'per': 'SNSD2015', 'snsd': '14942'},
      {
        'sr': 41,
        'name': 'Navnath M. Kharat',
        'per': 'SNSD2015',
        'snsd': '14944'
      },
      {
        'sr': 42,
        'name': 'Gopal D. Kerekar',
        'per': 'SNSD2015',
        'snsd': '14945'
      },
      {
        'sr': 43,
        'name': 'Rajendra B. Kadam',
        'per': 'SNSD2015',
        'snsd': '14946'
      },
      {
        'sr': 44,
        'name': 'Ravindra J. Pandit',
        'per': 'SNSD2015',
        'snsd': '14945'
      },
      {'sr': 45, 'name': 'Akash S. Zagade', 'per': 'SNSD2015', 'snsd': '14951'},
      {'sr': 46, 'name': 'Kiran C. Pimple', 'per': 'SNSD2015', 'snsd': '14952'},
      {'sr': 47, 'name': 'Lahu R. Pawar', 'per': 'SNSD2015', 'snsd': '14953'},
      {'sr': 48, 'name': 'Yogesh S. Kori', 'per': 'SNSD2015', 'snsd': '14954'},
      {'sr': 49, 'name': 'Trimbak H. More', 'per': 'SNSD2015', 'snsd': '14956'},
      {
        'sr': 50,
        'name': 'Rushikesh S. Pawar',
        'per': 'SNSD2019',
        'snsd': '14957'
      },
      {'sr': 51, 'name': 'Vivek Sarode', 'per': 'SNSD2019', 'snsd': '13048'},
      {
        'sr': 52,
        'name': 'Balasahed Jadhav',
        'per': 'SNSD2019',
        'snsd': '13049'
      },
      {'sr': 53, 'name': 'Kiran Kharat', 'per': 'SNSD2019', 'snsd': '13050'},
      {
        'sr': 54,
        'name': 'Sevak B. Shekokar',
        'per': 'SNSD2019',
        'snsd': '13051'
      },
      {
        'sr': 55,
        'name': 'Ramesh A. Sapkal',
        'per': 'SNSD2019',
        'snsd': '13052'
      },
      {
        'sr': 56,
        'name': 'Subhash Maragaje',
        'per': 'SNSD2019',
        'snsd': '13053'
      },
      {'sr': 57, 'name': 'Omkar S. Pawar', 'per': 'SNSD2019', 'snsd': '13054'},
      {'sr': 58, 'name': 'Suhas kawade', 'per': 'SNSD2019', 'snsd': '17764'},
      {'sr': 59, 'name': 'Shivaji Pawar', 'per': 'SNSD2019', 'snsd': '17765'},
      {
        'sr': 60,
        'name': 'Harshwardhan More',
        'per': 'SNSD2019',
        'snsd': '17766'
      },
      {'sr': 61, 'name': 'Sameer K. Raut', 'per': 'SNSD2019', 'snsd': '11211'},
      {
        'sr': 62,
        'name': 'Yashraj S. Zagade',
        'per': 'SNSD2019',
        'snsd': '11213'
      },
      {
        'sr': 63,
        'name': 'Dipesh D. Govalkar',
        'per': 'SNSD2019',
        'snsd': '11216'
      },
      {'sr': 64, 'name': 'Jay P. Gaikwad', 'per': 'SNSD2019', 'snsd': '11221'},
      {
        'sr': 65,
        'name': 'Prashant N. Kharat',
        'per': 'SNSD2019',
        'snsd': '11225'
      },
      {'sr': 66, 'name': 'Jayesh S. Raut', 'per': 'UR', 'snsd': 'NA'},
    ];
    final ladies = <Map<String, dynamic>>[
      {
        'sr': 1,
        'name': 'Sunita S. Khamkar(Sanchalak)',
        'per': 'SNSD2015',
        'snsd': '74134'
      },
      {
        'sr': 2,
        'name': 'Premsheela V. Jaiswal',
        'per': 'SNSD2015',
        'snsd': '74135'
      },
      {
        'sr': 3,
        'name': 'Lakshmi N. Benvansh',
        'per': 'SNSD2015',
        'snsd': '74136'
      },
      {'sr': 4, 'name': 'Siddhi Jadhav', 'per': 'SNSD2015', 'snsd': '74137'},
      {
        'sr': 5,
        'name': 'Uma S. Jadhav(Shikshika)',
        'per': 'SNSD2015',
        'snsd': '74139'
      },
      {'sr': 6, 'name': 'Sonal R. Kamble', 'per': 'SNSD2015', 'snsd': '74143'},
      {
        'sr': 7,
        'name': 'Pooja L. Prajapati',
        'per': 'SNSD2015',
        'snsd': '74144'
      },
      {
        'sr': 8,
        'name': 'Manisha S. Jadhav',
        'per': 'SNSD2015',
        'snsd': '74145'
      },
      {
        'sr': 9,
        'name': 'Kalpana A. Chavan',
        'per': 'SNSD2015',
        'snsd': '74147'
      },
      {'sr': 10, 'name': 'Samiksha Kadam', 'per': 'SNSD2015', 'snsd': '74150'},
      {
        'sr': 11,
        'name': 'Kavita N. Jaiswar',
        'per': 'SNSD2015',
        'snsd': '74152'
      },
      {
        'sr': 12,
        'name': 'Harshada B. Shekokar',
        'per': 'SNSD2015',
        'snsd': '74155'
      },
      {
        'sr': 13,
        'name': 'Rachna S. Zagade',
        'per': 'SNSD2015',
        'snsd': '74156'
      },
      {
        'sr': 14,
        'name': 'Pushpa N. Jaiswar',
        'per': 'SNSD2015',
        'snsd': '74157'
      },
      {
        'sr': 15,
        'name': 'Suman B. Shekokar',
        'per': 'SNSD2015',
        'snsd': '74158'
      },
      {'sr': 16, 'name': 'Nanda P.Gaikwad', 'per': 'SNSD2015', 'snsd': '74160'},
      {
        'sr': 17,
        'name': 'Nanda A. Maragaje',
        'per': 'SNSD2015',
        'snsd': '74161'
      },
      {
        'sr': 18,
        'name': 'Manisha D. Jadhav',
        'per': 'SNSD2015',
        'snsd': '74162'
      },
      {'sr': 19, 'name': 'Ankita Shinde', 'per': 'SNSD2015', 'snsd': '74166'},
      {'sr': 20, 'name': 'Nanda Kale', 'per': 'SNSD2019', 'snsd': '74001'},
      {'sr': 21, 'name': 'Deepali S. Raut', 'per': 'SNSD2019', 'snsd': '74002'},
      {'sr': 22, 'name': 'Sangeeta Batham', 'per': 'SNSD2019', 'snsd': '74003'},
      {
        'sr': 23,
        'name': 'Supriya N. Gawade',
        'per': 'SNSD2019',
        'snsd': '74004'
      },
      {
        'sr': 24,
        'name': 'Anjali S. Khamkar',
        'per': 'SNSD2019',
        'snsd': '74006'
      },
      {
        'sr': 25,
        'name': 'Simaran Kanoujiya',
        'per': 'SNSD2019',
        'snsd': '74007'
      },
      {
        'sr': 26,
        'name': 'Ashwini A. Pawar',
        'per': 'SNSD2019',
        'snsd': '74008'
      },
      {
        'sr': 27,
        'name': 'Namrata K. Pimple',
        'per': 'SNSD2019',
        'snsd': '74009'
      },
      {
        'sr': 28,
        'name': 'Asmita G. Jadhav',
        'per': 'SNSD2019',
        'snsd': '74010'
      },
      {
        'sr': 29,
        'name': 'Madhuri V. Jadhav',
        'per': 'SNSD2019',
        'snsd': '74011'
      },
      {'sr': 30, 'name': 'Pooja Lokhande', 'per': 'SNSD2019', 'snsd': '74012'},
      {'sr': 31, 'name': 'Sadhana Tiwari', 'per': 'SNSD2019', 'snsd': '74014'},
      {
        'sr': 32,
        'name': 'Shubhangi P. Gaikwad',
        'per': 'SNSD2023',
        'snsd': '78019'
      },
      {
        'sr': 33,
        'name': 'Shivanshi Kanoujiya',
        'per': 'SNSD2023',
        'snsd': '78020'
      },
      {'sr': 34, 'name': 'Amisha Yadav', 'per': 'SNSD2023', 'snsd': '78021'},
      {
        'sr': 35,
        'name': 'Shashikala M. Badal',
        'per': 'SNSD2015',
        'snsd': '74169'
      },
      {
        'sr': 36,
        'name': 'Ashwini D. Golambade',
        'per': 'SNSD2015',
        'snsd': '74171'
      },
      {
        'sr': 37,
        'name': 'Manjula Y. Gurav',
        'per': 'SNSD2015',
        'snsd': '74172'
      },
      {
        'sr': 38,
        'name': 'Vaishali G. Kokare',
        'per': 'SNSD2015',
        'snsd': '74177'
      },
      {'sr': 39, 'name': 'Manti H. Sharma', 'per': 'SNSD2015', 'snsd': '74178'},
      {
        'sr': 40,
        'name': 'Savitri U. Kewat',
        'per': 'SNSD2015',
        'snsd': '74179'
      },
      {'sr': 41, 'name': 'Nidhi Singh', 'per': 'NA', 'snsd': 'NA'},
      {'sr': 42, 'name': 'Radhika A. Londhe', 'per': 'NA', 'snsd': 'NA'},
      {'sr': 43, 'name': 'Rupali A. Londhe', 'per': 'NA', 'snsd': 'NA'},
      {'sr': 44, 'name': 'Akshara A. Londhe', 'per': 'NA', 'snsd': 'NA'},
    ];

    for (final m in gents) {
      await db.insert('members', {
        'sr_no': m['sr'],
        'name': m['name'],
        'per_no': m['per'],
        'snsd_no': m['snsd'],
        'category': 'Gents',
        'sub_category': '',
        'active': 1,
      });
    }
    for (final m in ladies) {
      await db.insert('members', {
        'sr_no': m['sr'],
        'name': m['name'],
        'per_no': m['per'],
        'snsd_no': m['snsd'],
        'category': 'Ladies',
        'sub_category': '',
        'active': 1,
      });
    }
  }

  // ---------------- Members CRUD ----------------

  Future<int> insertMember(Member m) async {
    final db = await database;
    return db.insert('members', m.toMap()..remove('id'));
  }

  Future<int> updateMember(Member m) async {
    final db = await database;
    return db.update('members', m.toMap(), where: 'id = ?', whereArgs: [m.id]);
  }

  Future<int> deleteMember(int id) async {
    final db = await database;
    return db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Member>> getMembers(String category) async {
    final db = await database;
    final rows = await db.query(
      'members',
      where: 'category = ? AND active = 1',
      whereArgs: [category],
      orderBy: 'sr_no ASC',
    );
    return rows.map((r) => Member.fromMap(r)).toList();
  }

  // ---------------- Attendance CRUD ----------------

  /// Saves (insert or update) one attendance row, keyed by (member, date).
  Future<void> upsertAttendance(AttendanceRecord rec) async {
    final db = await database;
    await db.insert(
      'attendance',
      rec.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Saves a whole batch (used by the "Save All" button) in one transaction.
  Future<void> saveAttendanceBatch(List<AttendanceRecord> records) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final rec in records) {
        await txn.insert(
          'attendance',
          rec.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Fetches attendance for a category on a given date, keyed by member_id.
  Future<Map<int, AttendanceRecord>> getAttendanceForDate(
      String category, String date) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT a.* FROM attendance a
      INNER JOIN members m ON m.id = a.member_id
      WHERE m.category = ? AND a.date = ?
    ''', [category, date]);
    final map = <int, AttendanceRecord>{};
    for (final r in rows) {
      final rec = AttendanceRecord.fromMap(r);
      map[rec.memberId] = rec;
    }
    return map;
  }

  /// Re-reads a single record straight from disk - used to CONFIRM a save
  /// really persisted (the "refresh and check" requirement).
  Future<AttendanceRecord?> verifyAttendance(int memberId, String date) async {
    final db = await database;
    final rows = await db.query(
      'attendance',
      where: 'member_id = ? AND date = ?',
      whereArgs: [memberId, date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AttendanceRecord.fromMap(rows.first);
  }

  Future<List<String>> getAllSavedDates() async {
    final db = await database;
    final rows = await db
        .rawQuery('SELECT DISTINCT date FROM attendance ORDER BY date DESC');
    return rows.map((r) => r['date'] as String).toList();
  }
}
