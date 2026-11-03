import 'package:flutter/material.dart';
import '../models/borrow_model.dart';

class BorrowCard extends StatelessWidget {
  final BorrowModel record;
  final VoidCallback onReturn;
  final VoidCallback onRenew;

  const BorrowCard({
    super.key,
    required this.record,
    required this.onReturn,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBorrowed = record.status == 'borrowed';

    // Check overdue
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final parts = record.dueDate.split('-');
    final due = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final bool isOverdue = isBorrowed && today.isAfter(due);
    final int lateDays = isOverdue ? today.difference(due).inDays : 0;
    final double currentFine = lateDays * 10.0;

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.bookTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isBorrowed
                        ? (isOverdue ? Colors.red.shade50 : Colors.teal.shade50)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isBorrowed
                          ? (isOverdue ? Colors.red.shade300 : const Color(0xFF00897B))
                          : Colors.grey.shade400,
                    ),
                  ),
                  child: Text(
                    isBorrowed ? (isOverdue ? 'Overdue' : 'Active') : 'Returned',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isBorrowed
                          ? (isOverdue ? Colors.red.shade700 : const Color(0xFF00897B))
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dates
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  'Issued: ${record.issueDate}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.event_available, size: 13, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  'Due: ${record.dueDate}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? Colors.red : Colors.black87,
                  ),
                ),
              ],
            ),

            // Overdue fine warning & librarian instruction
            if (isOverdue) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Late by $lateDays days • Fine: Rs. ${currentFine.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Please pay the fine to the librarian upon return.',
                      style: TextStyle(fontSize: 11, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],

            if (!isBorrowed && record.fine > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Returned late. Fine paid: Rs. ${record.fine.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            // Action Buttons
            if (isBorrowed) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: record.renewCount >= 1 ? null : onRenew,
                    icon: const Icon(Icons.refresh, size: 15),
                    label: Text(
                      record.renewCount >= 1 ? 'Renewed' : 'Renew (+7d)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00897B),
                      side: const BorderSide(color: Color(0xFF00897B)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: onReturn,
                    icon: const Icon(Icons.keyboard_return, size: 15),
                    label: const Text('Return Book', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

