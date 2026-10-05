import 'package:flutter/material.dart';
import '../admin/models/theatre_configuration.dart';
import '../admin/models/seat_config.dart';
import '../admin/models/movie_content.dart';
import '../admin/services/movie_repository.dart';
import '../shared/models/show_model.dart';
import '../shared/services/show_repository.dart';
import '../shared/services/booking_repository.dart';
import 'unity_experience_screen.dart';

/// Minimal persistent booking confirmation screen for database-backed theatres.
/// Styled with LiveScreen's premium cinematic theatre palette:
/// Black (#000000), Near Black (#080808), Charcoal (#151515),
/// Deep Burgundy (#700914), Warm Gold (#D4A84F), and Cream (#F2F0EA).
class TheatreBookingConfirmScreen extends StatefulWidget {
  final TheatreConfiguration theatre;
  final String? showId;
  final SeatConfig seat;

  const TheatreBookingConfirmScreen({
    super.key,
    required this.theatre,
    required this.seat,
    this.showId,
  });

  @override
  State<TheatreBookingConfirmScreen> createState() =>
      _TheatreBookingConfirmScreenState();
}

class _TheatreBookingConfirmScreenState
    extends State<TheatreBookingConfirmScreen> {
  bool _submitting = false;
  bool _confirmed = false;
  String? _error;

  ShowModel? _show;
  MovieContent? _movie;
  bool _loadingShow = false;

  @override
  void initState() {
    super.initState();
    _loadShowDetails();
  }

  Future<void> _loadShowDetails() async {
    final showId = widget.showId;
    if (showId == null) return;
    setState(() => _loadingShow = true);
    try {
      final show = await showRepository.getShowById(showId);
      MovieContent? movie;
      if (show?.movieId != null) {
        movie = await movieRepository.getMovieById(show!.movieId!);
      }
      if (!mounted) return;
      setState(() {
        _show = show;
        _movie = movie;
        _loadingShow = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingShow = false);
    }
  }

  String? get _movieTitle => _movie?.title ?? widget.theatre.content?.title;

  Future<void> _confirm() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await bookingRepository.createBooking(
        theatreId: widget.theatre.id,
        showId: widget.showId,
        seatId: widget.seat.id,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _confirmed = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        title: const Text(
          'Confirm Booking',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontFamilyFallback: ['serif'],
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF2F0EA),
          ),
        ),
        backgroundColor: const Color(0xFF0C0C0C),
        foregroundColor: const Color(0xFFF2F0EA),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF262626), height: 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _confirmed ? _buildSuccess(context) : _buildConfirm(),
      ),
    );
  }

  Widget _buildConfirm() {
    final movieTitle = _movieTitle;
    final price = _show?.price;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E0E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xD9B8893C),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 24,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.theatre.basicInfo.name,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontFamilyFallback: ['serif'],
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                      color: Color(0xFFF2F0EA),
                    ),
                  ),
                  const Icon(
                    Icons.confirmation_num_outlined,
                    color: Color(0xFFD4A84F),
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFF262626), height: 1),
              const SizedBox(height: 14),
              if (_loadingShow) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFD4A84F),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (movieTitle != null && movieTitle.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Movie',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
                    ),
                    Text(
                      movieTitle,
                      style: const TextStyle(
                        color: Color(0xFFF2F0EA),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              if (_show != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Showtime',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
                    ),
                    Text(
                      TimeOfDay.fromDateTime(_show!.startTime.toLocal()).format(context),
                      style: const TextStyle(
                        color: Color(0xFFD4A84F),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reserved Seat',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x33D4A84F),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD4A84F), width: 0.8),
                    ),
                    child: Text(
                      'Seat ${widget.seat.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD4A84F),
                      ),
                    ),
                  ),
                ],
              ),
              if (price != null) ...[
                const SizedBox(height: 14),
                const Divider(color: Color(0xFF262626), height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Price',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    ),
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD4A84F),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x60440101),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC7080C)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFF2F0EA), fontSize: 13),
            ),
          ),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _submitting ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF700914), // deep burgundy
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Confirm Booking'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xD9B8893C),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 28,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0x26D4A84F),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4A84F), width: 1.5),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFD4A84F),
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Booking Confirmed',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontFamilyFallback: ['serif'],
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF2F0EA),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seat ${widget.seat.id} at ${widget.theatre.basicInfo.name}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UnityExperienceScreen(
                    seatLabel: widget.seat.id,
                    theatre: widget.theatre,
                    movie: _movie,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.view_in_ar_rounded,
                size: 18,
                color: Color(0xFFD4A84F),
              ),
              label: const Text('Experience This Seat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD4A84F),
                backgroundColor: const Color(0x1AD4A84F),
                side: const BorderSide(color: Color(0xFFD4A84F), width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF700914), // deep burgundy
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
