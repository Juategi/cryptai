import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Chat input field widget
class ChatInputField extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onSend;
  final VoidCallback? onCancel;

  const ChatInputField({
    super.key,
    this.enabled = true,
    required this.onSend,
    this.onCancel,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.enabled) {
      widget.onSend(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGenerating = widget.onCancel != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: isGenerating
                        ? 'Generating response...'
                        : 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isGenerating)
              _buildCancelButton()
            else
              _buildSendButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: IconButton.filled(
        onPressed: _hasText && widget.enabled ? _handleSend : null,
        icon: const Icon(Icons.send_rounded),
        style: IconButton.styleFrom(
          backgroundColor:
              _hasText ? AppColors.primary : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: _hasText ? Colors.white : theme.colorScheme.outline,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return IconButton.filled(
      onPressed: widget.onCancel,
      icon: const Icon(Icons.stop_rounded),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
