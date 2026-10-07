using System.Runtime.InteropServices;
using UnityEngine;

/// <summary>
/// The single point of contact between Flutter and Unity.
///
/// FROM Flutter: Flutter calls ExperienceSeatById(seatId) via
/// unityInstance.SendMessage("FlutterBridge", "ExperienceSeatById", "G12").
///
/// TO Flutter: this script calls SendMessageToFlutter(...) (defined in the
/// FlutterBridge.jslib file) whenever something happens that Flutter needs
/// to know about, like the user exiting the experience.
///
/// Attach this to the same "VenueManager" GameObject as the other scripts.
/// The exact name "FlutterBridge" matters — it's the object name Flutter's
/// SendMessage calls will target.
/// </summary>
public class FlutterBridge : MonoBehaviour
{
    // These "extern" methods don't have C# code behind them — at runtime in
    // a real browser, they call straight into the JavaScript function of
    // the same name defined in FlutterBridge.jslib. In the Unity Editor
    // (not a real browser), calling them does nothing, which is why every
    // call below is wrapped in the UNITY_WEBGL check.
#if UNITY_WEBGL && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern void SendMessageToFlutter(string message);
#endif

    private void Awake()
    {
        gameObject.name = "FlutterBridge";

        // Runtime-added rather than requiring a manual Editor step to drop
        // it onto this (or any) GameObject — same object FlutterBridge
        // lives on is a convenient, already-persistent home for it.
        if (GetComponent<TrailerScreenPlayer>() == null)
        {
            gameObject.AddComponent<TrailerScreenPlayer>();
        }

        // Tell VenueGenerator not to build this scene's default venue on
        // Start. In a real build, Flutter is about to send this theatre's
        // configuration; generating first would show the scene's default
        // room (the "old demo theatre") for the moment in between — and
        // permanently, if the configuration never arrived.
        //
        // Guarded to WebGL so the Unity Editor still builds a venue
        // immediately for the in-editor generator panel, which has no
        // Flutter to talk to.
#if UNITY_WEBGL && !UNITY_EDITOR
        VenueGenerator.DeferInitialGenerate = true;
#endif
    }

    private void Start()
    {
        NotifyFlutter("unity_ready");
    }

    /// <summary>
    /// Called by Flutter (via load_configuration:&lt;json&gt;) before
    /// ExperienceSeatById, when a real TheatreConfiguration exists — see
    /// TheatreUnityBridge.toUnityVenueParametersJson on the Dart side for
    /// exactly what's in the JSON and why.
    ///
    /// Overwrites the room/screen/seating fields the theatre actually
    /// defines, and places the theatre's OWN saved seats and speakers;
    /// everything else this scene has configured (lighting, aisle count,
    /// headroom, eye heights, etc.) is left alone, since no theatre owner
    /// configures those.
    /// Regenerates the venue afterward so the change actually takes visual
    /// effect, then acks so Flutter knows it's safe to send the seat
    /// command — sending the seat command before this finishes could have
    /// the camera arrive at a seat position computed from the WRONG,
    /// stale room dimensions.
    /// </summary>
    public void LoadConfiguration(string json)
    {
        Debug.Log($"[FlutterBridge] Received theatre configuration: {json}");

        VenueGenerator venueGenerator = VenueGenerator.Instance;
        if (venueGenerator == null)
        {
            Debug.LogError("[FlutterBridge] No VenueGenerator found — cannot apply configuration.");
            NotifyFlutter("configuration_failed:no_venue_generator");
            return;
        }

        TheatreConfigPayload payload;
        try
        {
            payload = JsonUtility.FromJson<TheatreConfigPayload>(json);
        }
        catch (System.Exception e)
        {
            // Previously this warned and then acked 'configuration_loaded'
            // anyway, so Flutter believed the theatre had been applied and
            // went straight to the seat command — leaving the user in the
            // scene's default room with no indication anything had failed.
            // Failures are now reported as failures.
            Debug.LogError($"[FlutterBridge] Could not parse configuration JSON: {e.Message}");
            NotifyFlutter("configuration_failed:parse_error");
            return;
        }

        if (payload == null || string.IsNullOrEmpty(payload.theatreId))
        {
            Debug.LogError("[FlutterBridge] Configuration JSON parsed to null or had no theatreId.");
            NotifyFlutter("configuration_failed:empty_payload");
            return;
        }

        venueGenerator.ApplyConfiguration(payload);

        int seatCount = venueGenerator.GeneratedSeats != null ? venueGenerator.GeneratedSeats.Count : 0;
        int speakerCount = SpatialAudioManager.Instance != null
            ? SpatialAudioManager.Instance.SpeakerCount
            : 0;

        Debug.Log(
            $"[FlutterBridge] Applied theatre '{payload.theatreName}' ({payload.theatreId}): " +
            $"{seatCount} seats, {speakerCount} speakers.");

        // The ack carries the theatre ID and the counts back, so Flutter (and
        // anyone reading the browser console) can verify that the theatre
        // Unity actually built is the theatre that was requested — rather
        // than having to take a bare 'configuration_loaded' on faith.
        NotifyFlutter($"configuration_loaded:{payload.theatreId}:{seatCount}:{speakerCount}");

        // A theatre whose saved room cannot contain its saved seating is a
        // configuration problem the owner needs to fix, not something to
        // paper over. Reported AFTER the ack so it never blocks the user
        // from entering the experience — the venue is still generated, at
        // the owner's own dimensions.
        RoomFitReport fit = RoomGenerator.LastFitReport;
        if (!fit.Fits && fit.OwnerConfigured)
        {
            NotifyFlutter($"configuration_warning:room_too_small:{fit.Summary}");
        }
    }

    /// <summary>
    /// Called by Flutter when the user taps "Experience This Seat" on a
    /// given seat ID. Reuses the exact same VenueGenerator/ExperienceController
    /// systems Phase 2 and 3 already built — no duplicate logic here.
    /// </summary>
    public void ExperienceSeatById(string seatId)
    {
        Debug.Log($"[FlutterBridge] Received request to experience seat: {seatId}");

        SeatData seat = VenueGenerator.Instance?.FindSeatById(seatId);
        if (seat == null)
        {
            Debug.LogWarning($"[FlutterBridge] No seat found with ID '{seatId}'");
            NotifyFlutter("seat_not_found:" + seatId);
            return;
        }

        ExperienceController.Instance?.EnterExperience(seat);
        NotifyFlutter("experience_started:" + seatId);
    }

    /// <summary>Called by Flutter if it wants to force-close the experience remotely.</summary>
    public void ExitExperienceFromFlutter()
    {
        ExperienceController.Instance?.ExitExperience();
    }

    /// <summary>
    /// Called by Flutter's "Watch Trailer" button to play a direct video
    /// file ON the generated cinema screen itself (see
    /// TrailerScreenPlayer.cs for why this only ever receives a direct
    /// file URL, never a YouTube/Vimeo link — Flutter's own full-screen
    /// overlay handles those instead, and never calls this for them).
    /// </summary>
    public void LoadTrailer(string url)
    {
        Debug.Log($"[FlutterBridge] LoadTrailer received — url={url}");

        if (TrailerScreenPlayer.Instance != null)
        {
            TrailerScreenPlayer.Instance.Play(url);
        }
        else
        {
            // Previously this only logged to the Unity console — Flutter
            // would be left stuck on "Loading Trailer..." with literally no
            // way to know why, since nothing ever reached it. This is one
            // of the two places (the other being deep inside
            // TrailerScreenPlayer.Play itself) execution could silently
            // stall without this fix.
            Debug.LogWarning("[FlutterBridge] LoadTrailer: no TrailerScreenPlayer in the scene.");
            NotifyFlutter("trailer_error:no_trailer_player");
        }
    }

    /// <summary>Called by Flutter when the person closes the in-scene trailer.</summary>
    public void StopTrailer(string _)
    {
        Debug.Log("[FlutterBridge] StopTrailer received.");
        TrailerScreenPlayer.Instance?.Stop();
    }

    /// <summary>
    /// Call this from anywhere in Unity to notify Flutter that something
    /// happened. Messages are simple strings so both sides stay easy to
    /// reason about — e.g. "experience_exited:G12".
    /// </summary>
    public static void NotifyFlutter(string message)
    {
#if UNITY_WEBGL && !UNITY_EDITOR
        SendMessageToFlutter(message);
#else
        Debug.Log($"[FlutterBridge] (Editor only, not sent) Would notify Flutter: {message}");
#endif
    }
}
