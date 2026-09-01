using System;

/// <summary>
/// Describes one active "sitting in a seat" session. Kept intentionally
/// simple for Phase 3 — this is the hook Phase 4+ will extend with
/// analytics (time spent per seat, seats compared, etc).
/// </summary>
public class ExperienceSession
{
    public string VenueId;
    public string AuditoriumId;
    public string SeatId;
    public UnityEngine.Vector3 SeatPosition;
    public UnityEngine.Quaternion SeatRotation;
    public DateTime StartTime;

    public ExperienceSession(SeatData seat, string venueId = "demo_venue", string auditoriumId = "demo_auditorium")
    {
        VenueId = venueId;
        AuditoriumId = auditoriumId;
        SeatId = seat.Id;
        SeatPosition = seat.Position;
        SeatRotation = seat.Rotation;
        StartTime = DateTime.UtcNow;
    }
}
