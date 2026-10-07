using UnityEngine;

/// <summary>
/// Builds a lightweight, clearly-visible speaker cabinet mesh for a single
/// speaker GameObject, so a configured speaker is something a user can
/// actually SEE in the generated theatre, not just an inaudible-until-
/// playing AudioSource.
///
/// Deliberately built AS A CHILD of the same GameObject that carries the
/// AudioSource (see SpatialAudioManager.AddSpeaker), rather than as a
/// separately-tracked object. That is what guarantees "visible object and
/// audio object represent the same speaker" (same ID, same position, same
/// rotation) without a second bookkeeping system to keep in sync — the
/// visual simply inherits its parent's transform.
///
/// No custom mesh assets are used (WebGL build stays lightweight, per
/// spec) — everything here is Unity primitives (cube/cylinder) combined
/// into a small "cabinet + driver" silhouette that reads unambiguously as
/// a speaker at a glance, without needing to be a detailed model.
/// </summary>
public static class SpeakerVisual
{
    /// <summary>
    /// Adds the visible cabinet mesh(es) to [speakerGo] and returns the
    /// container. [channel] and [type] together decide the cabinet's shape
    /// and size (a subwoofer reads as a big floor box; a ceiling speaker
    /// reads as a small downward-facing dome; everything else reads as a
    /// standard rectangular cabinet).
    /// </summary>
    public static GameObject Build(GameObject speakerGo, SpeakerChannel channel, string type)
    {
        var container = new GameObject("Visual");
        container.transform.SetParent(speakerGo.transform, false);

        SpeakerShape shape = ShapeFor(channel, type);
        Color cabinetColor = new Color(0.05f, 0.05f, 0.06f); // near-black cabinet, matches the bezel/room's dark trim

        GameObject cabinet = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cabinet.name = "Cabinet";
        cabinet.transform.SetParent(container.transform, false);
        cabinet.transform.localPosition = shape.CabinetOffset;
        cabinet.transform.localScale = shape.CabinetSize;
        ApplyMaterial(cabinet, cabinetColor, glossiness: 0.25f);

        // A small lighter-grey "driver" disc on the front face reads as a
        // speaker cone at a glance, even at a distance where the cabinet
        // alone would just look like a dark box.
        GameObject driver = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        driver.name = "Driver";
        driver.transform.SetParent(container.transform, false);
        driver.transform.localPosition = shape.CabinetOffset + (Vector3.forward * (shape.CabinetSize.z * 0.5f + 0.01f));
        driver.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
        driver.transform.localScale = new Vector3(shape.DriverRadius, shape.CabinetSize.z * 0.05f, shape.DriverRadius);
        ApplyMaterial(driver, new Color(0.35f, 0.35f, 0.38f), glossiness: 0.4f);

        return container;
    }

    private static void ApplyMaterial(GameObject go, Color color, float glossiness)
    {
        var renderer = go.GetComponent<Renderer>();
        var material = new Material(Shader.Find("Standard")) { color = color };
        if (material.HasProperty("_Glossiness")) material.SetFloat("_Glossiness", glossiness);
        if (material.HasProperty("_Metallic")) material.SetFloat("_Metallic", 0.1f);
        renderer.sharedMaterial = material;
    }

    private readonly struct SpeakerShape
    {
        public readonly Vector3 CabinetSize;
        public readonly Vector3 CabinetOffset;
        public readonly float DriverRadius;

        public SpeakerShape(Vector3 size, Vector3 offset, float driverRadius)
        {
            CabinetSize = size;
            CabinetOffset = offset;
            DriverRadius = driverRadius;
        }
    }

    /// <summary>Cabinet size/offset by speaker type first (an owner's explicit
    /// choice), falling back to channel when type is empty/unrecognised.</summary>
    private static SpeakerShape ShapeFor(SpeakerChannel channel, string type)
    {
        string t = (type ?? string.Empty).Trim().ToLowerInvariant();

        if (t == "subwoofer" || channel == SpeakerChannel.Lfe)
        {
            // Big floor-standing box — subwoofers are physically the
            // largest cabinet in a real cinema rig.
            return new SpeakerShape(new Vector3(0.5f, 0.5f, 0.5f), new Vector3(0f, -0.25f, 0f), 0.18f);
        }

        if (t == "ceiling" || channel == SpeakerChannel.Overhead)
        {
            // Small, roughly cube-ish enclosure — overhead/height channel
            // speakers are compact and unobtrusive by design.
            return new SpeakerShape(new Vector3(0.28f, 0.22f, 0.28f), Vector3.zero, 0.1f);
        }

        if (t == "sidesurround" || t == "rearsurround" ||
            channel == SpeakerChannel.LeftSurround || channel == SpeakerChannel.RightSurround)
        {
            // Slim wall-mount cabinet — taller than it is deep.
            return new SpeakerShape(new Vector3(0.22f, 0.34f, 0.16f), Vector3.zero, 0.08f);
        }

        // Default: a front L/C/R style cabinet.
        return new SpeakerShape(new Vector3(0.3f, 0.4f, 0.24f), Vector3.zero, 0.1f);
    }
}
