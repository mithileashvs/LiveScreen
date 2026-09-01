using UnityEngine;

/// <summary>
/// A simple on-screen control panel using Unity's built-in "IMGUI" system.
/// This deliberately avoids needing you to manually build a Canvas/UI in
/// the Editor — just attach this script next to VenueGenerator and it works.
///
/// Not final visual design — Phase 2 is about correct generation logic first.
/// </summary>
[RequireComponent(typeof(VenueGenerator))]
public class VenueGeneratorUI : MonoBehaviour
{
    private VenueGenerator _generator;

    // Text field buffers (IMGUI text fields work with strings, so we
    // convert to/from numbers when Generate is pressed).
    private string _length, _width, _height;
    private string _screenWidth, _screenHeight;
    private string _rows, _seatsPerRow;
    private string _seatSpacing, _rowSpacing, _firstRowDistance;
    private string _curveRadius;
    private string _aisleCount;

    private bool _showCurved;
    private string _exportStatusMessage = "";

    // Reusable 1x1 colored textures for the legend swatches.
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
        float panelHeight = (_showCurved ? 470 : 440) + 90; // extra room for export button + status text
        GUI.Box(new Rect(10, 10, 260, panelHeight), "");
        GUILayout.BeginArea(new Rect(20, 20, 240, panelHeight - 20));

        GUILayout.Label("LIVESCREEN VENUE GENERATOR", GUI.skin.box);

        GUILayout.Label("Auditorium Length (m)");
        _length = GUILayout.TextField(_length);

        GUILayout.Label("Auditorium Width (m)");
        _width = GUILayout.TextField(_width);

        GUILayout.Label("Auditorium Height (m)");
        _height = GUILayout.TextField(_height);

        GUILayout.Label("Screen Width (m)");
        _screenWidth = GUILayout.TextField(_screenWidth);

        GUILayout.Label("Screen Height (m)");
        _screenHeight = GUILayout.TextField(_screenHeight);

        GUILayout.Label("Rows");
        _rows = GUILayout.TextField(_rows);

        GUILayout.Label("Seats per Row");
        _seatsPerRow = GUILayout.TextField(_seatsPerRow);

        GUILayout.Label("Seat Spacing (m)");
        _seatSpacing = GUILayout.TextField(_seatSpacing);

        GUILayout.Label("Row Spacing (m)");
        _rowSpacing = GUILayout.TextField(_rowSpacing);

        GUILayout.Label("Aisle Count (0-2)");
        _aisleCount = GUILayout.TextField(_aisleCount);

        GUILayout.Space(6);
        _showCurved = GUILayout.Toggle(_showCurved, " Curved seating");
        if (_showCurved)
        {
            GUILayout.Label("Curve Radius (m)");
            _curveRadius = GUILayout.TextField(_curveRadius);
        }

        GUILayout.Space(10);
        string buttonLabel = _generator.HasGeneratedOnce ? "REGENERATE VENUE" : "GENERATE VENUE";
        if (GUILayout.Button(buttonLabel, GUILayout.Height(36)))
        {
            ApplyFieldsAndGenerate();
        }

        GUILayout.Space(6);
        if (GUILayout.Button("Export Venue Data (JSON)", GUILayout.Height(28)))
        {
            string path = VenueDataExporter.ExportToJson(_generator);
            _exportStatusMessage = $"Saved to:\n{path}";
        }

        if (!string.IsNullOrEmpty(_exportStatusMessage))
        {
            GUILayout.Label(_exportStatusMessage);
        }

        GUILayout.EndArea();

        DrawLegend();
        DrawSelectedSeatPanel();
    }

    private void DrawLegend()
    {
        Rect legendRect = new Rect(10, Screen.height - 100, 200, 90);
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
        float panelHeight = 140;
        Rect panelRect = new Rect(Screen.width - 270, 10, 260, panelHeight);

        GUI.Box(panelRect, "");
        GUILayout.BeginArea(new Rect(panelRect.x + 10, panelRect.y + 10, 240, panelHeight - 20));
        GUILayout.Label($"Seat {seat.Id}", GUI.skin.box);
        GUILayout.Label($"Position: ({seat.Position.x:F2}, {seat.Position.y:F2}, {seat.Position.z:F2})");
        GUILayout.Label($"Rotation Y: {seat.Rotation.eulerAngles.y:F1}°");
        GUILayout.Label($"Type: {seat.Type}");
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
    }

    private float ParseOr(string text, float fallback)
    {
        return float.TryParse(text, out float result) ? result : fallback;
    }
}
