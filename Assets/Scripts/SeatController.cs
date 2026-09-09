using UnityEngine;

/// <summary>
/// Lives on every generated seat's root GameObject. When clicked, it tells
/// the VenueGenerator which seat was selected so the UI can display its
/// details, and visually highlights itself in gold (matching the LiveScreen
/// app's selected-seat color). This is the hook Phase 3 uses to move the
/// camera to this exact seat.
///
/// A seat is now several child parts (cushion, backrest segments, armrests,
/// base — see CinemaSeatBuilder) instead of one cube, so highlighting can no
/// longer just flip a single Renderer's color. Instead, CinemaSeatBuilder
/// hands this controller the seat's "fabric" renderers (the parts that
/// should visibly change color when selected) via Initialize(), and the
/// color override is applied with a MaterialPropertyBlock rather than
/// touching Renderer.material — that keeps every seat of the same type
/// sharing one Material instance for batching (spec section 12), while still
/// letting exactly one seat glow gold at a time.
/// </summary>
public class SeatController : MonoBehaviour
{
    public SeatData Seat;

    private static readonly Color HighlightColor = new Color(0.91f, 0.73f, 0.29f); // LiveScreen gold
    private static readonly int ColorPropertyId = Shader.PropertyToID("_Color");

    private Renderer[] _highlightRenderers;
    private Color _baseColor;
    private MaterialPropertyBlock _propertyBlock;

    /// <summary>Called once by CinemaSeatBuilder right after it builds this seat's parts.</summary>
    public void Initialize(Renderer[] highlightRenderers, Color baseColor)
    {
        _highlightRenderers = highlightRenderers;
        _baseColor = baseColor;
        _propertyBlock = new MaterialPropertyBlock();
        ApplyColor(_baseColor);
    }

    private void OnMouseDown()
    {
        VenueGenerator.Instance?.SelectSeat(this);
    }

    public void SetHighlighted(bool highlighted)
    {
        ApplyColor(highlighted ? HighlightColor : _baseColor);
    }

    private void ApplyColor(Color color)
    {
        if (_highlightRenderers == null) return;

        foreach (var renderer in _highlightRenderers)
        {
            if (renderer == null) continue;
            renderer.GetPropertyBlock(_propertyBlock);
            _propertyBlock.SetColor(ColorPropertyId, color);
            renderer.SetPropertyBlock(_propertyBlock);
        }
    }
}
