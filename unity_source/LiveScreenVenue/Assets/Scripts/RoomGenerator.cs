using UnityEngine;

/// <summary>
/// Builds the floor, walls, ceiling, floor risers, and architectural
/// lighting of the auditorium purely from VenueParameters. No dimensions
/// are hard-coded — change roomLength, roomWidth, or roomHeight and this
/// scales automatically.
///
/// Coordinate convention used across all generators:
///   X = left/right (width)
///   Y = up/down (height)
///   Z = front/back (length) — Z = 0 is the front wall (where the screen is)
///
/// Phase 4 changes (immersive theatre pass): the room now auto-expands to
/// always fully enclose the generated seating (see EnsureRoomFitsSeating),
/// gained stepped floor risers under each row so seats aren't floating
/// above a flat plane, and gained recessed ceiling lights + wall paneling +
/// aisle lighting so it reads as a real cinema instead of an empty box.
/// </summary>
public static class RoomGenerator
{
    /// <summary>
    /// The wall material's base color, exposed so other systems (currently
    /// just OrbitCamera's background) can match it exactly rather than
    /// duplicating the literal — keeps "the exterior looks the same as the
    /// walls" from silently drifting out of sync if either value changes.
    /// </summary>
    public static readonly Color WallColor = new Color(0.11f, 0.10f, 0.13f);

    /// <summary>Outcome of the most recent room-vs-seating check. Read by
    /// FlutterBridge so an undersized real theatre is reported to Flutter
    /// rather than quietly corrected.</summary>
    public static RoomFitReport LastFitReport;

    private static Material _floorMaterial;
    private static Material _ceilingMaterial;
    private static Material _wallMaterial;
    private static Material _panelMaterial;
    private static Material _fixtureMaterial;

    public static void Generate(Transform parent, VenueParameters p)
    {
        EnsureRoomFitsSeating(p);
        ConfigureAmbientLighting();

        GameObject room = new GameObject("Room");
        room.transform.SetParent(parent, false);

        float halfWidth = p.roomWidth / 2f;

        // Floor
        CreateBox(room.transform, "Floor",
            new Vector3(0, 0, p.roomLength / 2f),
            new Vector3(p.roomWidth, 0.1f, p.roomLength),
            GetFloorMaterial());

        BuildFloorRisers(room.transform, p);

        // Ceiling — this single slab is what guarantees no open sky is ever
        // visible; EnsureRoomFitsSeating() above guarantees it's always
        // large enough and high enough to fully cover the seating area.
        CreateBox(room.transform, "Ceiling",
            new Vector3(0, p.roomHeight, p.roomLength / 2f),
            new Vector3(p.roomWidth, 0.1f, p.roomLength),
            GetCeilingMaterial());

        // Front wall (where the screen sits)
        CreateBox(room.transform, "FrontWall",
            new Vector3(0, p.roomHeight / 2f, 0),
            new Vector3(p.roomWidth, p.roomHeight, 0.1f),
            GetWallMaterial());

        // Back wall
        CreateBox(room.transform, "BackWall",
            new Vector3(0, p.roomHeight / 2f, p.roomLength),
            new Vector3(p.roomWidth, p.roomHeight, 0.1f),
            GetWallMaterial());

        // Left wall
        CreateBox(room.transform, "LeftWall",
            new Vector3(-halfWidth, p.roomHeight / 2f, p.roomLength / 2f),
            new Vector3(0.1f, p.roomHeight, p.roomLength),
            GetWallMaterial());

        // Right wall
        CreateBox(room.transform, "RightWall",
            new Vector3(halfWidth, p.roomHeight / 2f, p.roomLength / 2f),
            new Vector3(0.1f, p.roomHeight, p.roomLength),
            GetWallMaterial());

        BuildWallPaneling(room.transform, p, -halfWidth, "Left");
        BuildWallPaneling(room.transform, p, halfWidth, "Right");
        BuildAisleLighting(room.transform, p, -halfWidth, "Left");
        BuildAisleLighting(room.transform, p, halfWidth, "Right");
        BuildCeilingLights(room.transform, p);
    }

    /// <summary>
    /// Guarantees the room is always at least big enough to enclose every
    /// seat this venue will generate, plus a safety margin (spec's #1
    /// requirement — no visible sky, under ANY parameter combination, not
    /// just the current defaults). Mutates p in place; VenueGeneratorUI
    /// re-syncs its display fields after Generate() so the owner can see if
    /// their entered numbers were too small and got auto-expanded.
    /// </summary>
    /// <summary>
    /// Checks the room against the space the seating and screen actually
    /// need.
    ///
    /// This used to unconditionally do `p.roomWidth = Mathf.Max(...)` — it
    /// silently rewrote the theatre owner's configured dimensions, and
    /// because VenueParameters is a long-lived object those expansions
    /// ACCUMULATED across regenerations, so a room could drift further from
    /// its saved size every time the venue was rebuilt.
    ///
    /// Now: when the dimensions came from an owner's saved configuration
    /// (<see cref="VenueParameters.ownerConfiguredRoom"/>) they are
    /// authoritative and left exactly as saved, and the mismatch is recorded
    /// in <see cref="LastFitReport"/> so FlutterBridge can report it as a
    /// configuration problem. Auto-expansion is kept only for the in-editor
    /// generator panel and the demo flow, where nobody's saved configuration
    /// is at stake.
    ///
    /// The room stays a fully closed box either way — walls, floor and
    /// ceiling are still built at whatever dimensions are in effect — so an
    /// undersized room shows seats intersecting the shell, not open skybox.
    /// </summary>
    private static void EnsureRoomFitsSeating(VenueParameters p)
    {
        Vector3 required = SeatGenerator.EstimateRequiredRoomBounds(p);

        bool fits = p.roomWidth >= required.x
                 && p.roomLength >= required.z
                 && p.roomHeight >= required.y;

        LastFitReport = new RoomFitReport
        {
            Fits = fits,
            OwnerConfigured = p.ownerConfiguredRoom,
            ConfiguredWidth = p.roomWidth,
            ConfiguredHeight = p.roomHeight,
            ConfiguredLength = p.roomLength,
            RequiredWidth = required.x,
            RequiredHeight = required.y,
            RequiredLength = required.z,
        };

        if (fits) return;

        if (p.ownerConfiguredRoom)
        {
            Debug.LogError(
                "[RoomGenerator] This theatre's saved room is too small for its saved " +
                $"seating/screen. Configured {p.roomWidth:F1}x{p.roomHeight:F1}x{p.roomLength:F1} " +
                $"(W x H x L), needs at least {required.x:F1}x{required.y:F1}x{required.z:F1}. " +
                "The saved dimensions are being honoured as-is - fix the theatre's Room or " +
                "Seating configuration rather than expecting Unity to enlarge it silently.");
            return;
        }

        Debug.Log(
            "[RoomGenerator] Room auto-expanded to enclose the seating layout " +
            $"({p.roomWidth:F1}x{p.roomHeight:F1}x{p.roomLength:F1} -> " +
            $"{Mathf.Max(p.roomWidth, required.x):F1}x{Mathf.Max(p.roomHeight, required.y):F1}x" +
            $"{Mathf.Max(p.roomLength, required.z):F1}). Only taken when these are NOT an " +
            "owner's saved dimensions.");

        p.roomWidth = Mathf.Max(p.roomWidth, required.x);
        p.roomHeight = Mathf.Max(p.roomHeight, required.y);
        p.roomLength = Mathf.Max(p.roomLength, required.z);
    }

    /// <summary>Low, cool, indoor ambient light instead of Unity's default skybox-driven
    /// ambient — this is atmosphere, not a substitute for the real enclosing geometry above.</summary>
    private static void ConfigureAmbientLighting()
    {
        RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
        RenderSettings.ambientLight = new Color(0.045f, 0.045f, 0.06f);

        // Cinema auditorium is an enclosed indoor venue — ensure outdoor sunlight is off
        foreach (Light l in Object.FindObjectsByType<Light>(FindObjectsInactive.Exclude, FindObjectsSortMode.None))
        {
            if (l.type == LightType.Directional)
            {
                l.enabled = false;
            }
        }
    }

    /// <summary>
    /// Builds a solid stepped platform under every row that has any rise
    /// (rowRisePerRow > 0), using the EXACT same per-row depth/height formulas
    /// SeatGenerator uses for the seats themselves — so the ground a row sits
    /// on and the row's seats can never drift out of sync (spec sections 5, 9, 10).
    /// </summary>
    private static void BuildFloorRisers(Transform parent, VenueParameters p)
    {
        if (p.rowRisePerRow <= 0f || p.rows <= 1) return; // flat floor, nothing to riser

        GameObject risers = new GameObject("Risers");
        risers.transform.SetParent(parent, false);

        for (int rowIndex = 1; rowIndex < p.rows; rowIndex++)
        {
            float rowHeight = SeatGenerator.ComputeRowHeight(rowIndex, p);
            float rowDepth = SeatGenerator.ComputeRowDepth(rowIndex, p);

            // Depth chosen to touch the previous and next riser edge-to-edge,
            // so there's no visible gap between steps.
            CreateBox(risers.transform, $"Riser_Row{rowIndex}",
                new Vector3(0, rowHeight / 2f, rowDepth),
                new Vector3(p.roomWidth * 0.94f, rowHeight, p.rowSpacing),
                GetFloorMaterial());
        }
    }

    /// <summary>Vertical acoustic-panel grooves along a side wall (spec section 3).</summary>
    private static void BuildWallPaneling(Transform parent, VenueParameters p, float wallX, string side)
    {
        if (p.wallPanelSpacing <= 0f) return;

        GameObject panels = new GameObject($"{side}WallPanels");
        panels.transform.SetParent(parent, false);

        // Panels face inward, offset slightly off the wall surface.
        float inwardOffset = wallX > 0 ? -0.06f : 0.06f;
        int count = Mathf.Max(1, Mathf.FloorToInt(p.roomLength / p.wallPanelSpacing));

        for (int i = 0; i < count; i++)
        {
            float z = (i + 0.5f) * p.wallPanelSpacing;
            if (z >= p.roomLength) break;

            CreateBox(panels.transform, $"Panel_{i}",
                new Vector3(wallX + inwardOffset, p.roomHeight * 0.55f, z),
                new Vector3(0.06f, p.roomHeight * 0.7f, 0.5f),
                GetPanelMaterial());
        }
    }

    /// <summary>Small warm floor-level marker lights along a side wall's aisle (spec section 6).</summary>
    // Real-time Lights are expensive in WebGL (no deferred rendering
    // available, so every light adds a full extra shading pass on
    // everything it touches). The original spacing-based counts scaled
    // linearly with room size with NO upper bound — a large real theatre
    // (e.g. 20 rows, ~26m long) produced 22 aisle lights + 12 ceiling
    // lights = 34 simultaneous real-time point lights, on top of ~3000
    // unbatched seat-part renderers for 500 seats. That combination is
    // almost certainly what was exhausting the GPU and causing a WebGL
    // context loss (which Chrome/the OS sometimes recovers from by
    // reloading the tab) once a real, large admin-configured theatre
    // loaded instead of a small test one. These caps keep the light count
    // bounded regardless of how big the configured room is; going wider
    // just spreads the same fixed number of fixtures further apart.
    private const int MaxCeilingLightRows = 5;  // x2 columns = 10 lights max
    private const int MaxAisleLightsPerSide = 6; // x2 sides = 12 lights max

    private static void BuildAisleLighting(Transform parent, VenueParameters p, float wallX, string side)
    {
        if (p.aisleLightSpacing <= 0f) return;

        GameObject lights = new GameObject($"{side}AisleLights");
        lights.transform.SetParent(parent, false);

        float inwardOffset = wallX > 0 ? -0.2f : 0.2f;
        int desiredCount = Mathf.Max(1, Mathf.FloorToInt(p.roomLength / p.aisleLightSpacing));
        int count = Mathf.Min(desiredCount, MaxAisleLightsPerSide);
        float effectiveSpacing = p.roomLength / count;

        for (int i = 0; i < count; i++)
        {
            float z = (i + 0.5f) * effectiveSpacing;

            Vector3 pos = new Vector3(wallX + inwardOffset, 0.15f, z);

            CreateBox(lights.transform, $"AisleFixture_{i}", pos, Quaternion.identity,
                new Vector3(0.10f, 0.05f, 0.10f), GetFixtureMaterial());

            GameObject lightGo = new GameObject($"AisleLight_{i}");
            lightGo.transform.SetParent(lights.transform, false);
            lightGo.transform.localPosition = pos;
            Light light = lightGo.AddComponent<Light>();
            light.type = LightType.Point;
            light.color = p.aisleLightColor;
            light.intensity = p.aisleLightIntensity;
            light.range = Mathf.Max(2f, effectiveSpacing);
        }
    }

    /// <summary>Recessed ceiling downlights in a grid across the auditorium (spec section 2).</summary>
    private static void BuildCeilingLights(Transform parent, VenueParameters p)
    {
        if (p.ceilingLightSpacing <= 0f) return;

        GameObject lights = new GameObject("CeilingLights");
        lights.transform.SetParent(parent, false);

        float halfWidth = p.roomWidth / 2f;
        float[] columnsX = { -halfWidth * 0.5f, halfWidth * 0.5f };
        int desiredRows = Mathf.Max(1, Mathf.FloorToInt(p.roomLength / p.ceilingLightSpacing));
        int rowsOfLights = Mathf.Min(desiredRows, MaxCeilingLightRows);
        float effectiveSpacing = p.roomLength / rowsOfLights;
        float fixtureY = p.roomHeight - 0.08f; // recessed just below the ceiling slab

        int index = 0;
        for (int i = 0; i < rowsOfLights; i++)
        {
            float z = (i + 0.5f) * effectiveSpacing;

            foreach (float x in columnsX)
            {
                Vector3 pos = new Vector3(x, fixtureY, z);

                CreateBox(lights.transform, $"CeilingFixture_{index}", pos, Quaternion.identity,
                    new Vector3(0.5f, 0.05f, 0.5f), GetFixtureMaterial());

                GameObject lightGo = new GameObject($"CeilingLight_{index}");
                lightGo.transform.SetParent(lights.transform, false);
                lightGo.transform.localPosition = pos;
                Light light = lightGo.AddComponent<Light>();
                light.type = LightType.Point;
                light.color = p.ceilingLightColor;
                light.intensity = p.ceilingLightIntensity;
                light.range = effectiveSpacing * 1.3f;

                index++;
            }
        }
    }

    private static void CreateBox(Transform parent, string name, Vector3 position, Vector3 size, Material sharedMaterial)
    {
        CreateBox(parent, name, position, Quaternion.identity, size, sharedMaterial);
    }

    private static void CreateBox(Transform parent, string name, Vector3 position, Quaternion rotation, Vector3 size, Material sharedMaterial)
    {
        GameObject box = GameObject.CreatePrimitive(PrimitiveType.Cube);
        box.name = name;
        box.transform.SetParent(parent, false);
        box.transform.localPosition = position;
        box.transform.localRotation = rotation;
        box.transform.localScale = size;

        var renderer = box.GetComponent<Renderer>();
        renderer.sharedMaterial = sharedMaterial; // shared, not .material — batching-friendly (spec section 12)
    }

    private static Material GetFloorMaterial()
    {
        if (_floorMaterial != null) return _floorMaterial;
        _floorMaterial = BuildMaterial(new Color(0.10f, 0.09f, 0.11f), glossiness: 0.15f, metallic: 0f); // dark theatre carpet
        return _floorMaterial;
    }

    private static Material GetCeilingMaterial()
    {
        if (_ceilingMaterial != null) return _ceilingMaterial;
        _ceilingMaterial = BuildMaterial(new Color(0.07f, 0.07f, 0.085f), glossiness: 0.1f, metallic: 0f); // dark acoustic panel
        return _ceilingMaterial;
    }

    private static Material GetWallMaterial()
    {
        if (_wallMaterial != null) return _wallMaterial;
        _wallMaterial = BuildMaterial(WallColor, glossiness: 0.12f, metallic: 0f); // acoustic fabric wall
        return _wallMaterial;
    }

    private static Material GetPanelMaterial()
    {
        if (_panelMaterial != null) return _panelMaterial;
        _panelMaterial = BuildMaterial(new Color(0.16f, 0.14f, 0.19f), glossiness: 0.2f, metallic: 0f); // slightly lighter groove accent
        return _panelMaterial;
    }

    private static Material GetFixtureMaterial()
    {
        if (_fixtureMaterial != null) return _fixtureMaterial;
        _fixtureMaterial = BuildMaterial(new Color(0.9f, 0.9f, 0.85f), glossiness: 0.6f, metallic: 0.1f); // small visible light housing
        if (_fixtureMaterial.HasProperty("_EmissionColor"))
        {
            _fixtureMaterial.EnableKeyword("_EMISSION");
            _fixtureMaterial.SetColor("_EmissionColor", new Color(0.6f, 0.6f, 0.55f));
        }
        return _fixtureMaterial;
    }

    private static Material BuildMaterial(Color color, float glossiness, float metallic)
    {
        Material mat = new Material(Shader.Find("Standard")) { color = color };
        if (mat.HasProperty("_Glossiness")) mat.SetFloat("_Glossiness", glossiness);
        if (mat.HasProperty("_Metallic")) mat.SetFloat("_Metallic", metallic);
        return mat;
    }
}

/// <summary>Result of checking a room against the space its seating and
/// screen need. Purely descriptive - it changes nothing on its own.</summary>
public struct RoomFitReport
{
    public bool Fits;
    public bool OwnerConfigured;
    public float ConfiguredWidth;
    public float ConfiguredHeight;
    public float ConfiguredLength;
    public float RequiredWidth;
    public float RequiredHeight;
    public float RequiredLength;

    /// <summary>A short, colon-free summary safe to embed in the
    /// colon-delimited messages sent to Flutter.</summary>
    public string Summary =>
        $"configured {ConfiguredWidth:F1}x{ConfiguredHeight:F1}x{ConfiguredLength:F1}" +
        $" needs {RequiredWidth:F1}x{RequiredHeight:F1}x{RequiredLength:F1}";
}
