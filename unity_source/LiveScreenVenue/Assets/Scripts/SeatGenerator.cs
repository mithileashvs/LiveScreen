using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// The heart of Phase 2: turns row/seat-count/spacing numbers into
/// exact 3D positions, rotations, and IDs for every seat — automatically.
///
/// Nothing here is hand-placed. Every seat's coordinates are calculated
/// from VenueParameters using simple geometry.
/// </summary>
public static class SeatGenerator
{
    public static List<SeatData> Generate(Transform parent, VenueParameters p)
    {
        GameObject seatingRoot = new GameObject("Seating");
        seatingRoot.transform.SetParent(parent, false);

        List<SeatData> allSeats = new List<SeatData>();

        // Work out which seat "slots" in a row are aisle gaps vs real seats.
        // Example: seatsPerRow = 20, aisleCount = 1 -> two blocks of ~10 seats
        // with a gap in the middle.
        List<int> aisleAfterSeatIndexes = CalculateAislePositions(p.seatsPerRow, p.aisleCount);

        for (int rowIndex = 0; rowIndex < p.rows; rowIndex++)
        {
            string rowLabel = GetRowLabel(rowIndex);

            // Distance of this row from the screen (front-to-back).
            float rowDepth = ComputeRowDepth(rowIndex, p);
            float rowHeight = ComputeRowHeight(rowIndex, p); // slight stadium-style rise

            SeatType rowSeatType = DetermineSeatType(rowIndex, p.rows);

            int seatNumber = 1;
            for (int seatIndex = 0; seatIndex < p.seatsPerRow; seatIndex++)
            {
                Vector3 localPos;
                Quaternion localRot;

                if (p.arrangement == SeatArrangement.Curved)
                {
                    CalculateCurvedPosition(seatIndex, rowIndex, p, out localPos, out localRot);
                }
                else
                {
                    CalculateStraightPosition(seatIndex, p, out localPos, out localRot);
                }

                localPos.z += rowDepth;
                localPos.y = rowHeight;

                // Add extra horizontal gap for aisles that fall before this seat.
                float aisleShift = CountAislesBefore(seatIndex, aisleAfterSeatIndexes) * p.aisleWidth;
                localPos.x += aisleShift - (aisleAfterSeatIndexes.Count * p.aisleWidth / 2f);

                SeatData seat = new SeatData
                {
                    Id = $"{rowLabel}{seatNumber}",
                    Row = rowLabel,
                    Number = seatNumber,
                    Type = rowSeatType,
                    Position = localPos,
                    Rotation = localRot
                };

                allSeats.Add(seat);
                CreateSeatObject(seatingRoot.transform, seat, p);

                seatNumber++;
            }
        }

        return allSeats;
    }

    /// <summary>
    /// How far row <paramref name="rowIndex"/> is from the screen, front-to-back.
    /// This is the SINGLE source of truth for row depth — RoomGenerator's floor
    /// risers use this exact same formula so the solid ground under a row and
    /// the seats sitting on it can never drift out of sync.
    /// </summary>
    public static float ComputeRowDepth(int rowIndex, VenueParameters p)
    {
        return p.firstRowDistanceFromScreen + (rowIndex * p.rowSpacing);
    }

    /// <summary>
    /// How high row <paramref name="rowIndex"/> sits above the base floor
    /// (the gentle stadium-style rise). Same single-source-of-truth reasoning
    /// as <see cref="ComputeRowDepth"/> — RoomGenerator's risers read this too.
    /// </summary>
    public static float ComputeRowHeight(int rowIndex, VenueParameters p)
    {
        return rowIndex * p.rowRisePerRow;
    }

    /// <summary>
    /// Estimates the minimum room footprint (width, length, height) needed to
    /// fully enclose every seat this venue will generate, plus a safety
    /// margin. RoomGenerator calls this before laying out walls/ceiling so
    /// the auditorium can NEVER end up smaller than the seating it has to
    /// contain — which is what would expose the open skybox around the
    /// edges. This is intentionally conservative (worst case for curved
    /// arrangement) rather than pixel-perfect.
    /// </summary>
    /// <summary>
    /// Estimates the minimum room footprint (width, length, height) needed to
    /// fully enclose every seat this venue will generate, plus a safety
    /// margin — AND to fully enclose the configured screen. This is the
    /// exact bug behind the "grey hole above the screen": with the
    /// defaults (screenHeightFromFloor 2m + screenHeight 8m = a screen top
    /// edge at 10m) the ceiling used to be auto-sized purely from the
    /// seating (8m default), so the screen — and its bezel — physically
    /// poked straight through the ceiling into the void above, and that
    /// void is what showed through as a grey/blue patch (Unity's default
    /// skybox, still visible through the gap). Factoring the screen in
    /// here means the ceiling/walls can never end up smaller than the
    /// screen itself, for any configuration.
    /// </summary>
    public static Vector3 EstimateRequiredRoomBounds(VenueParameters p)
    {
        int lastRow = Mathf.Max(0, p.rows - 1);

        float requiredLength = ComputeRowDepth(lastRow, p) + p.roomSafetyMargin;

        float seatingRequiredHeight = ComputeRowHeight(lastRow, p) + p.ceilingHeadroom;
        // ScreenGenerator's bezel is drawn 0.5m taller/wider than the screen
        // itself (see ScreenGenerator.BuildBezel) — matched here so the
        // bezel can't poke through either, not just the screen panel.
        float screenTopEdge = p.screenHeightFromFloor + p.screenHeight + 0.5f;
        float requiredHeight = Mathf.Max(seatingRequiredHeight, screenTopEdge + p.ceilingHeadroom);

        float halfWidth;
        if (p.arrangement == SeatArrangement.Curved)
        {
            // Worst case: the back row's arc radius, which is always the
            // widest point of a curved layout.
            halfWidth = p.curveRadius + (lastRow * p.rowSpacing);
        }
        else
        {
            float rowWidth = (p.seatsPerRow - 1) * p.seatSpacing;
            float aisleExtra = Mathf.Max(0, p.aisleCount) * p.aisleWidth;
            halfWidth = (rowWidth / 2f) + aisleExtra;
        }

        // The screen (plus its 0.5m bezel margin) must also fit within the
        // walls' width, same reasoning as the height check above.
        halfWidth = Mathf.Max(halfWidth, (p.screenWidth + 0.5f) / 2f);

        float requiredWidth = (halfWidth * 2f) + p.roomSafetyMargin;

        return new Vector3(requiredWidth, requiredHeight, requiredLength);
    }

    /// <summary>Straight rows: seats sit on a flat line, all facing forward (toward the screen).</summary>
    private static void CalculateStraightPosition(int seatIndex, VenueParameters p, out Vector3 position, out Quaternion rotation)
    {
        float rowWidth = (p.seatsPerRow - 1) * p.seatSpacing;
        float x = -rowWidth / 2f + (seatIndex * p.seatSpacing);

        position = new Vector3(x, 0, 0);
        rotation = Quaternion.identity; // facing forward, toward -Z... actually toward screen at Z=0, so face -Z
        rotation = Quaternion.Euler(0, 180f, 0);
    }

    /// <summary>
    /// Curved rows: each row is an arc. Rows further back use a larger radius,
    /// so the whole auditorium curves outward like a real cinema.
    /// Seats rotate to always face the centre (the screen).
    /// </summary>
    private static void CalculateCurvedPosition(int seatIndex, int rowIndex, VenueParameters p, out Vector3 position, out Quaternion rotation)
    {
        float rowRadius = p.curveRadius + (rowIndex * p.rowSpacing);
        float totalAngle = (p.seatsPerRow - 1) * p.seatSpacing / rowRadius; // radians
        float startAngle = -totalAngle / 2f;
        float angle = startAngle + (seatIndex * (p.seatSpacing / rowRadius));

        float x = rowRadius * Mathf.Sin(angle);
        float zBow = rowRadius * (1 - Mathf.Cos(angle)); // how far this seat bows forward/back on the arc

        position = new Vector3(x, 0, -zBow);
        // Face toward the centre of the curve (the screen), then flip 180°
        // since our seats are modelled facing -Z by default.
        float angleDegrees = angle * Mathf.Rad2Deg;
        rotation = Quaternion.Euler(0, 180f + angleDegrees, 0);
    }

    /// <summary>Assigns seat types by row: front rows = Recliner, next few = Premium, rest = Standard.</summary>
    private static SeatType DetermineSeatType(int rowIndex, int totalRows)
    {
        if (rowIndex < Mathf.CeilToInt(totalRows * 0.15f)) return SeatType.Recliner;
        if (rowIndex < Mathf.CeilToInt(totalRows * 0.4f)) return SeatType.Premium;
        return SeatType.Standard;
    }

    /// <summary>Converts a row index (0,1,2...) into a letter label (A,B,C... then AA,AB... if needed).</summary>
    private static string GetRowLabel(int rowIndex)
    {
        if (rowIndex < 26)
        {
            return ((char)('A' + rowIndex)).ToString();
        }
        // Fallback for very large venues: AA, AB, AC...
        int first = rowIndex / 26 - 1;
        int second = rowIndex % 26;
        return $"{(char)('A' + first)}{(char)('A' + second)}";
    }

    /// <summary>Works out which seat indexes should have an aisle gap placed right after them.</summary>
    private static List<int> CalculateAislePositions(int seatsPerRow, int aisleCount)
    {
        List<int> positions = new List<int>();
        if (aisleCount <= 0) return positions;

        int blockSize = seatsPerRow / (aisleCount + 1);
        for (int i = 1; i <= aisleCount; i++)
        {
            positions.Add(blockSize * i - 1); // gap after this seat index
        }
        return positions;
    }

    private static int CountAislesBefore(int seatIndex, List<int> aislePositions)
    {
        int count = 0;
        foreach (int pos in aislePositions)
        {
            if (seatIndex > pos) count++;
        }
        return count;
    }

    private static void CreateSeatObject(Transform parent, SeatData seat, VenueParameters p)
    {
        // Actual seat geometry/materials live in CinemaSeatBuilder now (backrest,
        // cushion, armrests, base — see spec section 4) instead of a single cube.
        // SeatGenerator stays focused on WHERE seats go; CinemaSeatBuilder handles
        // what they look like.
        CinemaSeatBuilder.Build(parent, seat, p);
    }

    internal static Color ColorForSeatType(SeatType type)
    {
        switch (type)
        {
            case SeatType.Recliner: return new Color(0.29f, 0.78f, 0.91f); // blue, matches LiveScreen app
            case SeatType.Premium: return new Color(0.70f, 0.53f, 1f);     // purple
            default: return new Color(0.16f, 0.16f, 0.21f);                // standard dark grey
        }
    }
}
