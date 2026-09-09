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
    /// Only overwrites the specific room/screen/seating-layout fields
    /// Flutter actually sends; everything else this scene has configured
    /// (lighting, aisle count, headroom, eye heights, etc.) is left alone.
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
            Debug.LogWarning("[FlutterBridge] No VenueGenerator found — cannot apply configuration.");
            NotifyFlutter("configuration_loaded");
            return;
        }

        VenueParameters incoming;
        try
        {
            incoming = JsonUtility.FromJson<VenueParameters>(json);
        }
        catch (System.Exception e)
        {
            Debug.LogWarning($"[FlutterBridge] Could not parse configuration JSON: {e.Message}");
            NotifyFlutter("configuration_loaded");
            return;
        }

        if (incoming == null)
        {
            Debug.LogWarning("[FlutterBridge] Configuration JSON parsed to null.");
            NotifyFlutter("configuration_loaded");
            return;
        }

        VenueParameters p = venueGenerator.Parameters;
        p.roomWidth = incoming.roomWidth;
        p.roomLength = incoming.roomLength;
        p.roomHeight = incoming.roomHeight;
        p.screenWidth = incoming.screenWidth;
        p.screenHeight = incoming.screenHeight;
        p.rows = incoming.rows;
        p.seatsPerRow = incoming.seatsPerRow;
        p.seatSpacing = incoming.seatSpacing;
        p.rowSpacing = incoming.rowSpacing;
        p.seatWidth = incoming.seatWidth;
        p.firstRowDistanceFromScreen = incoming.firstRowDistanceFromScreen;
        p.rowRisePerRow = incoming.rowRisePerRow;

        venueGenerator.Generate();

        NotifyFlutter("configuration_loaded");
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
