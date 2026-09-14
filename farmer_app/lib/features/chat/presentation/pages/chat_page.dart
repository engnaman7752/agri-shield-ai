import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/features/chat/data/chat_model.dart';
import 'package:farmer_app/features/chat/presentation/providers/chat_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String? insuranceId;
  final String? sensorCode;

  const ChatPage({super.key, this.insuranceId, this.sensorCode});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(chatProvider.notifier).sendMessage(
      text, 
      insuranceId: widget.insuranceId,
      sensorCode: widget.sensorCode,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    
    // Auto scroll when new messages arrive
    ref.listen(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.white),
            SizedBox(width: 8),
            Text('Farmer Shield AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => Navigator.pushNamed(context, '/settings/language'),
            tooltip: 'Change Language',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatState.messages.length && chatState.isLoading) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(message: chatState.messages[index]);
              },
            ),
          ),
          _buildQuickActions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      "Explain PMFBY Coverage",
      "Check My Field Sensor",
      "Pest Control Advice",
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(actions[index], style: const TextStyle(fontSize: 12)),
            backgroundColor: Colors.green.shade50,
            side: BorderSide(color: Colors.green.shade200),
            onPressed: () => _sendMessage(actions[index]),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Ask about PMFBY, crops, or weather...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.green,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Avatar + label row
            if (!message.isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.green.shade600,
                      child: const Icon(Icons.smart_toy, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text('Farmer Shield AI', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.green.shade600 : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
                  bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
                ),
                border: message.isUser ? null : Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: message.isUser
                  ? Text(
                      message.text,
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                    )
                  : _buildFormattedAIText(message.text),
            ),
            
            // ReAct Reasoning Steps UI
            if (!message.isUser && message.reasoningSteps.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      title: Row(
                        children: [
                          Icon(Icons.psychology, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'View AI Reasoning',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      childrenPadding: const EdgeInsets.all(12).copyWith(top: 0),
                      children: message.reasoningSteps.map((step) {
                        // Parse and prettify reasoning steps
                        final cleanStep = _cleanReasoningStep(step);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.arrow_right, size: 14, color: Colors.blue.shade400),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  cleanStep,
                                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Render AI text with basic formatting (bold, bullet points)
  Widget _buildFormattedAIText(String text) {
    // Split into lines and build rich text spans
    final lines = text.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      if (line.trim().startsWith('- ') || line.trim().startsWith('• ')) {
        // Bullet point
        children.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 15, color: Colors.black87)),
              Expanded(child: _buildRichLine(line.trim().substring(2))),
            ],
          ),
        ));
      } else if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 8));
      } else {
        children.add(_buildRichLine(line));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Build a single line with bold/code formatting
  Widget _buildRichLine(String line) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');
    int lastEnd = 0;

    for (final match in regex.allMatches(line)) {
      // Text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: line.substring(lastEnd, match.start),
          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        ));
      }
      if (match.group(1) != null) {
        // Bold text
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold, height: 1.5),
        ));
      } else if (match.group(2) != null) {
        // Code text
        spans.add(WidgetSpan(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(match.group(2)!, style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.black87)),
          ),
        ));
      }
      lastEnd = match.end;
    }

    // Remaining text
    if (lastEnd < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastEnd),
        style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
      ));
    }

    if (spans.isEmpty) {
      return Text(line, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5));
    }

    return RichText(text: TextSpan(children: spans));
  }

  /// Clean up raw reasoning steps into readable format
  String _cleanReasoningStep(String step) {
    // Remove raw "Thought:", "Action:", "Observation:" prefixes and clean up
    return step
        .replaceAll(RegExp(r'Thought:\s*'), '💭 ')
        .replaceAll(RegExp(r'Action:\s*'), '⚡ Used tool: ')
        .replaceAll(RegExp(r'Observation:\s*'), '📋 Result: ')
        .replaceAll(RegExp(r'Decided to use tool '), 'Using ')
        .replaceAll('Waiting for backend data...', '')
        .replaceAll('Received data from tool', 'Got response')
        .replaceAll('Direct response without tools', 'Answered directly')
        .replaceAll('Thinking...', 'Analyzing your question...')
        .trim();
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(0)),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
            ),
            SizedBox(width: 12),
            Text('AI is thinking...', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
