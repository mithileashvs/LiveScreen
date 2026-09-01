using UnityEngine;

/// <summary>
/// Builds the floor, walls, and ceiling of the auditorium purely from
/// VenueParameters. No dimensions are hard-coded — change roomLength,
/// roomWidth, or roomHeight and this scales automatically.
///
/// Coordinate convention used across all generators:
///   X = left/right (width)
///   Y = up/down (height)
///   Z = front/back (length) — Z = 0 is the front wall (where the screen is)
/// </summary>
public static class RoomGenerator
{
    public static void Generate(Transform parent, VenueParameters p)
    {
        GameObject room = new GameObject("Room");
        room.transform.SetParent(parent, false);

        float halfWidth = p.roomWidth / 2f;

        // Floor
        CreateBox(room.transform, "Floor",
            new Vector3(0, 0, p.roomLength / 2f),
            new Vector3(p.roomWidth, 0.1f, p.roomLength),
            new Color(0.15f, 0.15f, 0.18f));

        // Ceiling
        CreateBox(room.transform, "Ceiling",
            new Vector3(0, p.roomHeight, p.roomLength / 2f),
            new Vector3(p.roomWidth, 0.1f, p.roomLength),
            new Color(0.08f, 0.08f, 0.1f));

        // Front wall (where the screen sits)
        CreateBox(room.transform, "FrontWall",
            new Vector3(0, p.roomHeight / 2f, 0),
            new Vector3(p.roomWidth, p.roomHeight, 0.1f),
            new Color(0.1f, 0.1f, 0.12f));

        // Back wall
        CreateBox(room.transform, "BackWall",
            new Vector3(0, p.roomHeight / 2f, p.roomLength),
            new Vector3(p.roomWidth, p.roomHeight, 0.1f),
            new Color(0.1f, 0.1f, 0.12f));

        // Left wall
        CreateBox(room.transform, "LeftWall",
            new Vector3(-halfWidth, p.roomHeight / 2f, p.roomLength / 2f),
            new Vector3(0.1f, p.roomHeight, p.roomLength),
            new Color(0.12f, 0.12f, 0.15f));

        // Right wall
        CreateBox(room.transform, "RightWall",
            new Vector3(halfWidth, p.roomHeight / 2f, p.roomLength / 2f),
            new Vector3(0.1f, p.roomHeight, p.roomLength),
            new Color(0.12f, 0.12f, 0.15f));
    }

    private static void CreateBox(Transform parent, string name, Vector3 position, Vector3 size, Color color)
    {
        GameObject box = GameObject.CreatePrimitive(PrimitiveType.Cube);
        box.name = name;
        box.transform.SetParent(parent, false);
        box.transform.localPosition = position;
        box.transform.localScale = size;

        var renderer = box.GetComponent<Renderer>();
        renderer.material.color = color;
    }
}
