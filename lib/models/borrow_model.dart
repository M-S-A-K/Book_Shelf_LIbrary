class BorrowModel {
  final int? id;
  final int userId;
  final int bookId;
  final String bookTitle;
  final String issueDate;
  final String dueDate;
  final String? returnDate;
  final String status; // 'borrowed' or 'returned'
  final double fine;
  final int renewCount; // 0 or 1

  BorrowModel({
    this.id,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
    this.status = 'borrowed',
    this.fine = 0.0,
    this.renewCount = 0,
  });

  // Convert BorrowModel to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'book_title': bookTitle,
      'issue_date': issueDate,
      'due_date': dueDate,
      'return_date': returnDate,
      'status': status,
      'fine': fine,
      'renew_count': renewCount,
    };
  }

  // Create BorrowModel from SQLite Map
  factory BorrowModel.fromMap(Map<String, dynamic> map) {
    return BorrowModel(
      id: map['id'],
      userId: map['user_id'] ?? 0,
      bookId: map['book_id'] ?? 0,
      bookTitle: map['book_title'] ?? '',
      issueDate: map['issue_date'] ?? '',
      dueDate: map['due_date'] ?? '',
      returnDate: map['return_date'],
      status: map['status'] ?? 'borrowed',
      fine: (map['fine'] as num?)?.toDouble() ?? 0.0,
      renewCount: map['renew_count'] ?? 0,
    );
  }
}

