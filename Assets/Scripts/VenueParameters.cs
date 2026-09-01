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
}
