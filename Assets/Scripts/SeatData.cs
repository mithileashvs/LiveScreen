using System;
using UnityEngine;

/// <summary>
/// Represents one generated seat. This is calculated automatically —
/// nothing here is ever typed in by hand.
/// [Serializable] lets this be exported to JSON later, for the future
/// backend connection described in the Phase 2 spec.
/// </summary>
[Serializable]
public class SeatData
{
    public string Id;          // e.g. "G12"
    public string Row;         // e.g. "G"
    public int Number;         // e.g. 12
    public SeatType Type;
    public Vector3 Position;
    public Quaternion Rotation;

    public override string ToString()
    {
        return $"Seat {Id}\n" +
               $"Position: ({Position.x:F2}, {Position.y:F2}, {Position.z:F2})\n" +
               $"Rotation Y: {Rotation.eulerAngles.y:F1}°\n" +
               $"Type: {Type}";
    }
}
