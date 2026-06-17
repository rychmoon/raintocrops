import 'package:flutter/material.dart';

class EmailAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String?>? onSuggestedEmailChanged;
  final String hintText;
  final String labelText;

  const EmailAutocompleteField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onSubmitted,
    this.onSuggestedEmailChanged,
    this.hintText = 'Enter your email',
    this.labelText = 'Email',
  });

  @override
  State<EmailAutocompleteField> createState() => _EmailAutocompleteFieldState();
}

class _EmailAutocompleteFieldState extends State<EmailAutocompleteField> {
  final FocusNode _focusNode = FocusNode();

  final List<String> _popularDomains = const [
    'gmail.com',
  ];

  String? _suggestedEmail;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
    _updateSuggestion();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    _updateSuggestion();
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  bool _looksCompleteEmail(String text) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text.trim());
  }

  void _updateSuggestion() {
    final text = widget.controller.text.trim();

    String? nextSuggestion;

    if (text.isEmpty || _looksCompleteEmail(text)) {
      nextSuggestion = null;
    } else if (!text.contains('@')) {
      nextSuggestion = '$text@${_popularDomains.first}';
    } else {
      final parts = text.split('@');
      final username = parts.first;
      final typedDomain = parts.length > 1 ? parts.last.toLowerCase() : '';

      if (username.isEmpty) {
        nextSuggestion = null;
      } else {
        final match = _popularDomains.cast<String?>().firstWhere(
              (d) => d!.startsWith(typedDomain),
          orElse: () => null,
        );

        nextSuggestion = match == null ? null : '$username@$match';
      }
    }

    if (_suggestedEmail != nextSuggestion) {
      setState(() {
        _suggestedEmail = nextSuggestion;
      });
      widget.onSuggestedEmailChanged?.call(nextSuggestion);
    }
  }

  String _ghostSuffix() {
    final typed = widget.controller.text;
    final suggestion = _suggestedEmail;

    if (!_focusNode.hasFocus || typed.isEmpty || suggestion == null) {
      return '';
    }

    if (suggestion.toLowerCase() == typed.toLowerCase()) {
      return '';
    }

    if (!suggestion.toLowerCase().startsWith(typed.toLowerCase())) {
      return '';
    }

    return suggestion.substring(typed.length);
  }

  void _applySuggestion() {
    final suggestion = _suggestedEmail;
    if (suggestion == null || suggestion.isEmpty) return;

    widget.controller.text = suggestion;
    widget.controller.selection = TextSelection.collapsed(
      offset: suggestion.length,
    );

    setState(() {});
    widget.onSuggestedEmailChanged?.call(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final ghostSuffix = _ghostSuffix();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.transparent,
                    width: 1,
                  ),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: widget.controller.text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.transparent,
                        ),
                      ),
                      TextSpan(
                        text: ghostSuffix,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              autofillHints: null,
              onSubmitted: (value) {
                if (_suggestedEmail != null &&
                    value.trim().isNotEmpty &&
                    !value.contains('@')) {
                  _applySuggestion();
                  widget.onSubmitted?.call(_suggestedEmail!);
                  return;
                }
                widget.onSubmitted?.call(value);
              },
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFBDBDBD),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.lightBlue,
                    width: 1,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFBDBDBD),
                    width: 1,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF6F6F6),
                suffixIcon: ghostSuffix.isNotEmpty
                    ? IconButton(
                  onPressed: _applySuggestion,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                )
                    : null,
              ),
            ),
          ],
        ),
        if (ghostSuffix.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _applySuggestion,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.alternate_email_rounded,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _suggestedEmail!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Text(
                    'Use',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}