using UnityEngine;

/// <summary>
/// Builds the cinema screen — a bright placeholder panel with a dark bezel
/// frame (spec section 11/14: "premium" read) and a soft light so the
/// screen appears to illuminate the front rows (spec section 6). In a later
/// phase this will display an actual trailer.
/// </summary>
public static class ScreenGenerator
{
    public static GameObject Generate(Transform parent, VenueParameters p)
    {
        GameObject screen = GameObject.CreatePrimitive(PrimitiveType.Cube);
        screen.name = "Screen";
        screen.transform.SetParent(parent, false);

        // Centre height, lateral offset and rotation all come from the
        // theatre's own saved ScreenConfig when one was sent (see
        // VenueParameters.ResolvedScreenCenterY / screenOffsetX /
        // screenRotationY). They fall back to this scene's previous
        // behaviour when nothing was sent, so a brand-new theatre with no
        // saved screen still looks like it always did.
        float centerY = p.ResolvedScreenCenterY;
        Quaternion screenRotation = Quaternion.Euler(0f, p.screenRotationY, 0f);

        screen.transform.localPosition = new Vector3(p.screenOffsetX, centerY, p.screenDistanceFromFrontWall);
        screen.transform.localRotation = screenRotation;
        screen.transform.localScale = new Vector3(p.screenWidth, p.screenHeight, 0.05f);

        Material screenMaterial = new Material(Shader.Find("Standard")) { color = new Color(0.9f, 0.9f, 0.95f) };
        // A real cinema screen is a matte, diffuse projection surface, not
        // reflective — setting glossiness and metallic to 0 eliminates specular
        // hot spots from any ceiling lights in the auditorium.
        if (screenMaterial.HasProperty("_Glossiness")) screenMaterial.SetFloat("_Glossiness", 0f);
        if (screenMaterial.HasProperty("_Metallic")) screenMaterial.SetFloat("_Metallic", 0f);
        if (screenMaterial.HasProperty("_EmissionColor"))
        {
            screenMaterial.EnableKeyword("_EMISSION");
            screenMaterial.SetColor("_EmissionColor", Color.white * p.screenGlowIntensity);
        }
        screen.GetComponent<Renderer>().sharedMaterial = screenMaterial;

        BuildBezel(parent, screen.transform, p, centerY);
        BuildScreenGlowLight(parent, p, centerY);

        return screen;
    }

    /// <summary>A thin dark frame just behind/around the screen — reads as a proscenium
    /// rather than a flat panel floating on the front wall.</summary>
    private static void BuildBezel(Transform parent, Transform screenTransform, VenueParameters p, float centerY)
    {
        GameObject bezel = GameObject.CreatePrimitive(PrimitiveType.Cube);
        bezel.name = "ScreenBezel";
        bezel.transform.SetParent(parent, false);
        // Sits 3cm BEHIND the screen along the screen's own facing
        // direction, so the bezel still frames the panel correctly once the
        // screen is rotated rather than drifting out in front of it.
        Quaternion screenRotation = Quaternion.Euler(0f, p.screenRotationY, 0f);
        Vector3 behind = screenRotation * new Vector3(0f, 0f, -0.03f);
        bezel.transform.localPosition =
            new Vector3(p.screenOffsetX, centerY, p.screenDistanceFromFrontWall) + behind;
        bezel.transform.localRotation = screenRotation;
        bezel.transform.localScale = new Vector3(p.screenWidth + 0.5f, p.screenHeight + 0.5f, 0.06f);

        Material bezelMaterial = new Material(Shader.Find("Standard")) { color = new Color(0.03f, 0.03f, 0.035f) };
        if (bezelMaterial.HasProperty("_Glossiness")) bezelMaterial.SetFloat("_Glossiness", 0.1f);
        bezel.GetComponent<Renderer>().sharedMaterial = bezelMaterial;
    }

    /// <summary>Soft light in front of the screen, aimed back at the seating area, so the
    /// front rows are gently lit as if by the screen itself (spec section 6).</summary>
    private static void BuildScreenGlowLight(Transform parent, VenueParameters p, float centerY)
    {
        GameObject lightGo = new GameObject("ScreenGlowLight");
        lightGo.transform.SetParent(parent, false);
        Quaternion screenRotation = Quaternion.Euler(0f, p.screenRotationY, 0f);
        // Position 1.0m in front of the screen (+Z along screen orientation)
        Vector3 inFront = screenRotation * new Vector3(0f, 0f, 1.0f);
        lightGo.transform.localPosition =
            new Vector3(p.screenOffsetX, centerY, p.screenDistanceFromFrontWall) + inFront;
        // Aim forward into the auditorium seating area (+Z) rather than backward into the screen.
        lightGo.transform.localRotation = screenRotation;

        Light light = lightGo.AddComponent<Light>();
        light.type = LightType.Spot;
        light.color = new Color(0.75f, 0.82f, 1f);
        light.intensity = p.screenGlowIntensity;
        light.range = p.firstRowDistanceFromScreen + 8f;
        light.spotAngle = 90f;
    }
}
