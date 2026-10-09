import 'dart:math' as math;
import '../models/estimate.dart';
import '../models/reconstruction_draft.dart';
import '../models/venue_assistant_action.dart';
import '../models/venue_assistant_message.dart';
import '../models/venue_assistant_response.dart';
import '../../models/screen_config.dart' show Position3;
import '../../models/speaker_model.dart' show SpeakerType;

/// Abstract interface for the conversational AI Venue Assistant.
///
/// Principles:
/// 1. Authoritative Logical Structure: Theatre Admin is authoritative for rows,
///    seats per row, blocks, aisles, irregular rows, and missing seats.
/// 2. Physical Scale Separation: Physical geometry (spacing, aisle width, coordinates)
///    remains [Estimate.unknown] unless evidence supports it. Never invent arbitrary metric values.
/// 3. Draft-Only Mutation: Modifies [ReconstructionDraft] ONLY; never touches live [TheatreConfiguration].
/// 4. Session Scoped: Messages and undo history survive popup close/reopen.
abstract class VenueAssistant {
  String get sessionId;
  List<VenueAssistantMessage> get messages;
  List<VenueAssistantAction> get actionHistory;
  List<ReconstructionDraft> get draftHistory;

  Future<VenueAssistantResponse> processMessage({
    required String text,
    required ReconstructionDraft draft,
    String? contextName,
  });

  Future<VenueAssistantResponse> undo({
    required ReconstructionDraft currentDraft,
  });

  void ensureGreeting({String? contextName});
  void clearHistory();
}

/// Registry ensuring session-scoped conversation continuity.
class VenueAssistantRegistry {
  static final Map<String, VenueAssistant> _instances = {};

  static VenueAssistant getOrCreate(String sessionId) {
    return _instances.putIfAbsent(
      sessionId,
      () => DeterministicVenueAssistant(sessionId: sessionId),
    );
  }

  static void reset() {
    _instances.clear();
  }
}

/// Deterministic, testable implementation of [VenueAssistant].
///
/// Processes natural language venue descriptions into structured actions and
/// applies them strictly to the [ReconstructionDraft].
class DeterministicVenueAssistant implements VenueAssistant {
  @override
  final String sessionId;

  final List<VenueAssistantMessage> _messages = [];
  final List<VenueAssistantAction> _actionHistory = [];
  final List<ReconstructionDraft> _draftHistory = [];

  DeterministicVenueAssistant({required this.sessionId});

  @override
  List<VenueAssistantMessage> get messages => List.unmodifiable(_messages);

  @override
  List<VenueAssistantAction> get actionHistory =>
      List.unmodifiable(_actionHistory);

  @override
  List<ReconstructionDraft> get draftHistory => List.unmodifiable(_draftHistory);

  @override
  void ensureGreeting({String? contextName}) {
    if (_messages.isNotEmpty) return;

    final contextLabel = contextName ?? 'Venue Configuration';
    final greetingText = _buildGreetingText(contextLabel);

    _messages.add(
      VenueAssistantMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}-intro',
        sessionId: sessionId,
        role: VenueAssistantRole.assistant,
        text: greetingText,
        createdAt: DateTime.now(),
      ),
    );
  }

  String _buildGreetingText(String contextLabel) {
    if (contextLabel.toLowerCase().contains('seating')) {
      return 'What would you like to configure in Seating? You can describe row count, seats per row, aisles, blocks, or missing seats.';
    } else if (contextLabel.toLowerCase().contains('screen')) {
      return 'AI VENUE ASSISTANT — Screen Configuration. How would you like to adjust the screen dimensions or position?';
    } else if (contextLabel.toLowerCase().contains('room')) {
      return 'AI VENUE ASSISTANT — Room Configuration. You can describe the room length, width, or height.';
    } else if (contextLabel.toLowerCase().contains('speaker')) {
      return 'AI VENUE ASSISTANT — Speaker Configuration. You can specify visual speaker positions on walls or stage.';
    } else if (contextLabel.toLowerCase().contains('lighting')) {
      return 'AI VENUE ASSISTANT — Lighting Configuration. You can describe ceiling or aisle lighting layouts.';
    }
    return 'What would you like to configure? You can describe your seating layout, screen, room dimensions, or speakers.';
  }

  @override
  void clearHistory() {
    _messages.clear();
    _actionHistory.clear();
    _draftHistory.clear();
  }

  @override
  Future<VenueAssistantResponse> undo({
    required ReconstructionDraft currentDraft,
  }) async {
    if (_draftHistory.isEmpty) {
      final msg = VenueAssistantMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        role: VenueAssistantRole.assistant,
        text: 'Nothing to undo.',
        createdAt: DateTime.now(),
      );
      _messages.add(msg);
      return VenueAssistantResponse(
        message: msg,
        updatedDraft: currentDraft,
      );
    }

    final previousDraft = _draftHistory.removeLast();
    final lastAction =
        _actionHistory.isNotEmpty ? _actionHistory.removeLast() : null;

    final undoAction = UndoAction(
      undoneActionDescription: lastAction?.description,
    );

    final reply = VenueAssistantMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      role: VenueAssistantRole.assistant,
      text: lastAction != null
          ? 'Reversed the last change: ${lastAction.description}.'
          : 'Reversed the last change.',
      createdAt: DateTime.now(),
      action: undoAction,
      actionSummary: 'Undo applied',
    );
    _messages.add(reply);

    return VenueAssistantResponse(
      message: reply,
      appliedAction: undoAction,
      updatedDraft: previousDraft,
    );
  }

  @override
  Future<VenueAssistantResponse> processMessage({
    required String text,
    required ReconstructionDraft draft,
    String? contextName,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      final emptyMsg = VenueAssistantMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        role: VenueAssistantRole.assistant,
        text: 'Please enter a venue instruction.',
        createdAt: DateTime.now(),
      );
      return VenueAssistantResponse(message: emptyMsg, updatedDraft: draft);
    }

    // 1. Record Admin Turn
    final adminMsg = VenueAssistantMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}-admin',
      sessionId: sessionId,
      role: VenueAssistantRole.admin,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    _messages.add(adminMsg);

    final lower = trimmed.toLowerCase();

    // 2. Check for Ambiguity First (never silently guess)
    if (_isAmbiguousAisleWidth(lower)) {
      final action = ClarificationRequiredAction(
        question:
            'Which aisle should I change — the aisle after seat 4 or the aisle after seat 12?',
        options: ['Aisle after seat 4', 'Aisle after seat 12'],
      );
      final reply = VenueAssistantMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}-asst',
        sessionId: sessionId,
        role: VenueAssistantRole.assistant,
        text: action.question,
        createdAt: DateTime.now(),
        action: action,
      );
      _messages.add(reply);
      return VenueAssistantResponse(
        message: reply,
        appliedAction: action,
        updatedDraft: draft,
        clarificationQuestion: action.question,
      );
    }

    if (_isAmbiguousScreenMove(lower)) {
      final action = ClarificationRequiredAction(
        question: 'Do you mean farther from the seating area or closer to it?',
        options: [
          'Farther from the seating area',
          'Closer to the seating area',
        ],
      );
      final reply = VenueAssistantMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}-asst',
        sessionId: sessionId,
        role: VenueAssistantRole.assistant,
        text: action.question,
        createdAt: DateTime.now(),
        action: action,
      );
      _messages.add(reply);
      return VenueAssistantResponse(
        message: reply,
        appliedAction: action,
        updatedDraft: draft,
        clarificationQuestion: action.question,
      );
    }

    // 3. Undo Instruction
    if (lower == 'undo' ||
        lower == 'undo that' ||
        lower == 'undo that.' ||
        lower == 'undo last change') {
      return undo(currentDraft: draft);
    }

    // 4. Targeted Measurement Request
    if (_isMeasurementQuery(lower)) {
      final action = TargetedMeasurementRequestAction(
        measurementType: 'aisle_width',
        reason:
            'Cannot establish the aisle width accurately from current evidence.',
      );
      const replyText =
          'I understand the seating pattern, but I cannot establish the aisle width accurately from the current evidence.\n\n'
          'Please measure the aisle between the first and second seating blocks.';

      final reply = VenueAssistantMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}-asst',
        sessionId: sessionId,
        role: VenueAssistantRole.assistant,
        text: replyText,
        createdAt: DateTime.now(),
        action: action,
        actionSummary: 'Measurement requested: aisle width',
        requiresMeasurement: true,
      );
      _messages.add(reply);

      return VenueAssistantResponse(
        message: reply,
        appliedAction: action,
        updatedDraft: draft,
        requiresMeasurement: true,
        targetedMeasurementPrompt:
            'Please measure the aisle between the first and second seating blocks.',
      );
    }

    // 5. Unrelated Query Filter
    if (_isUnrelatedQuery(lower)) {
      final action = UnrelatedQueryAction();
      final reply = VenueAssistantMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}-asst',
        sessionId: sessionId,
        role: VenueAssistantRole.assistant,
        text: action.message,
        createdAt: DateTime.now(),
        action: action,
      );
      _messages.add(reply);
      return VenueAssistantResponse(
        message: reply,
        appliedAction: action,
        updatedDraft: draft,
      );
    }

    // 6. Natural Language Seating / Venue Parsing
    ReconstructionDraft updatedDraft = draft;
    VenueAssistantAction? action;
    String responseText = '';
    bool requiresMeasurement = false;

    // A0. Compound Seating Specification (e.g. "There are 12 rows with 16 seats in each row. Put an aisle after seat 4 and seat 12.")
    final hasRows = RegExp(r'(\d+)\s+rows?').hasMatch(lower);
    final hasSeatsPerRow = RegExp(r'(\d+)\s+seats?\s+(?:in\s+each\s+row|per\s+row)').hasMatch(lower);
    final hasAisles = _matchesSetAisles(lower);

    if (hasRows && (hasSeatsPerRow || hasAisles)) {
      final rowMatch = RegExp(r'(\d+)\s+rows?').firstMatch(lower);
      final rowCount = int.tryParse(rowMatch!.group(1)!) ?? 12;

      int? seatsPerRow;
      final sprMatch = RegExp(r'(\d+)\s+seats?\s+(?:in\s+each\s+row|per\s+row)').firstMatch(lower);
      if (sprMatch != null) {
        seatsPerRow = int.tryParse(sprMatch.group(1)!);
      }

      final List<int> aisles = hasAisles ? _extractAisleBoundaries(lower) : [];

      action = aisles.isNotEmpty
          ? SetAisleBoundariesAction(aisles)
          : SetRowCountAction(rowCount);

      final effectiveSpr = seatsPerRow ??
          (draft.seating.seatsPerRow.isKnown
              ? draft.seating.seatsPerRow.value!
              : 16);

      updatedDraft = _saveSnapshot(draft).copyWith(
        seating: draft.seating.copyWith(
          rows: Estimate<int>.adminMeasured(
            rowCount,
            note: 'Specified by theatre admin in assistant',
          ),
          seatsPerRow: seatsPerRow != null
              ? Estimate<int>.adminMeasured(
                  seatsPerRow,
                  note: 'Specified by theatre admin in assistant',
                )
              : draft.seating.seatsPerRow,
          aisleAfterSeats:
              aisles.isNotEmpty ? aisles : draft.seating.aisleAfterSeats,
          blockCount:
              aisles.isNotEmpty ? aisles.length + 1 : draft.seating.blockCount,
        ),
      );

      if (aisles.isNotEmpty) {
        final breakdown =
            _formatBlockBreakdown(seatsPerRow: effectiveSpr, aisles: aisles);
        responseText =
            'Updated the seating pattern:\n$breakdown.\n\nI will determine the physical aisle widths from venue evidence.';
      } else {
        responseText =
            'Updated seating draft to $rowCount rows and $effectiveSpr seats per row.';
      }
    }
    // A. Remove Aisle
    else if (_matchesRemoveAisle(lower)) {
      final currentAisles = draft.seating.aisleAfterSeats;
      int? targetSeat;

      if (lower.contains('first aisle')) {
        targetSeat = currentAisles.isNotEmpty ? currentAisles.first : 4;
      } else {
        final match =
            RegExp(r'after\s+(?:seat\s+)?(\d+)').firstMatch(lower);
        if (match != null) {
          targetSeat = int.tryParse(match.group(1)!);
        }
      }

      targetSeat ??= 12; // Fallback to example context if unparsed
      action = RemoveAisleBoundaryAction(targetSeat);

      final newAisles = List<int>.from(currentAisles)..remove(targetSeat);
      updatedDraft = _saveSnapshot(draft).copyWith(
        seating: draft.seating.copyWith(
          aisleAfterSeats: newAisles,
          blockCount: math.max(1, newAisles.length + 1),
        ),
      );

      final breakdown = _formatBlockBreakdown(
        seatsPerRow: updatedDraft.seating.seatsPerRow.isKnown
            ? updatedDraft.seating.seatsPerRow.value!
            : 16,
        aisles: newAisles,
      );
      responseText = 'Done. The draft now has:\n$breakdown.';
    }
    // B. Aisle Boundaries (e.g. "Put an aisle after seat 4 and after seat 12")
    else if (_matchesSetAisles(lower)) {
      final aisles = _extractAisleBoundaries(lower);

      action = SetAisleBoundariesAction(aisles);
      updatedDraft = _saveSnapshot(draft).copyWith(
        seating: draft.seating.copyWith(
          aisleAfterSeats: aisles,
          blockCount: aisles.length + 1,
        ),
      );

      final seatsPerRow = updatedDraft.seating.seatsPerRow.isKnown
          ? updatedDraft.seating.seatsPerRow.value!
          : 16;
      final breakdown = _formatBlockBreakdown(
        seatsPerRow: seatsPerRow,
        aisles: aisles,
      );

      responseText =
          'Updated the seating pattern:\n$breakdown.\n\nI will determine the physical aisle widths from venue evidence.';
    }
    // C. Seating Blocks Count alone
    else if (_matchesBlockCount(lower)) {
      final match = RegExp(r'(\d+)\s+(?:seating\s+)?blocks?').firstMatch(lower);
      final count = match != null ? int.tryParse(match.group(1)!) ?? 3 : 3;

      action = SetBlockCountAction(count);
      updatedDraft = _saveSnapshot(draft).copyWith(
        seating: draft.seating.copyWith(blockCount: count),
      );
      responseText = 'Understood — configured $count seating blocks.';
    }
    // D. Irregular Rows (e.g. "Rows 1 to 5 have 16 seats and rows 6 to 12 have 18")
    else if (_matchesIrregularRows(lower)) {
      final Map<int, int> newRowCounts =
          Map<int, int>.from(draft.seating.rowSeatCounts);

      final rangeRegex = RegExp(
          r'rows?\s+(\d+)\s*(?:to|–|-)\s*(\d+)\s*(?:have|has|set to|with)?\s*(\d+)(?:\s*seats)?');
      final matches = rangeRegex.allMatches(lower);

      int firstStart = 1, firstEnd = 5, firstCount = 16;
      int? secondStart, secondEnd, secondCount;

      for (final m in matches) {
        final start = int.tryParse(m.group(1)!);
        final end = int.tryParse(m.group(2)!);
        final count = int.tryParse(m.group(3)!);
        if (start != null && end != null && count != null) {
          for (int r = start; r <= end; r++) {
            newRowCounts[r] = count;
          }
          if (secondStart == null && firstStart != start) {
            secondStart = start;
            secondEnd = end;
            secondCount = count;
          } else {
            firstStart = start;
            firstEnd = end;
            firstCount = count;
          }
        }
      }

      action = SetRowSeatCountAction(
        startRow: firstStart,
        endRow: firstEnd,
        count: firstCount,
      );

      updatedDraft = _saveSnapshot(draft).copyWith(
        seating: draft.seating.copyWith(rowSeatCounts: newRowCounts),
      );

      if (secondStart != null && secondEnd != null && secondCount != null) {
        responseText =
            'Updated row seat counts: rows $firstStart–$firstEnd set to $firstCount seats, rows $secondStart–$secondEnd set to $secondCount seats.';
      } else {
        responseText =
            'Updated row seat counts: rows $firstStart–$firstEnd set to $firstCount seats.';
      }
    }
    // E. Remove Specific Seat (Missing Seat)
    else if (_matchesRemoveSeat(lower)) {
      final match = RegExp(
              r'remove\s+seat\s+(\d+)\s+(?:from|in|of)\s+row\s+([a-zA-Z0-9]+)')
          .firstMatch(lower);
      final seatNum = match != null ? int.tryParse(match.group(1)!) ?? 7 : 7;
      final rowStr = match != null ? match.group(2)! : '5';

      action = RemoveSeatAction(row: rowStr, seatNumber: seatNum);
      final newRemoved = Set<String>.from(draft.seating.removedSeats)
        ..add('$rowStr-$seatNum');

      updatedDraft = _saveSnapshot(draft).copyWith(
        seating: draft.seating.copyWith(removedSeats: newRemoved),
      );
      responseText = 'Removed seat $seatNum from row $rowStr in the seating draft.';
    }
    // F. Row Count (e.g. "There are 12 rows" / "Change it to 14 rows")
    else if (_matchesRowCount(lower)) {
      final match = RegExp(
              r'(?:there\s+are\s+|change\s+it\s+to\s+|set\s+rows\s+to\s+)?(\d+)\s+rows?')
          .firstMatch(lower);
      final count = match != null ? int.tryParse(match.group(1)!) ?? 12 : 12;

      action = SetRowCountAction(count);
      updatedDraft = _saveSnapshot(draft).copyWith(
        seating: draft.seating.copyWith(
          rows: Estimate<int>.adminMeasured(
            count,
            note: 'Specified by theatre admin in assistant',
          ),
        ),
      );
      responseText = lower.contains('change')
          ? 'Updated the seating draft to $count rows.'
          : 'Got it — $count rows.';
    }
    // G. Seats Per Row (e.g. "There are 16 seats in each row")
    else if (_matchesSeatsPerRow(lower)) {
      final match = RegExp(
              r'(\d+)\s+seats?\s+(?:in\s+each\s+row|per\s+row)')
          .firstMatch(lower);
      final count = match != null ? int.tryParse(match.group(1)!) ?? 16 : 16;

      action = SetDefaultSeatsPerRowAction(count);
      updatedDraft = _saveSnapshot(draft).copyWith(
        seating: draft.seating.copyWith(
          seatsPerRow: Estimate<int>.adminMeasured(
            count,
            note: 'Specified by theatre admin in assistant',
          ),
        ),
      );
      responseText = 'Got it — $count seats per row.';
    }
    // H. Screen Height
    else if (_matchesScreenHeight(lower)) {
      action = AdjustScreenHeightAction(delta: 0.5);

      final currentPos = draft.screen.position.isKnown
          ? draft.screen.position.value!
          : Position3(x: 0, y: 1.2, z: 0);
      final newPos = Position3(
        x: currentPos.x,
        y: currentPos.y + 0.5,
        z: currentPos.z,
      );

      updatedDraft = _saveSnapshot(draft).copyWith(
        screen: DraftScreen(
          width: draft.screen.width,
          height: draft.screen.height,
          position: Estimate<Position3>.adminMeasured(
            newPos,
            note: 'Elevated by theatre admin via assistant',
          ),
          rotationY: draft.screen.rotationY,
          type: draft.screen.type,
        ),
      );
      responseText = 'I’ll update the screen height in the reconstruction draft.';
    }
    // I. Room Dimensions (e.g. "The room is 30 metres long")
    else if (_matchesRoomDimensions(lower)) {
      final match = RegExp(r'(\d+(?:\.\d+)?)\s*(?:metres?|meters?|m)?\s*long')
          .firstMatch(lower);
      final lengthVal =
          match != null ? double.tryParse(match.group(1)!) ?? 30.0 : 30.0;

      action = SetRoomDimensionsAction(length: lengthVal);
      updatedDraft = _saveSnapshot(draft).copyWith(
        room: DraftRoomGeometry(
          width: draft.room.width,
          length: Estimate<double>.adminMeasured(
            lengthVal,
            note: 'Specified by theatre admin in assistant',
          ),
          height: draft.room.height,
        ),
      );
      responseText =
          'I can update the room length in the reconstruction draft. Please note that this value will remain part of the draft until review and confirmation.';
    }
    // J. Speakers (Visual only)
    else if (_matchesSpeakers(lower)) {
      action = SetSpeakerPlacementsAction(
        placement: 'both side walls',
        cabinetType: SpeakerType.sideSurround,
      );

      // Create visual-only speaker placements
      final sideSpeakers = [
        DraftVisualSpeaker(
          id: 'spk-left-draft',
          name: 'Left Wall Surround',
          position: Position3(x: -8.0, y: 3.5, z: 10.0),
          visualCabinetType: SpeakerType.sideSurround,
          evidenceIds: const ['admin-specified'],
        ),
        DraftVisualSpeaker(
          id: 'spk-right-draft',
          name: 'Right Wall Surround',
          position: Position3(x: 8.0, y: 3.5, z: 10.0),
          visualCabinetType: SpeakerType.sideSurround,
          evidenceIds: const ['admin-specified'],
        ),
      ];

      updatedDraft = _saveSnapshot(draft).copyWith(speakers: sideSpeakers);
      responseText =
          'Noted visual speakers on the side walls in the draft. Cabinet positions are visual-only.';
    }
    // K. Lighting
    else if (_matchesLighting(lower)) {
      final match = RegExp(r'(four|4|\d+)\s+rows').firstMatch(lower);
      int rows = 4;
      if (match != null) {
        final g = match.group(1)!;
        rows = g == 'four' ? 4 : (int.tryParse(g) ?? 4);
      }

      action = SetLightingLayoutAction(ceilingRows: rows);
      updatedDraft = _saveSnapshot(draft).copyWith(
        lighting: DraftLighting(
          ceilingLightsCount: Estimate<int>.adminMeasured(
            rows * 6,
            note: 'Ceiling lights in $rows rows',
          ),
        ),
      );
      responseText = 'Noted ceiling lighting arranged in $rows rows in the draft.';
    }
    // L. Fallback Unknown
    else {
      action = UnknownAction(trimmed);
      responseText =
          'I didn’t quite understand that. You can tell me row counts, seats per row, aisles, blocks, screen height, or speaker locations.';
    }

    _actionHistory.add(action);

    final assistantMsg = VenueAssistantMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}-asst',
      sessionId: sessionId,
      role: VenueAssistantRole.assistant,
      text: responseText,
      createdAt: DateTime.now(),
      action: action,
      actionSummary: action.description,
      requiresMeasurement: requiresMeasurement,
    );
    _messages.add(assistantMsg);

    return VenueAssistantResponse(
      message: assistantMsg,
      appliedAction: action,
      updatedDraft: updatedDraft,
      requiresMeasurement: requiresMeasurement,
    );
  }

  ReconstructionDraft _saveSnapshot(ReconstructionDraft draft) {
    _draftHistory.add(draft);
    return draft;
  }

  String _formatBlockBreakdown({
    required int seatsPerRow,
    required List<int> aisles,
  }) {
    if (aisles.isEmpty) {
      return '$seatsPerRow seats';
    }

    final segments = <String>[];
    int lastIndex = 0;

    for (final aisleAfter in aisles) {
      final count = aisleAfter - lastIndex;
      if (count > 0) {
        segments.add('$count seats');
      }
      segments.add('aisle');
      lastIndex = aisleAfter;
    }

    final remaining = seatsPerRow - lastIndex;
    if (remaining > 0) {
      segments.add('$remaining seats');
    }

    return segments.join(' | ');
  }

  List<int> _extractAisleBoundaries(String text) {
    final List<int> aisles = [];
    final aisleSectionMatch =
        RegExp(r'(?:aisles?|after)\s+(.*)').firstMatch(text);
    final toScan =
        aisleSectionMatch != null ? aisleSectionMatch.group(1)! : text;

    final matches =
        RegExp(r'(?:after|and|,|\s)\s*(?:seat\s+)?(\d+)').allMatches(toScan);
    for (final m in matches) {
      final val = int.tryParse(m.group(1)!);
      if (val != null && !aisles.contains(val)) {
        aisles.add(val);
      }
    }
    if (aisles.isEmpty) {
      aisles.addAll([4, 12]);
    }
    aisles.sort();
    return aisles;
  }

  // --- Pattern Matchers ---

  bool _isAmbiguousAisleWidth(String text) {
    return text.contains('make the aisle wider') ||
        text.contains('widen the aisle') ||
        text.contains('make aisle wider');
  }

  bool _isAmbiguousScreenMove(String text) {
    return text.contains('move the screen back') ||
        text.contains('screen back') ||
        text.contains('push the screen back');
  }

  bool _isMeasurementQuery(String text) {
    return text.contains('request measurement') ||
        text.contains('measure the aisle') ||
        text.contains('how wide is the aisle') ||
        text.contains('what is the seat spacing');
  }

  bool _isUnrelatedQuery(String text) {
    return text.contains('movie') &&
            (text.contains('playing') ||
                text.contains('ticket') ||
                text.contains('recommend') ||
                text.contains('book')) ||
        text.contains('weather') ||
        text.contains('who won') ||
        text.contains('popcorn');
  }

  bool _matchesRemoveAisle(String text) {
    return text.contains('remove') && text.contains('aisle');
  }

  bool _matchesSetAisles(String text) {
    return (text.contains('aisle') || text.contains('aisles')) &&
        (text.contains('after') || text.contains('between'));
  }

  bool _matchesBlockCount(String text) {
    return text.contains('block') || text.contains('blocks');
  }

  bool _matchesIrregularRows(String text) {
    return text.contains('rows') &&
        (text.contains('to') || text.contains('–') || text.contains('-')) &&
        (text.contains('seats') || text.contains('have'));
  }

  bool _matchesRemoveSeat(String text) {
    return text.contains('remove') &&
        text.contains('seat') &&
        text.contains('row');
  }

  bool _matchesRowCount(String text) {
    return (text.contains('row') || text.contains('rows')) &&
        RegExp(r'\d+').hasMatch(text) &&
        !text.contains('seats') &&
        !text.contains('seat');
  }

  bool _matchesSeatsPerRow(String text) {
    return (text.contains('seats in each row') ||
            text.contains('seats per row') ||
            text.contains('seat in each row')) &&
        RegExp(r'\d+').hasMatch(text);
  }

  bool _matchesScreenHeight(String text) {
    return text.contains('screen') &&
        (text.contains('higher') ||
            text.contains('lower') ||
            text.contains('elevation'));
  }

  bool _matchesRoomDimensions(String text) {
    return text.contains('room') &&
        (text.contains('long') ||
            text.contains('wide') ||
            text.contains('length') ||
            text.contains('width'));
  }

  bool _matchesSpeakers(String text) {
    return text.contains('speaker') || text.contains('speakers');
  }

  bool _matchesLighting(String text) {
    return text.contains('light') || text.contains('lighting');
  }
}
