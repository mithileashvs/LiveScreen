using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// The main entry point for Phase 2. Holds the current venue parameters,
/// and is responsible for clearing any previously generated venue and
/// building a new one from scratch whenever Generate() is called.
///
/// Attach this to a single empty GameObject in your scene (e.g. "VenueManager").
/// </summary>
public class VenueGenerator : MonoBehaviour
{
    public static VenueGenerator Instance { get; private set; }

    public VenueParameters Parameters = new VenueParameters();

    [HideInInspector] public List<SeatData> GeneratedSeats = new List<SeatData>();
    [HideInInspector] public SeatData SelectedSeat;
    [HideInInspector] public bool HasGeneratedOnce;

    private Transform _venueRoot;
    private SeatController _selectedController;

    private void Awake()
    {
        Instance = this;
    }

    private void Start()
    {
        // Build the default venue as soon as the app starts, so there's
        // something to see immediately.
        Generate();
    }

    /// <summary>
    /// Clears whatever venue currently exists and builds a brand new one
    /// from the current Parameters. Call this after changing any values.
    /// </summary>
    public void Generate()
    {
        ClearExistingVenue();

        GameObject root = new GameObject("GeneratedVenue");
        root.transform.SetParent(transform, false);
        _venueRoot = root.transform;

        RoomGenerator.Generate(_venueRoot, Parameters);
        ScreenGenerator.Generate(_venueRoot, Parameters);
        GeneratedSeats = SeatGenerator.Generate(_venueRoot, Parameters);

        SelectedSeat = null;
        _selectedController = null;
        HasGeneratedOnce = true;

        Debug.Log($"Venue generated: {Parameters.rows} rows x {Parameters.seatsPerRow} seats = {GeneratedSeats.Count} total seats.");
    }

    private void ClearExistingVenue()
    {
        if (_venueRoot != null)
        {
            Destroy(_venueRoot.gameObject);
        }
    }

    public void SelectSeat(SeatController controller)
    {
        // Un-highlight whatever was selected before.
        if (_selectedController != null)
        {
            _selectedController.SetHighlighted(false);
        }

        // If the user clicked the same seat again, deselect it entirely.
        if (_selectedController == controller)
        {
            _selectedController = null;
            SelectedSeat = null;
            return;
        }

        controller.SetHighlighted(true);
        _selectedController = controller;
        SelectedSeat = controller.Seat;

        Debug.Log($"Selected {SelectedSeat.Id} at {SelectedSeat.Position}");
    }
}
