using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Builds one cinema seat as a small composed hierarchy — a support base,
/// a cushion, a two-segment angled backrest (reads as a curved backrest
/// without needing a custom mesh), and armrests — instead of the single
/// flat cube seats used before (spec section 4: "Replace the block seat look").
///
/// Performance (spec section 12): every seat of the same SeatType shares
/// the exact same Material instances, created once and cached below. The
/// gold "selected" highlight is applied per-seat via a MaterialPropertyBlock
/// (see SeatController) instead of instancing a new material per seat, so
/// batching still works no matter how many hundreds of seats exist.
/// </summary>
public static class CinemaSeatBuilder
{
    private static readonly Dictionary<SeatType, Material> FabricMaterials = new Dictionary<SeatType, Material>();
    private static Material _frameMaterial;

    public static GameObject Build(Transform parent, SeatData seat, VenueParameters p)
    {
        Material fabric = GetFabricMaterial(seat.Type);
        Material frame = GetFrameMaterial();

        GameObject root = new GameObject($"Seat_{seat.Id}");
        root.transform.SetParent(parent, false);
        root.transform.localPosition = seat.Position;
        root.transform.localRotation = seat.Rotation;

        float w = p.seatWidth;

        // Support base — what makes the seat look like it's actually resting
        // on the floor/riser instead of floating above it.
        CreatePart(root.transform, "Base",
            new Vector3(0f, 0.20f, -0.03f), Quaternion.identity,
            new Vector3(w * 0.7f, 0.40f, 0.40f), frame);

        // Cushion.
        Renderer cushion = CreatePart(root.transform, "Cushion",
            new Vector3(0f, 0.46f, 0.06f), Quaternion.identity,
            new Vector3(w, 0.14f, 0.52f), fabric);

        // Backrest, built from two progressively-angled segments so it reads
        // as one curved backrest rather than a flat slab standing straight up.
        Renderer backLower = CreatePart(root.transform, "BackrestLower",
            new Vector3(0f, 0.72f, -0.24f), Quaternion.Euler(-6f, 0f, 0f),
            new Vector3(w, 0.50f, 0.10f), fabric);

        Renderer backUpper = CreatePart(root.transform, "BackrestUpper",
            new Vector3(0f, 1.06f, -0.31f), Quaternion.Euler(-16f, 0f, 0f),
            new Vector3(w * 0.94f, 0.34f, 0.09f), fabric);

        // Armrests.
        CreatePart(root.transform, "ArmrestLeft",
            new Vector3(-(w / 2f + 0.035f), 0.62f, -0.02f), Quaternion.identity,
            new Vector3(0.07f, 0.30f, 0.50f), frame);
        CreatePart(root.transform, "ArmrestRight",
            new Vector3(w / 2f + 0.035f, 0.62f, -0.02f), Quaternion.identity,
            new Vector3(0.07f, 0.30f, 0.50f), frame);

        // One collider for the whole seat, so clicking any part of it selects
        // the seat — each child part's own auto-generated collider is
        // removed in CreatePart() to avoid duplicate/blocking hit tests.
        BoxCollider collider = root.AddComponent<BoxCollider>();
        collider.center = new Vector3(0f, 0.65f, -0.05f);
        collider.size = new Vector3(w + 0.10f, 1.30f, 0.75f);

        var controller = root.AddComponent<SeatController>();
        controller.Seat = seat;
        controller.Initialize(new[] { cushion, backLower, backUpper }, SeatGenerator.ColorForSeatType(seat.Type));

        return root;
    }

    private static Renderer CreatePart(Transform parent, string name, Vector3 localPos, Quaternion localRot, Vector3 scale, Material sharedMaterial)
    {
        GameObject part = GameObject.CreatePrimitive(PrimitiveType.Cube);
        part.name = name;
        part.transform.SetParent(parent, false);
        part.transform.localPosition = localPos;
        part.transform.localRotation = localRot;
        part.transform.localScale = scale;

        // The seat root carries the one collider we actually want (added by
        // the caller); primitives come with their own by default.
        Object.Destroy(part.GetComponent<Collider>());

        var renderer = part.GetComponent<Renderer>();
        renderer.sharedMaterial = sharedMaterial; // shared, not .material — keeps seats batching-friendly
        return renderer;
    }

    private static Material GetFabricMaterial(SeatType type)
    {
        if (FabricMaterials.TryGetValue(type, out Material existing) && existing != null)
        {
            return existing;
        }

        Material mat = new Material(Shader.Find("Standard"))
        {
            color = SeatGenerator.ColorForSeatType(type)
        };
        // Premium fabric read: fairly rough, not shiny or metallic.
        SafeSetFloat(mat, "_Glossiness", 0.28f);
        SafeSetFloat(mat, "_Metallic", 0f);

        FabricMaterials[type] = mat;
        return mat;
    }

    private static Material GetFrameMaterial()
    {
        if (_frameMaterial != null) return _frameMaterial;

        _frameMaterial = new Material(Shader.Find("Standard"))
        {
            color = new Color(0.06f, 0.06f, 0.07f)
        };
        // Seat bases/armrests read as a dark brushed-metal frame.
        SafeSetFloat(_frameMaterial, "_Glossiness", 0.45f);
        SafeSetFloat(_frameMaterial, "_Metallic", 0.6f);

        return _frameMaterial;
    }

    private static void SafeSetFloat(Material mat, string property, float value)
    {
        if (mat.HasProperty(property))
        {
            mat.SetFloat(property, value);
        }
    }
}
