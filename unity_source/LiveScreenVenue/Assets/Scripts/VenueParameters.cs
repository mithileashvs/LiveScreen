using System;
using UnityEngine;

/// <summary>
/// How the seating rows are arranged.
/// Straight = simple flat rows.
/// Curved = rows bow outward slightly, like a real cinema.
/// </summary>
public enum SeatArrangement
{
    Straight,
    Curved
}

/// <summary>
/// The three seat types Phase 2 supports.
/// </summary>
public enum SeatType
{
    Standard,
    Premium,
    Recliner
}

/// <summary>
/// Every number a venue owner would enter to describe their cinema.
/// This single object is what the whole generation system is built from —
/// nothing about the 3D venue is hard-coded, it all comes from here.
/// </summary>
[Serializable]
public class VenueParameters
{
    [Header("Auditorium Dimensions (metres)")]
    public float roomLength = 30f;   // front-to-back
    public float roomWidth = 20f;    // side-to-side
    public float roomHeight = 8f;

    [Header("Screen")]
    public float screenWidth = 18f;
    public float screenHeight = 8f;
    public float screenDistanceFromFrontWall = 1f;
    public float screenHeightFromFloor = 2f;

    [Tooltip("Lateral offset of the screen's centre from the room's centre " +
             "line, in metres. Comes from the theatre's saved ScreenConfig " +
             "position.x — a screen an owner deliberately moved off-centre " +
             "used to be silently re-centred here.")]
    public float screenOffsetX = 0f;

    [Tooltip("Height of the screen's CENTRE above the floor, in metres. " +
             "Negative means 'not specified' — fall back to deriving it " +
             "from screenHeightFromFloor + screenHeight/2, which is what " +
             "this scene did before a theatre's own screen position was " +
             "ever sent. Comes from ScreenConfig position.y.")]
    public float screenCenterY = -1f;

    [Tooltip("Screen rotation around the vertical axis, in degrees. 0 faces " +
             "straight down +Z into the auditorium. From ScreenConfig.rotationY.")]
    public float screenRotationY = 0f;

    /// <summary>The screen centre height actually used, honouring
    /// <see cref="screenCenterY"/> when the theatre specified one.</summary>
    public float ResolvedScreenCenterY =>
        screenCenterY >= 0f ? screenCenterY : screenHeightFromFloor + (screenHeight / 2f);

    [Header("Seating Layout")]
    public int rows = 15;
    public int seatsPerRow = 20;
    public float seatWidth = 0.55f;
    public float seatSpacing = 0.60f;   // centre-to-centre, left-right
    public float rowSpacing = 1.10f;    // centre-to-centre, front-to-back
    public float firstRowDistanceFromScreen = 7f;
    public float rowRisePerRow = 0.12f; // slight height increase per row (stadium-style), set 0 for flat

    [Header("Arrangement")]
    public SeatArrangement arrangement = SeatArrangement.Straight;
    public float curveRadius = 25f; // only used when arrangement == Curved

    [Header("Aisles")]
    [Tooltip("How many vertical aisles to leave gaps for (0, 1, or 2)")]
    public int aisleCount = 1;
    public float aisleWidth = 1.2f;

    [Header("Seat Experience (Phase 3)")]
    [Tooltip("How high the camera sits above a Standard seat's position, in metres")]
    public float eyeHeightStandard = 1.2f;
    [Tooltip("Premium seats sit slightly differently than Standard")]
    public float eyeHeightPremium = 1.15f;
    [Tooltip("Recliners lean back, so the eye position is a bit lower")]
    public float eyeHeightRecliner = 1.0f;
    [Tooltip("Camera field of view during the seat experience, in degrees")]
    public float experienceFieldOfView = 70f;

    [Header("Ownership of Room Dimensions")]
    [Tooltip("True when roomWidth/roomLength/roomHeight came from a theatre " +
             "owner's saved configuration. When true those dimensions are " +
             "AUTHORITATIVE: RoomGenerator must not quietly enlarge them to " +
             "fit the seating, and reports a validation problem instead. " +
             "False for the in-editor generator panel and the demo flow, " +
             "where auto-expansion is a convenience rather than a silent " +
             "rewrite of somebody's configuration.")]
    public bool ownerConfiguredRoom = false;

    [Header("Enclosure Safety (Phase 4 - Immersive Theatre)")]
    [Tooltip("Extra space (metres) always left behind the back row and above " +
             "the tallest riser before the walls/ceiling are placed. The room " +
             "is auto-expanded to at least fit rows/seats + this margin, so " +
             "changing seating layout can never leave the seating area poking " +
             "outside the enclosed shell (which is what exposes the skybox).")]
    public float roomSafetyMargin = 4f;
    [Tooltip("Headroom (metres) kept above a seated person's eye line when " +
             "auto-sizing the ceiling height.")]
    public float ceilingHeadroom = 2.4f;

    [Header("Theatre Architecture & Lighting (Phase 4)")]
    [Tooltip("Distance (metres) between rows of recessed ceiling downlights.")]
    public float ceilingLightSpacing = 4f;
    [Tooltip("Brightness of each recessed ceiling downlight.")]
    public float ceilingLightIntensity = 1.0f;
    public Color ceilingLightColor = new Color(0.82f, 0.87f, 1f);

    [Tooltip("Distance (metres) between the small warm floor-level aisle lights.")]
    public float aisleLightSpacing = 2.2f;
    [Tooltip("Brightness of each aisle marker light.")]
    public float aisleLightIntensity = 0.35f;
    public Color aisleLightColor = new Color(1f, 0.82f, 0.55f);

    [Tooltip("Distance (metres) between the vertical acoustic panel grooves on the side walls.")]
    public float wallPanelSpacing = 2.5f;

    [Tooltip("How strongly the screen appears to glow and cast light onto the front rows.")]
    public float screenGlowIntensity = 0.8f;
}
