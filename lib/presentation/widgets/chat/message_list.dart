import 'package:flutter/material.dart';
import '../../../data/models/message_model.dart';
import 'message_bubble.dart';

/// List of chat messages
class MessageList extends StatefulWidget {
  final List<MessageModel> messages;
  final String? streamingContent;
  final bool showTimestamps;

  const MessageList({
    super.key,
    required this.messages,
    this.streamingContent,
    this.showTimestamps = true,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to bottom when new messages arrive
    if (widget.messages.length != oldWidget.messages.length ||
        widget.streamingContent != oldWidget.streamingContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStreamingContent =
        widget.streamingContent != null && widget.streamingContent!.isNotEmpty;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: widget.messages.length + (hasStreamingContent ? 1 : 0),
      itemBuilder: (context, index) {
        // Show streaming content at the end
        if (hasStreamingContent && index == widget.messages.length) {
          return StreamingMessageBubble(content: widget.streamingContent!);
        }

        final message = widget.messages[index];
        return MessageBubble(
          message: message,
          showTimestamp: widget.showTimestamps,
        );
      },
    );
  }
}
