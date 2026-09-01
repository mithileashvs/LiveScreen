using UnityEngine;

/// <summary>
/// Builds the cinema screen — a simple placeholder plane for Phase 2.
/// In a later phase this will display an actual trailer.
/// </summary>
public static class ScreenGenerator
{
    public static void Generate(Transform parent, VenueParameters p)
    {
        GameObject screen = GameObject.CreatePrimitive(PrimitiveType.Cube);
        screen.name = "Screen";
        screen.transform.SetParent(parent, false);

        // Positioned just in front of the front wall (Z = distance from front wall),
        // centred left-right (X = 0), raised off the floor by screenHeightFromFloor.
        float centerY = p.screenHeightFromFloor + (p.screenHeight / 2f);

        screen.transform.localPosition = new Vector3(0, centerY, p.screenDistanceFromFrontWall);
        screen.transform.localScale = new Vector3(p.screenWidth, p.screenHeight, 0.05f);

        var renderer = screen.GetComponent<Renderer>();
        renderer.material.color = new Color(0.9f, 0.9f, 0.95f); // bright placeholder "screen"
    }
}
