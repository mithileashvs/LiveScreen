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

        float centerY = p.screenHeightFromFloor + (p.screenHeight / 2f);

        screen.transform.localPosition = new Vector3(0, centerY, p.screenDistanceFromFrontWall);
        screen.transform.localScale = new Vector3(p.screenWidth, p.screenHeight, 0.05f);

        Material screenMaterial = new Material(Shader.Find("Standard")) { color = new Color(0.9f, 0.9f, 0.95f) };
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
        bezel.transform.localPosition = new Vector3(0, centerY, p.screenDistanceFromFrontWall - 0.03f);
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
        lightGo.transform.localPosition = new Vector3(0, centerY, p.screenDistanceFromFrontWall + 0.5f);
        lightGo.transform.localRotation = Quaternion.Euler(0f, 180f, 0f); // aim back into the auditorium

        Light light = lightGo.AddComponent<Light>();
        light.type = LightType.Spot;
        light.color = new Color(0.75f, 0.82f, 1f);
        light.intensity = p.screenGlowIntensity;
        light.range = p.firstRowDistanceFromScreen + 8f;
        light.spotAngle = 100f;
    }
}
