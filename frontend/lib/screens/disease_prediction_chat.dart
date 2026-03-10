import 'package:flutter/material.dart';
import '../widgets/page_header.dart';
import '../services/api_service.dart';
import '../services/local_health_chat.dart'; // fallback when offline

class DiseasePredictionChat extends StatefulWidget {
  const DiseasePredictionChat({super.key});

  @override
  State<DiseasePredictionChat> createState() => _DiseasePredictionChatState();
}

class _DiseasePredictionChatState extends State<DiseasePredictionChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _messages.addAll([
      ChatMessage(
        text: "Hi! I'm your AI Health Assistant powered by machine learning. "
            "Describe your symptoms and I'll help identify possible conditions.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
      ChatMessage(
        text: "⚠️ This is a preliminary AI tool only. "
            "For accurate diagnosis, please consult a healthcare professional.",
        isUser: false,
        timestamp: DateTime.now(),
        isWarning: true,
      ),
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    String response;
    try {
      // Try the real ML backend first
      response = await _api.sendChatMessage(text);
    } catch (_) {
      // Offline fallback — rule-based local responses
      await Future.delayed(const Duration(milliseconds: 400));
      response = getLocalHealthResponse(text);
    }

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
      _isSending = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const PageHeader(
            title: 'Health Assistant',
            subtitle: 'AI-powered symptom analysis',
            icon: Icons.chat_bubble_outline,
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF20B2AA))),
                  SizedBox(width: 8),
                  Text('AI is thinking…', style: TextStyle(fontSize: 12, color: Color(0xFF20B2AA))),
                ],
              ),
            ),
          _buildInputRow(context),
        ],
      ),
    );
  }

  Widget _buildInputRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Type your symptoms here…',
                  hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 15),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2D3748)
                      : const Color(0xFFF0F4F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFF20B2AA), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isSending ? Colors.grey.shade300 : const Color(0xFF20B2AA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF20B2AA), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Builder(builder: (ctx) {
                  final isDark = Theme.of(ctx).brightness == Brightness.dark;
                  final warningBg = isDark ? const Color(0xFF2D2010) : const Color(0xFFFFF4E5);
                  final warningText = isDark ? const Color(0xFFFFCC80) : const Color(0xFF7A4F00);
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: message.isWarning
                          ? warningBg
                          : message.isUser
                              ? const Color(0xFF20B2AA)
                              : Theme.of(ctx).cardTheme.color ?? Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                      border: message.isWarning
                          ? Border.all(color: const Color(0xFFFFB74D), width: 1.5)
                          : message.isUser
                              ? null
                              : Border.all(color: Theme.of(ctx).dividerColor, width: 1),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isWarning
                            ? warningText
                            : message.isUser
                                ? Colors.white
                                : Theme.of(ctx).textTheme.bodyLarge?.color,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isWarning;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isWarning = false,
  });
}
