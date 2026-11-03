import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/book_model.dart';
import '../models/user_model.dart';
import '../widgets/message_dialog.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel book;
  final UserModel user;

  const BookDetailScreen({
    super.key,
    required this.book,
    required this.user,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isBorrowing = false;

  void _borrowBook() async {
    setState(() => _isBorrowing = true);

    String? error = await DatabaseHelper.instance.borrowBook(
      userId: widget.user.id!,
      bookId: widget.book.id!,
      bookTitle: widget.book.title,
    );

    setState(() => _isBorrowing = false);

    if (!mounted) return;

    if (error != null) {
      showAppDialog(
        context,
        title: 'Cannot Borrow',
        message: error,
      );
    } else {
      // Short & simple confirmation dialog as requested
      showAppDialog(
        context,
        title: 'Book Borrowed',
        message: 'Successfully Borrowed!\n\nReturn within 7 days to avoid late fine (Rs. 10/day).',
        onOk: () => Navigator.pop(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = widget.book.isAvailable == 1;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Book Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Book Icon Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00897B).withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 60,
                color: Color(0xFF00897B),
              ),
            ),
            const SizedBox(height: 24),

            // Book Title
            Text(
              widget.book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Author
            Text(
              'Author: ${widget.book.author}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),

            // Category & Availability Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.book.category,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAvailable ? Colors.green.shade400 : Colors.orange.shade400,
                    ),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Borrowed',
                    style: TextStyle(
                      color: isAvailable ? Colors.green.shade700 : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Borrow Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isAvailable && !_isBorrowing) ? _borrowBook : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isBorrowing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isAvailable ? 'Borrow This Book' : 'Book Currently Unavailable',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
