import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/widgets.dart';

class GuestCountSelection extends StatefulWidget {
  const GuestCountSelection({
    super.key,
    required this.count,
    required this.onSubmit,
  });

  final int? count; // null = not answered yet
  final void Function(int count) onSubmit;

  @override
  State<GuestCountSelection> createState() => _GuestCountSelectionState();
}

class _GuestCountSelectionState extends State<GuestCountSelection> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final n = int.tryParse(_controller.text);
    if (n == null || n < 0 || n > 20) {
      setState(() => _error = 'Enter a whole number from 0 to 20');
      return;
    }
    setState(() => _error = null);
    widget.onSubmit(n);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.count == null
        ? "You haven't answered yet"
        : 'Your answer: ${widget.count} attending (0 = not coming)';

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'How many people are coming?',
                    errorText: _error,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StyledButton(onPressed: _save, child: const Text('SAVE')),
            ],
          ),
          const SizedBox(height: 4),
          Paragraph(status),
        ],
      ),
    );
  }
}
