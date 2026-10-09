import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/reconstruction_draft.dart';
import '../../models/venue_assistant_message.dart';
import '../../services/venue_assistant.dart';

/// Floating circular AI Venue Assistant button and expandable compact popup.
///
/// Principles:
/// - Small circular floating button when closed (Deep black, metallic gold, subtle burgundy, warm off-white).
/// - Expands smoothly into a compact floating popup above the configuration surface without replacing it.
/// - Authoritative logical assistance mutating [ReconstructionDraft] ONLY.
/// - Preserves conversation history across close and reopen within the capture session.
class FloatingVenueAssistant extends StatefulWidget {
  final String sessionId;
  final String theatreId;
  final String contextName;
  final ReconstructionDraft currentDraft;
  final ValueChanged<ReconstructionDraft>? onDraftUpdated;
  final VoidCallback? onMeasurementRequested;

  const FloatingVenueAssistant({
    super.key,
    required this.sessionId,
    required this.theatreId,
    required this.currentDraft,
    this.contextName = 'Venue Configuration',
    this.onDraftUpdated,
    this.onMeasurementRequested,
  });

  @override
  State<FloatingVenueAssistant> createState() => _FloatingVenueAssistantState();
}

class _FloatingVenueAssistantState extends State<FloatingVenueAssistant>
    with SingleTickerProviderStateMixin {
  late VenueAssistant _assistant;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isOpen = false;
  bool _processing = false;

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _deepBlack = Color(0xFF0C0C10);
  static const Color _burgundy = Color(0xFF5A1226);
  static const Color _offWhite = Color(0xFFF7F5F0);
  static const Color _mutedGrey = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _initAssistant();
  }

  void _initAssistant() {
    _assistant = VenueAssistantRegistry.getOrCreate(widget.sessionId);
    _assistant.ensureGreeting(contextName: widget.contextName);
  }

  @override
  void didUpdateWidget(covariant FloatingVenueAssistant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _initAssistant();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleOpen() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animController.forward();
        _scrollToBottom();
      } else {
        _animController.reverse();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _inputController.text.trim();
    if (text.isEmpty || _processing) return;

    if (presetText == null) {
      _inputController.clear();
    }

    setState(() => _processing = true);
    _scrollToBottom();

    try {
      final response = await _assistant.processMessage(
        text: text,
        draft: widget.currentDraft,
        contextName: widget.contextName,
      );

      if (response.updatedDraft != null &&
          response.updatedDraft != widget.currentDraft) {
        widget.onDraftUpdated?.call(response.updatedDraft!);
      }

      if (response.requiresMeasurement) {
        widget.onMeasurementRequested?.call();
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxPopupWidth = math.min(380.0, size.width - 32.0);
    final maxPopupHeight = math.min(520.0, size.height - 110.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Compact Floating Popup
        if (_isOpen)
          ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment.bottomRight,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                key: const Key('floating_venue_assistant_popup'),
                width: maxPopupWidth,
                height: maxPopupHeight,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xF80C0C10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _gold.withValues(alpha: 0.35), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: _burgundy.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const Divider(height: 1, color: Color(0x33D4AF37)),
                      Expanded(child: _buildMessagesList()),
                      _buildQuickActionChips(),
                      const Divider(height: 1, color: Color(0x22D4AF37)),
                      _buildInputArea(),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Small Circular Floating Button
        GestureDetector(
          onTap: _toggleOpen,
          child: Container(
            key: const Key('floating_venue_assistant_button'),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF221F1C), _deepBlack],
              ),
              border: Border.all(
                color: _isOpen ? _gold : _gold.withValues(alpha: 0.85),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: _burgundy.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: AnimatedRotation(
                turns: _isOpen ? 0.125 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isOpen ? Icons.close : Icons.auto_awesome,
                  color: _gold,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: const Color(0xFF141318),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _burgundy.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withValues(alpha: 0.5), width: 1),
            ),
            child: const Icon(Icons.auto_awesome, color: _gold, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AI VENUE ASSISTANT',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  widget.contextName,
                  style: const TextStyle(
                    color: _offWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('floating_venue_assistant_close'),
            icon: const Icon(Icons.close, color: _mutedGrey, size: 18),
            onPressed: _toggleOpen,
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final messages = _assistant.messages;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isAdmin = msg.role == VenueAssistantRole.admin;
        return _buildMessageBubble(msg, isAdmin);
      },
    );
  }

  Widget _buildMessageBubble(VenueAssistantMessage msg, bool isAdmin) {
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isAdmin ? const Color(0xFF261219) : const Color(0xFF16161D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAdmin ? _burgundy.withValues(alpha: 0.6) : _gold.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(
                color: _offWhite,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            if (msg.actionSummary != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _gold.withValues(alpha: 0.35), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune, color: _gold, size: 10),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        msg.actionSummary!,
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (msg.requiresMeasurement) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.straighten, color: Colors.amber, size: 11),
                    SizedBox(width: 4),
                    Text(
                      'Measurement Required',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChips() {
    final chips = [
      '+ 12 rows',
      '+ 16 seats/row',
      '+ 3 blocks',
      '+ Aisles after 4 & 12',
      '+ Request measurement',
      '+ Undo',
    ];

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFF0E0E14),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final label = chips[index];
          return ActionChip(
            label: Text(
              label,
              style: const TextStyle(color: _gold, fontSize: 10.5),
            ),
            backgroundColor: const Color(0xFF1B1B22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _gold.withValues(alpha: 0.3), width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              final raw = label.replaceFirst('+ ', '');
              if (raw == 'Undo') {
                _sendMessage('undo that');
              } else if (raw == '12 rows') {
                _sendMessage('There are 12 rows.');
              } else if (raw == '16 seats/row') {
                _sendMessage('There are 16 seats in each row.');
              } else if (raw == '3 blocks') {
                _sendMessage('There are 3 seating blocks.');
              } else if (raw == 'Aisles after 4 & 12') {
                _sendMessage('Put an aisle after seat 4 and after seat 12.');
              } else if (raw == 'Request measurement') {
                _sendMessage('Request measurement');
              } else {
                _sendMessage(raw);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: const Color(0xFF121217),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('floating_venue_assistant_input'),
              controller: _inputController,
              style: const TextStyle(color: _offWhite, fontSize: 12.5),
              cursorColor: _gold,
              decoration: InputDecoration(
                hintText: 'Type a venue instruction...',
                hintStyle: const TextStyle(color: _mutedGrey, fontSize: 12),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFF1E1E26),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: _gold.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: _gold.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: _gold, width: 1.2),
                ),
              ),
              onSubmitted: (val) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _burgundy.withValues(alpha: 0.4),
              border: Border.all(color: _gold.withValues(alpha: 0.5)),
            ),
            child: IconButton(
              key: const Key('floating_venue_assistant_send'),
              icon: _processing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _gold,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: _gold, size: 16),
              onPressed: _processing ? null : () => _sendMessage(),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            ),
          ),
        ],
      ),
    );
  }
}
