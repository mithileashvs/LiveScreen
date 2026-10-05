using System;
using UnityEngine;

/// <summary>
/// The Unity-side mirror of the ONE canonical theatre payload Flutter
/// sends (see theatre_unity_bridge.dart's toUnityPayload — every field
/// name here must spell exactly the same, because JsonUtility matches by
/// field name, not by attribute).
///
/// This is deliberately a plain DTO, separate from <see cref="VenueParameters"/>:
/// VenueParameters is the scene's own tuning surface (lighting, headroom,
/// eye heights, safety margins) and keeps its inspector defaults;
/// this is what a specific theatre's OWNER saved. LoadConfiguration copies
/// the owner's values onto the scene's parameters and leaves the rest
/// alone, so a theatre never has to re-specify lighting to get a room.
/// </summary>
[Serializable]
public class TheatreConfigPayload
{
    public int payloadVersion;
    public string theatreId;
    public string theatreName;

    /// <summary>
    /// False only for a brand-new theatre whose owner has not configured
    /// anything yet. When false, the scene's own defaults are legitimately
    /// the defaults for a new theatre. When true, those defaults must
    /// never be substituted for anything the owner saved.
    /// </summary>
    public bool hasSavedConfiguration;

    // Room
    public float roomWidth;
    public float roomLength;
    public float roomHeight;

    // Screen
    public float screenWidth;
    public float screenHeight;
    public float screenOffsetX;
    public float screenCenterY;
    public float screenDistanceFromFrontWall;
    public float screenRotationY;
    public string screenType;

    // Seating generator parameters
    public int rows;
    public int seatsPerRow;
    public float seatSpacing;
    public float rowSpacing;
    public float seatWidth;
    public float seatDepth;
    public float seatHeight;
    public float firstRowDistanceFromScreen;
    public float rowRisePerRow;
    public float seatingOriginX;
    public float seatingBaseY;

    public SeatPlacement[] seats;
    public SpeakerPlacement[] speakers;
    public AcousticsPayload acoustics;
}

/// <summary>
/// The Unity-side mirror of TheatreUnityBridge.toUnityTrailerPayload.
/// [kind] is the SAME classification trailer_url.dart's TrailerKind enum
/// already computes on the Flutter side ("directFile" | "youtube" |
/// "vimeo" | "missing" | "unsupported") — Unity does not re-guess what a
/// saved trailer value is, it just receives the answer.
/// </summary>
[Serializable]
public class TrailerPayload
{
    public string kind;
    public string url;
}

/// <summary>One saved seat, with the SAME stable ID the web seat map and the
/// booking system use. Unity places exactly these rather than re-deriving a
/// grid, so a seat selected in Unity is unambiguously the same seat row that
/// gets booked.</summary>
[Serializable]
public class SeatPlacement
{
    public string id;
    public string row;
    public int number;
    public float x;
    public float y;
    public float z;
    public float rotationY;
    public string category; // standard | premium | recliner

    public Vector3 Position => new Vector3(x, y, z);
    public Quaternion Rotation => Quaternion.Euler(0f, 180f + rotationY, 0f);

    public SeatType ToSeatType()
    {
        switch (category)
        {
            case "premium": return SeatType.Premium;
            case "recliner": return SeatType.Recliner;
            default: return SeatType.Standard;
        }
    }
}

/// <summary>One saved speaker. Position is in the same room-local coordinate
/// space as seats (X = left/right, Y = up, Z = distance from the front wall).</summary>
[Serializable]
public class SpeakerPlacement
{
    public string id;
    public string name;
    public string type;
    public string channel; // left|center|right|leftSurround|rightSurround|lfe|overhead
    public float x;
    public float y;
    public float z;
    public float rotationY;
    public float ratedPowerWatts;
    public float frequencyRangeLowHz;
    public float frequencyRangeHighHz;
    public float sensitivityDb;

    public Vector3 Position => new Vector3(x, y, z);

    public SpeakerChannel ToChannel()
    {
        switch (channel)
        {
            case "center": return SpeakerChannel.Center;
            case "right": return SpeakerChannel.Right;
            case "leftSurround": return SpeakerChannel.LeftSurround;
            case "rightSurround": return SpeakerChannel.RightSurround;
            case "lfe": return SpeakerChannel.Lfe;
            case "overhead": return SpeakerChannel.Overhead;
            default: return SpeakerChannel.Left;
        }
    }
}

/// <summary>
/// The theatre's configured surface absorption, reaching the existing
/// spatial-audio system instead of being discarded. This is NOT an accurate
/// acoustic simulation and is not presented as one — it maps configured
/// absorption onto Unity's reverb/rolloff controls so a heavily treated room
/// audibly differs from a bare one.
/// </summary>
[Serializable]
public class AcousticsPayload
{
    public float floorAbsorption;
    public float wallAbsorption;
    public float ceilingAbsorption;
    public int panelCount;
    public float panelCoverageSqm;
    public bool curtainEnabled;

    /// <summary>0 = fully reflective room, 1 = fully absorptive.</summary>
    public float AverageAbsorption =>
        Mathf.Clamp01((floorAbsorption + wallAbsorption + ceilingAbsorption) / 3f);
}
