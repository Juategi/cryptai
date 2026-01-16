import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/speech_provider.dart';

/// Chat input field widget with speech-to-text support
class ChatInputField extends ConsumerStatefulWidget {
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
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  bool _isListening = false;
  double _soundLevel = 0.0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
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

  Future<void> _toggleSpeechRecognition() async {
    final speechService = ref.read(speechServiceProvider);

    if (_isListening) {
      await speechService.cancelListening();
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
      return;
    }

    // Initialize if needed
    final initialized = await speechService.initialize();
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available on this device'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isListening = true);

    await speechService.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;

        setState(() {
          _controller.text = text;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: text.length),
          );
        });

        // Auto-send when speech recognition finalizes
        if (isFinal && text.trim().isNotEmpty) {
          setState(() {
            _isListening = false;
            _soundLevel = 0.0;
          });
          // Send the message automatically
          widget.onSend(text.trim());
          _controller.clear();
        }
      },
      onSoundLevel: (level) {
        if (mounted) {
          setState(() => _soundLevel = level);
        }
      },
    );
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
            // Microphone button
            if (!isGenerating) _buildMicrophoneButton(theme),
            if (!isGenerating) const SizedBox(width: 8),
            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled && !_isListening,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: _isListening
                        ? 'Listening...'
                        : isGenerating
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

  Widget _buildMicrophoneButton(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = _isListening ? 1.0 + (_pulseController.value * 0.1) : 1.0;
        final glowOpacity = _isListening ? 0.3 + (_soundLevel / 20) : 0.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: _isListening
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: glowOpacity),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  )
                : null,
            child: IconButton.filled(
              onPressed: widget.enabled ? _toggleSpeechRecognition : null,
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none_rounded),
              style: IconButton.styleFrom(
                backgroundColor: _isListening
                    ? AppColors.error
                    : theme.colorScheme.surfaceContainerHighest,
                foregroundColor:
                    _isListening ? Colors.white : theme.colorScheme.onSurface,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: IconButton.filled(
        onPressed: _hasText && widget.enabled && !_isListening
            ? _handleSend
            : null,
        icon: const Icon(Icons.send_rounded),
        style: IconButton.styleFrom(
          backgroundColor: _hasText
              ? AppColors.primary
              : theme.colorScheme.surfaceContainerHighest,
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
