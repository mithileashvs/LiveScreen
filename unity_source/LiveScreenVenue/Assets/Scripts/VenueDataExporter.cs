using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

/// <summary>
/// Wraps everything about a generated venue into one exportable structure.
/// This mirrors the "Venue → Auditorium → Seats" data model described in
/// the Phase 2 spec, so it can eventually be sent to/from a real backend
/// without changing how the generator itself works.
/// </summary>
[Serializable]
public class VenueExportData
{
    public VenueParameters parameters;
    public List<SeatData> seats;
    public int totalSeats;
}

/// <summary>
/// Saves the current venue's parameters and every seat's calculated data
/// as a JSON file. Nothing here talks to a real server yet — this just
/// proves the data is clean and ready for that connection later.
/// </summary>
public static class VenueDataExporter
{
    public static string ExportToJson(VenueGenerator generator)
    {
        var exportData = new VenueExportData
        {
            parameters = generator.Parameters,
            seats = generator.GeneratedSeats,
            totalSeats = generator.GeneratedSeats.Count
        };

        string json = JsonUtility.ToJson(exportData, true);
        string path = Path.Combine(Application.persistentDataPath, "venue_data.json");
        File.WriteAllText(path, json);

        Debug.Log($"Venue data exported to: {path}");
        return path;
    }
}
