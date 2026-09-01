using UnityEngine;

[RequireComponent(typeof(VenueGenerator))]
public class VenueGeneratorUI : MonoBehaviour
{
    private VenueGenerator _generator;

    private string _length, _width, _height;
    private string _screenWidth, _screenHeight;
    private string _rows, _seatsPerRow;
    private string _seatSpacing, _rowSpacing, _firstRowDistance;
    private string _curveRadius;
    private string _aisleCount;

    private bool _showCurved;
    private string _exportStatusMessage = "";

    private Texture2D _standardSwatch, _premiumSwatch, _reclinerSwatch;

    private void Start()
    {
        _generator = GetComponent<VenueGenerator>();
        SyncFieldsFromParameters();

        _standardSwatch = MakeSwatch(new Color(0.16f, 0.16f, 0.21f));
        _premiumSwatch = MakeSwatch(new Color(0.70f, 0.53f, 1f));
        _reclinerSwatch = MakeSwatch(new Color(0.29f, 0.78f, 0.91f));
    }

    private Texture2D MakeSwatch(Color color)
    {
        Texture2D tex = new Texture2D(1, 1);
        tex.SetPixel(0, 0, color);
        tex.Apply();
        return tex;
    }

    private void SyncFieldsFromParameters()
    {
        var p = _generator.Parameters;
        _length = p.roomLength.ToString();
        _width = p.roomWidth.ToString();
        _height = p.roomHeight.ToString();
        _screenWidth = p.screenWidth.ToString();
        _screenHeight = p.screenHeight.ToString();
        _rows = p.rows.ToString();
        _seatsPerRow = p.seatsPerRow.ToString();
        _seatSpacing = p.seatSpacing.ToString();
        _rowSpacing = p.rowSpacing.ToString();
        _firstRowDistance = p.firstRowDistanceFromScreen.ToString();
        _curveRadius = p.curveRadius.ToString();
        _aisleCount = p.aisleCount.ToString();
        _showCurved = p.arrangement == SeatArrangement.Curved;
    }

    private void OnGUI()
    {
        // While the seat experience is active, show only the minimal
        // experience overlay instead of the full generator panel.
        if (ExperienceController.Instance != null && ExperienceController.Instance.IsExperienceActive)
        {
            DrawExperienceOverlay();
            return;
        }

        float panelWidth = 340;
        float panelHeight = 300 + (_showCurved ? 24 : 0) + (string.IsNullOrEmpty(_exportStatusMessage) ? 0 : 30) + 15;

        GUI.Box(new Rect(10, 10, panelWidth, panelHeight), "");
        GUILayout.BeginArea(new Rect(20, 20, panelWidth - 20, panelHeight - 20));

        GUILayout.Label("LIVESCREEN VENUE GENERATOR", GUI.skin.box);
        GUILayout.Space(6);

        GUILayout.BeginHorizontal();

        GUILayout.BeginVertical(GUILayout.Width(150));
        FieldRow("Length (m)", ref _length);
        FieldRow("Width (m)", ref _width);
        FieldRow("Height (m)", ref _height);
        FieldRow("Screen W (m)", ref _screenWidth);
        FieldRow("Screen H (m)", ref _screenHeight);
        GUILayout.EndVertical();

        GUILayout.Space(10);

        GUILayout.BeginVertical(GUILayout.Width(150));
        FieldRow("Rows", ref _rows);
        FieldRow("Seats/Row", ref _seatsPerRow);
        FieldRow("Seat Gap (m)", ref _seatSpacing);
        FieldRow("Row Gap (m)", ref _rowSpacing);
        FieldRow("Aisles (0-2)", ref _aisleCount);
        GUILayout.EndVertical();

        GUILayout.EndHorizontal();

        GUILayout.Space(6);
        _showCurved = GUILayout.Toggle(_showCurved, " Curved seating");
        if (_showCurved)
        {
            FieldRow("Curve Radius (m)", ref _curveRadius);
        }

        GUILayout.Space(10);
        string buttonLabel = _generator.HasGeneratedOnce ? "REGENERATE VENUE" : "GENERATE VENUE";
        if (GUILayout.Button(buttonLabel, GUILayout.Height(36)))
        {
            ApplyFieldsAndGenerate();
        }

        GUILayout.Space(6);
        if (GUILayout.Button("Export Venue Data (JSON)", GUILayout.Height(26)))
        {
            string path = VenueDataExporter.ExportToJson(_generator);
            _exportStatusMessage = "Saved: venue_data.json (see Console for full path)";
        }

        if (!string.IsNullOrEmpty(_exportStatusMessage))
        {
            GUILayout.Label(_exportStatusMessage);
        }

        GUILayout.EndArea();

        DrawLegend(panelHeight);
        DrawSelectedSeatPanel();
    }

    private void FieldRow(string label, ref string value)
    {
        GUILayout.BeginHorizontal();
        GUILayout.Label(label, GUILayout.Width(90));
        value = GUILayout.TextField(value, GUILayout.Width(50));
        GUILayout.EndHorizontal();
    }

    private void DrawLegend(float mainPanelHeight)
    {
        Rect legendRect = new Rect(10, 20 + mainPanelHeight, 200, 90);
        GUI.Box(legendRect, "");
        GUILayout.BeginArea(new Rect(legendRect.x + 10, legendRect.y + 8, 180, 80));

        GUILayout.Label("Seat Types");
        DrawLegendRow(_standardSwatch, "Standard");
        DrawLegendRow(_premiumSwatch, "Premium");
        DrawLegendRow(_reclinerSwatch, "Recliner");

        GUILayout.EndArea();
    }

    private void DrawLegendRow(Texture2D swatch, string label)
    {
        GUILayout.BeginHorizontal();
        GUILayout.Label(swatch, GUILayout.Width(16), GUILayout.Height(16));
        GUILayout.Label(label);
        GUILayout.EndHorizontal();
    }

    private void DrawSelectedSeatPanel()
    {
        if (_generator.SelectedSeat == null) return;

        var seat = _generator.SelectedSeat;
        float panelHeight = 180;
        Rect panelRect = new Rect(Screen.width - 270, 10, 260, panelHeight);

        GUI.Box(panelRect, "");
        GUILayout.BeginArea(new Rect(panelRect.x + 10, panelRect.y + 10, 240, panelHeight - 20));
        GUILayout.Label($"Seat {seat.Id}", GUI.skin.box);
        GUILayout.Label($"Position: ({seat.Position.x:F2}, {seat.Position.y:F2}, {seat.Position.z:F2})");
        GUILayout.Label($"Rotation Y: {seat.Rotation.eulerAngles.y:F1}°");
        GUILayout.Label($"Type: {seat.Type}");

        GUILayout.Space(8);
        if (GUILayout.Button("Experience This Seat", GUILayout.Height(30)))
        {
            ExperienceController.Instance?.EnterExperience(seat);
        }

        GUILayout.EndArea();
    }

    /// <summary>
    /// The minimal overlay shown while the user is "sitting" in a seat —
    /// deliberately sparse so it doesn't distract from the 3D view (spec section 9).
    /// </summary>
    private void DrawExperienceOverlay()
    {
        var session = ExperienceController.Instance.CurrentSession;
        if (session == null) return;

        float panelWidth = 220;
        Rect topRect = new Rect((Screen.width - panelWidth) / 2f, 20, panelWidth, 70);

        GUI.Box(topRect, "");
        GUILayout.BeginArea(new Rect(topRect.x + 10, topRect.y + 8, panelWidth - 20, 54));
        GUILayout.Label("LIVESCREEN", GUI.skin.box);
        GUILayout.Label($"Seat {session.SeatId}", GUI.skin.label);
        GUILayout.EndArea();

        Rect exitRect = new Rect((Screen.width - 180) / 2f, Screen.height - 70, 180, 44);
        GUI.Box(exitRect, "");
        GUILayout.BeginArea(exitRect);
        if (GUILayout.Button("Exit Experience", GUILayout.Height(40)))
        {
            ExperienceController.Instance.ExitExperience();
        }
        GUILayout.EndArea();
    }

    private void ApplyFieldsAndGenerate()
    {
        var p = _generator.Parameters;

        p.roomLength = ParseOr(_length, p.roomLength);
        p.roomWidth = ParseOr(_width, p.roomWidth);
        p.roomHeight = ParseOr(_height, p.roomHeight);
        p.screenWidth = ParseOr(_screenWidth, p.screenWidth);
        p.screenHeight = ParseOr(_screenHeight, p.screenHeight);
        p.rows = Mathf.Max(1, (int)ParseOr(_rows, p.rows));
        p.seatsPerRow = Mathf.Max(1, (int)ParseOr(_seatsPerRow, p.seatsPerRow));
        p.seatSpacing = ParseOr(_seatSpacing, p.seatSpacing);
        p.rowSpacing = ParseOr(_rowSpacing, p.rowSpacing);
        p.curveRadius = ParseOr(_curveRadius, p.curveRadius);
        p.aisleCount = Mathf.Clamp((int)ParseOr(_aisleCount, p.aisleCount), 0, 2);
        p.arrangement = _showCurved ? SeatArrangement.Curved : SeatArrangement.Straight;

        _generator.Generate();

        // RoomGenerator may have auto-expanded roomLength/Width/Height to
        // guarantee full enclosure of the seating layout (see
        // RoomGenerator.EnsureRoomFitsSeating) — re-sync the displayed
        // numbers so the venue owner can see the corrected values instead
        // of the panel silently disagreeing with what's on screen.
        SyncFieldsFromParameters();
    }

    private float ParseOr(string text, float fallback)
    {
        return float.TryParse(text, out float result) ? result : fallback;
    }
}
