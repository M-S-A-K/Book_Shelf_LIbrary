import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/borrow_model.dart';
import '../models/user_model.dart';
import '../widgets/borrow_card.dart';
import '../widgets/message_dialog.dart';

class BorrowedBooksScreen extends StatefulWidget {
  final UserModel user;

  const BorrowedBooksScreen({super.key, required this.user});

  @override
  State<BorrowedBooksScreen> createState() => _BorrowedBooksScreenState();
}

class _BorrowedBooksScreenState extends State<BorrowedBooksScreen> {
  List<BorrowModel> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await DatabaseHelper.instance.getStudentBorrowedBooks(widget.user.id!);
    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
      });
    }
  }

  double _calculateTotalPendingFine() {
    double total = 0.0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var r in _records) {
      if (r.status == 'borrowed') {
        final parts = r.dueDate.split('-');
        final due = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        if (today.isAfter(due)) {
          int days = today.difference(due).inDays;
          total += (days * 10.0);
        }
      } else {
        total += r.fine;
      }
    }
    return total;
  }

  void _returnBook(BorrowModel record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Return Book'),
        content: Text('Confirm return for "${record.bookTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              double fine = await DatabaseHelper.instance.returnBook(
                recordId: record.id!,
                bookId: record.bookId,
                dueDateStr: record.dueDate,
              );

              if (!mounted) return;
              _loadRecords();

              if (fine > 0) {
                showAppDialog(
                  context,
                  title: 'Book Returned',
                  message: 'Late fine: Rs. ${fine.toStringAsFixed(0)}.\n\nPlease pay the fine to the librarian.',
                );
              } else {
                showAppDialog(
                  context,
                  title: 'Book Returned',
                  message: 'Book returned successfully on time!',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _renewBook(BorrowModel record) async {
    String? error = await DatabaseHelper.instance.renewBook(
      recordId: record.id!,
      currentDueDateStr: record.dueDate,
    );

    if (!mounted) return;

    if (error != null) {
      showAppDialog(
        context,
        title: 'Notice',
        message: error,
      );
    } else {
      _loadRecords();
      showAppDialog(
        context,
        title: 'Renewed',
        message: 'Book renewed for 7 more days.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _records.where((r) => r.status == 'borrowed').length;
    final totalFine = _calculateTotalPendingFine();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Borrowed Books'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecords,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview summary cards (Pakistani currency display, no Indian rupee icon)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00897B).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.book, color: Color(0xFF00897B), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$activeCount',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const Text('Issued Books', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.payments_outlined, color: Colors.redAccent, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rs. ${totalFine.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                    ),
                                    const Text('Late Fee Due', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'Borrowing History & Active Books',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),

                    if (_records.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 50),
                          child: Text(
                            'No borrowed books yet',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          return BorrowCard(
                            record: _records[index],
                            onReturn: () => _returnBook(_records[index]),
                            onRenew: () => _renewBook(_records[index]),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
