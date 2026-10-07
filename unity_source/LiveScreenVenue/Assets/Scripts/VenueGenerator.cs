using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// The main entry point for Phase 2. Holds the current venue parameters,
/// and is responsible for clearing any previously generated venue and
/// building a new one from scratch whenever Generate() is called.
///
/// Attach this to a single empty GameObject in your scene (e.g. "VenueManager").
/// </summary>
public class VenueGenerator : MonoBehaviour
{
    public static VenueGenerator Instance { get; private set; }

    public VenueParameters Parameters = new VenueParameters();

    /// <summary>
    /// The specific theatre's saved configuration, once Flutter has sent
    /// it. Null means no theatre configuration was supplied — only then is
    /// this scene's own VenueParameters legitimately the source of truth
    /// (a brand-new theatre with nothing configured, or the in-editor
    /// generator panel).
    /// </summary>
    public TheatreConfigPayload Configuration { get; private set; }

    /// <summary>
    /// Set by FlutterBridge during Awake in real (WebGL) builds, BEFORE any
    /// Start runs. When true, Start does not immediately build a venue.
    ///
    /// This is what stops the scene's default room from being generated and
    /// briefly shown while Flutter's real theatre configuration is still in
    /// flight — the "old demo theatre" a user would see flash up (and would
    /// keep seeing entirely if the configuration never arrived).
    /// </summary>
    public static bool DeferInitialGenerate;

    [Tooltip("How long to wait for Flutter to send a theatre configuration " +
             "before giving up and building from this scene's own defaults. " +
             "Only relevant when DeferInitialGenerate is set. Keeps the " +
             "older demo-data flow (which sends no configuration at all) " +
             "working instead of leaving it on a permanently empty screen.")]
    public float configurationWaitTimeoutSeconds = 4f;

    [HideInInspector] public List<SeatData> GeneratedSeats = new List<SeatData>();
    [HideInInspector] public SeatData SelectedSeat;
    [HideInInspector] public bool HasGeneratedOnce;

    /// <summary>The generated Screen object's transform — used by the Phase 3
    /// experience camera to calculate which direction seats should look.</summary>
    public Transform ScreenTransform { get; private set; }

    private Transform _venueRoot;
    private SeatController _selectedController;

    private void Awake()
    {
        Instance = this;
    }

    private void Start()
    {
        if (DeferInitialGenerate)
        {
            // Wait for the real theatre configuration rather than showing
            // this scene's defaults in the meantime.
            StartCoroutine(WaitForConfigurationThenGenerate());
            return;
        }

        // Editor / no-bridge case: build the default venue immediately so
        // there's something to see and tune.
        Generate();
    }

    private IEnumerator WaitForConfigurationThenGenerate()
    {
        float waited = 0f;
        while (Configuration == null && waited < configurationWaitTimeoutSeconds)
        {
            waited += Time.unscaledDeltaTime;
            yield return null;
        }

        if (Configuration == null && !HasGeneratedOnce)
        {
            Debug.LogWarning(
                "[VenueGenerator] No theatre configuration arrived within " +
                $"{configurationWaitTimeoutSeconds}s — falling back to this scene's " +
                "default parameters. If a theatre WAS selected, its configuration " +
                "did not reach Unity; check UnityExperienceScreen is being given a " +
                "TheatreConfiguration.");
            Generate();
        }
    }

    /// <summary>
    /// Copies a specific theatre's saved configuration onto this scene's
    /// parameters and rebuilds. Only the fields the theatre actually
    /// defines are overwritten — lighting, aisles, headroom, eye heights
    /// and the other scene-tuning values keep their configured values,
    /// since no theatre owner sets those.
    /// </summary>
    public void ApplyConfiguration(TheatreConfigPayload payload)
    {
        if (payload == null)
        {
            Debug.LogWarning("[VenueGenerator] ApplyConfiguration called with null payload — ignoring.");
            return;
        }

        Configuration = payload;
        VenueParameters p = Parameters;

        // Room. Guarded with > 0 so a payload missing a field (an older or
        // partially-populated theatre) leaves the existing value alone
        // rather than collapsing the room to zero.
        bool gotWidth = payload.roomWidth > 0f;
        bool gotLength = payload.roomLength > 0f;
        bool gotHeight = payload.roomHeight > 0f;
        if (gotWidth) p.roomWidth = payload.roomWidth;
        if (gotLength) p.roomLength = payload.roomLength;
        if (gotHeight) p.roomHeight = payload.roomHeight;

        // Marks these dimensions as the owner's, which stops RoomGenerator
        // from enlarging them behind the owner's back (see
        // RoomGenerator.EnsureRoomFitsSeating).
        p.ownerConfiguredRoom = gotWidth && gotLength && gotHeight;

        // Screen
        if (payload.screenWidth > 0f) p.screenWidth = payload.screenWidth;
        if (payload.screenHeight > 0f) p.screenHeight = payload.screenHeight;
        p.screenOffsetX = payload.screenOffsetX;
        p.screenCenterY = payload.screenCenterY;
        p.screenRotationY = payload.screenRotationY;
        if (payload.screenDistanceFromFrontWall > 0f)
        {
            p.screenDistanceFromFrontWall = payload.screenDistanceFromFrontWall;
        }

        // Seating layout
        if (payload.rows > 0) p.rows = payload.rows;
        if (payload.seatsPerRow > 0) p.seatsPerRow = payload.seatsPerRow;
        if (payload.seatSpacing > 0f) p.seatSpacing = payload.seatSpacing;
        if (payload.rowSpacing > 0f) p.rowSpacing = payload.rowSpacing;
        if (payload.seatWidth > 0f) p.seatWidth = payload.seatWidth;
        if (payload.firstRowDistanceFromScreen > 0f)
        {
            p.firstRowDistanceFromScreen = payload.firstRowDistanceFromScreen;
        }
        p.rowRisePerRow = payload.rowRisePerRow;

        Generate();
    }

    /// <summary>
    /// Clears whatever venue currently exists and builds a brand new one
    /// from the current Parameters. Call this after changing any values.
    /// </summary>
    public void Generate()
    {
        // The screen this may be playing on is about to be destroyed and
        // rebuilt from scratch — stop first, or TrailerScreenPlayer would
        // be left holding a reference to a destroyed Material/Renderer
        // (and its VideoPlayer would keep decoding into a RenderTexture
        // nothing is displaying anymore).
        if (TrailerScreenPlayer.Instance != null)
        {
            TrailerScreenPlayer.Instance.Stop();
        }

        ClearExistingVenue();

        GameObject root = new GameObject("GeneratedVenue");
        root.transform.SetParent(transform, false);
        _venueRoot = root.transform;

        RoomGenerator.Generate(_venueRoot, Parameters);
        GameObject screenObj = ScreenGenerator.Generate(_venueRoot, Parameters);
        ScreenTransform = screenObj.transform;

        // Place the theatre's ACTUAL saved seats when it has them; only
        // fall back to deriving a grid when no configuration exists.
        GeneratedSeats = SeatGenerator.Generate(
            _venueRoot, Parameters, Configuration != null ? Configuration.seats : null);

        // Generate visual-only cinema speakers at the theatre's saved positions
        SpeakerGenerator.Generate(
            _venueRoot, Parameters, Configuration != null ? Configuration.speakers : null);

        SelectedSeat = null;
        _selectedController = null;
        HasGeneratedOnce = true;

        // Rebuild the speaker rig against the venue that now exists. This
        // is why speakers used to stay on the demo layout: the rig was
        // built once in SpatialAudioManager.Start and never rebuilt, so
        // regenerating the venue left the old speakers behind.
        if (SpatialAudioManager.Instance != null)
        {
            SpatialAudioManager.Instance.RebuildForCurrentVenue(_venueRoot);
        }

        string source = Configuration == null
            ? "scene defaults (no theatre configuration supplied)"
            : $"theatre '{Configuration.theatreName}' ({Configuration.theatreId})";
        Debug.Log(
            $"[VenueGenerator] Venue generated from {source}: " +
            $"room {Parameters.roomWidth}x{Parameters.roomLength}x{Parameters.roomHeight}m, " +
            $"screen {Parameters.screenWidth}x{Parameters.screenHeight}m, " +
            $"{GeneratedSeats.Count} seats.");
    }

    private void ClearExistingVenue()
    {
        if (_venueRoot != null)
        {
            // Deactivate and rename BEFORE the deferred Destroy. Destroy
            // only takes effect at the end of the frame, so without this
            // the previous theatre's geometry is still present (and still
            // rendering, and still hit-testable for seat clicks) alongside
            // the newly generated one for the remainder of this frame —
            // which reads as "the old theatre is still there".
            _venueRoot.gameObject.SetActive(false);
            _venueRoot.gameObject.name = "GeneratedVenue_Discarded";
            Destroy(_venueRoot.gameObject);
            _venueRoot = null;
        }
    }

    public void SelectSeat(SeatController controller)
    {
        // Un-highlight whatever was selected before.
        if (_selectedController != null)
        {
            _selectedController.SetHighlighted(false);
        }

        // If the user clicked the same seat again, deselect it entirely.
        if (_selectedController == controller)
        {
            _selectedController = null;
            SelectedSeat = null;
            return;
        }

        controller.SetHighlighted(true);
        _selectedController = controller;
        SelectedSeat = controller.Seat;

        Debug.Log($"Selected {SelectedSeat.Id} at {SelectedSeat.Position}");
    }

    /// <summary>
    /// Finds a generated seat by its ID (e.g. "G12"). This will be the entry
    /// point a future Flutter-to-Unity bridge uses: Flutter sends a seat ID,
    /// Unity looks it up here to know exactly where to put the camera.
    /// </summary>
    public SeatData FindSeatById(string seatId)
    {
        return GeneratedSeats.Find(s => s.Id == seatId);
    }
}
