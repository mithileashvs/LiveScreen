using UnityEngine;

/// <summary>
/// Lives on every generated seat GameObject. When clicked, it tells the
/// VenueGenerator which seat was selected so the UI can display its details,
/// and visually highlights itself in gold (matching the LiveScreen app's
/// selected-seat color). This is the hook Phase 3 will use to move the
/// camera to this exact seat.
/// </summary>
public class SeatController : MonoBehaviour
{
    public SeatData Seat;

    private static readonly Color HighlightColor = new Color(0.91f, 0.73f, 0.29f); // LiveScreen gold

    private Renderer _renderer;
    private Color _originalColor;

    private void Awake()
    {
        _renderer = GetComponent<Renderer>();
        _originalColor = _renderer.material.color;
    }

    private void OnMouseDown()
    {
        VenueGenerator.Instance?.SelectSeat(this);
    }

    public void SetHighlighted(bool highlighted)
    {
        _renderer.material.color = highlighted ? HighlightColor : _originalColor;
    }
}
