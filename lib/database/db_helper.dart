import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/book_model.dart';
import '../models/borrow_model.dart';

class DatabaseHelper {
  // Singleton pattern so the app uses a single database connection
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Getter for the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('student_library.db');
    return _database!;
  }

  // Initialize and open database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Create tables and insert initial university books
  Future<void> _createDB(Database db, int version) async {
    // 1. Users Table (Student Only)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        student_id TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // 2. Books Table
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        is_available INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 3. Borrow Records Table
    await db.execute('''
      CREATE TABLE borrow_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        book_id INTEGER NOT NULL,
        book_title TEXT NOT NULL,
        issue_date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        return_date TEXT,
        status TEXT NOT NULL,
        fine REAL NOT NULL DEFAULT 0.0,
        renew_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Seed realistic university Computer Science books
    List<Map<String, dynamic>> defaultBooks = [
      {
        'title': 'Programming Fundamentals (PF)',
        'author': 'Tony Gaddis',
        'category': 'Programming',
        'description': 'Covers C++ basics, variables, conditional statements, loops, functions, and arrays.',
        'is_available': 1,
      },
      {
        'title': 'Data Structures & Algorithms (DSA)',
        'author': 'Robert Lafore',
        'category': 'Computer Science',
        'description': 'Comprehensive study of stacks, queues, linked lists, binary trees, graphs, and sorting.',
        'is_available': 1,
      },
      {
        'title': 'Object Oriented Programming (OOP)',
        'author': 'Bjarne Stroustrup',
        'category': 'Programming',
        'description': 'Master classes, objects, inheritance, polymorphism, encapsulation, and abstraction.',
        'is_available': 1,
      },
      {
        'title': 'Database Systems (DBMS)',
        'author': 'Abraham Silberschatz',
        'category': 'Database',
        'description': 'Relational model, SQL commands, ER modeling, normalization, and ACID properties.',
        'is_available': 1,
      },
      {
        'title': 'Operating Systems (OS)',
        'author': 'Silberschatz & Galvin',
        'category': 'Computer Science',
        'description': 'Process management, CPU scheduling, synchronization, deadlocks, and virtual memory.',
        'is_available': 1,
      },
      {
        'title': 'Computer Networks (CN)',
        'author': 'Andrew S. Tanenbaum',
        'category': 'Networking',
        'description': 'OSI 7 layers, TCP/IP protocol suite, subnetting, IP addressing, and routing algorithms.',
        'is_available': 1,
      },
      {
        'title': 'Software Engineering (SE)',
        'author': 'Ian Sommerville',
        'category': 'Software Eng',
        'description': 'Software development life cycle (SDLC), Agile Scrum, SRS documentation, and testing.',
        'is_available': 1,
      },
      {
        'title': 'Artificial Intelligence (AI)',
        'author': 'Stuart Russell',
        'category': 'AI',
        'description': 'Intelligent agents, state space search, heuristic search, logic, and introduction to ML.',
        'is_available': 1,
      },
      {
        'title': 'Discrete Mathematics',
        'author': 'Kenneth H. Rosen',
        'category': 'Mathematics',
        'description': 'Set theory, propositional logic, mathematical induction, relations, and graph theory.',
        'is_available': 1,
      },
      {
        'title': 'Web Application Development',
        'author': 'Jon Duckett',
        'category': 'Web Dev',
        'description': 'Core frontend and backend technologies: HTML5, CSS3, JavaScript, APIs, and databases.',
        'is_available': 1,
      },
    ];

    for (var book in defaultBooks) {
      await db.insert('books', book);
    }
  }

  // ---------------- STUDENT AUTH METHODS ----------------

  // Register a new student
  Future<int> registerStudent(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  // Login student by Email or Student ID and Password
  Future<UserModel?> loginStudent(String emailOrId, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: '(email = ? OR student_id = ?) AND password = ?',
      whereArgs: [emailOrId.trim(), emailOrId.trim(), password],
    );

    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }

  // ---------------- BOOK METHODS ----------------

  // Get all books
  Future<List<BookModel>> getAllBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('books', orderBy: 'title ASC');
    return maps.map((item) => BookModel.fromMap(item)).toList();
  }

  // Get books by category and/or search query
  Future<List<BookModel>> getBooks({String? category, String? searchQuery}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (category != null && category != 'All') {
      whereClause += 'category = ?';
      whereArgs.add(category);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += '(title LIKE ? OR author LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'title ASC',
    );

    return maps.map((item) => BookModel.fromMap(item)).toList();
  }

  // ---------------- BORROWING & RETURN METHODS ----------------

  // Borrow a book
  Future<String?> borrowBook({
    required int userId,
    required int bookId,
    required String bookTitle,
  }) async {
    final db = await database;

    // 1. Check if user already borrowed 3 books
    final activeBorrows = await db.rawQuery(
      "SELECT COUNT(*) as total FROM borrow_records WHERE user_id = ? AND status = 'borrowed'",
      [userId],
    );
    int currentBorrowedCount = Sqflite.firstIntValue(activeBorrows) ?? 0;
    if (currentBorrowedCount >= 3) {
      return 'You have reached the maximum borrowing limit of 3 books.';
    }

    // 2. Check if the book is available
    final bookCheck = await db.query(
      'books',
      where: 'id = ? AND is_available = 1',
      whereArgs: [bookId],
    );
    if (bookCheck.isEmpty) {
      return 'This book is currently unavailable.';
    }

    // 3. Dates: 7 days borrowing duration
    final now = DateTime.now();
    final dueDate = now.add(const Duration(days: 7));

    final issueDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final dueDateStr = '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';

    // 4. Insert borrow record and update book availability
    await db.transaction((txn) async {
      await txn.insert('borrow_records', {
        'user_id': userId,
        'book_id': bookId,
        'book_title': bookTitle,
        'issue_date': issueDateStr,
        'due_date': dueDateStr,
        'return_date': null,
        'status': 'borrowed',
        'fine': 0.0,
        'renew_count': 0,
      });

      await txn.update(
        'books',
        {'is_available': 0},
        where: 'id = ?',
        whereArgs: [bookId],
      );
    });

    return null; // Null means success with no error message
  }

  // Get borrowed books for a specific student
  Future<List<BorrowModel>> getStudentBorrowedBooks(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'borrow_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return maps.map((item) => BorrowModel.fromMap(item)).toList();
  }

  // Return a book and calculate fine (Rs. 10 per day late)
  Future<double> returnBook({
    required int recordId,
    required int bookId,
    required String dueDateStr,
  }) async {
    final db = await database;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final parts = dueDateStr.split('-');
    final due = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    int lateDays = 0;
    if (today.isAfter(due)) {
      lateDays = today.difference(due).inDays;
    }

    double fine = lateDays * 10.0;
    final returnDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await db.transaction((txn) async {
      // Update borrow record
      await txn.update(
        'borrow_records',
        {
          'status': 'returned',
          'return_date': returnDateStr,
          'fine': fine,
        },
        where: 'id = ?',
        whereArgs: [recordId],
      );

      // Mark book as available again
      await txn.update(
        'books',
        {'is_available': 1},
        where: 'id = ?',
        whereArgs: [bookId],
      );
    });

    return fine;
  }

  // Renew a borrowed book once (+7 days)
  Future<String?> renewBook({required int recordId, required String currentDueDateStr}) async {
    final db = await database;

    // Check if already renewed
    final records = await db.query(
      'borrow_records',
      where: 'id = ? AND status = ?',
      whereArgs: [recordId, 'borrowed'],
    );

    if (records.isEmpty) {
      return 'Borrow record not found.';
    }

    if ((records.first['renew_count'] as int) >= 1) {
      return 'This book has already been renewed once.';
    }

    final parts = currentDueDateStr.split('-');
    final currentDue = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final newDue = currentDue.add(const Duration(days: 7));
    final newDueDateStr = '${newDue.year}-${newDue.month.toString().padLeft(2, '0')}-${newDue.day.toString().padLeft(2, '0')}';

    await db.update(
      'borrow_records',
      {
        'due_date': newDueDateStr,
        'renew_count': 1,
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );

    return null; // Null means success
  }

  // ---------------- DASHBOARD STATS ----------------

  Future<Map<String, int>> getDashboardStats(int userId) async {
    final db = await database;

    final totalBooksCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM books'),
    ) ?? 0;

    final availableBooksCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM books WHERE is_available = 1'),
    ) ?? 0;

    final myBorrowedCount = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM borrow_records WHERE user_id = ? AND status = 'borrowed'",
        [userId],
      ),
    ) ?? 0;

    return {
      'total': totalBooksCount,
      'available': availableBooksCount,
      'borrowed': myBorrowedCount,
    };
  }
}

