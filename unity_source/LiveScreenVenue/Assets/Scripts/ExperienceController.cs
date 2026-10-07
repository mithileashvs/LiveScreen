using System.Collections;
using UnityEngine;

/// <summary>
/// Phase 3 core system. Takes a SeatData (already calculated by Phase 2's
/// SeatGenerator — one single source of truth for positions) and moves the
/// camera there, at the correct eye height, automatically facing the screen.
///
/// Attach this to the same "VenueManager" object as VenueGenerator.
/// </summary>
[RequireComponent(typeof(VenueGenerator))]
public class ExperienceController : MonoBehaviour
{
    public static ExperienceController Instance { get; private set; }

    [Tooltip("How long the camera takes to move into the seat, in seconds")]
    public float transitionDuration = 0.6f;

    public bool IsExperienceActive { get; private set; }
    public ExperienceSession CurrentSession { get; private set; }

    private VenueGenerator _venueGenerator;
    private OrbitCamera _orbitCamera;
    private Camera _camera;

    // Saved so we can restore the preview camera exactly where it was.
    private Vector3 _savedPreviewPosition;
    private Quaternion _savedPreviewRotation;
    private float _savedFieldOfView;
    private bool _hasSavedPreviewState;

    private Coroutine _transitionCoroutine;

    private void Awake()
    {
        Instance = this;
        _venueGenerator = GetComponent<VenueGenerator>();
    }

    private void Start()
    {
        _camera = Camera.main;
        if (_camera != null)
        {
            _orbitCamera = _camera.GetComponent<OrbitCamera>();
        }
    }

    /// <summary>
    /// The main entry point for Phase 3. Pass in the seat the user selected —
    /// the exact same SeatData that Phase 2 generated, nothing recalculated
    /// or duplicated.
    /// </summary>
    public void EnterExperience(SeatData seat)
    {
        if (_camera == null || seat == null) return;

        // First time entering: remember where the preview camera was so we
        // can put it back exactly when the user exits.
        if (!IsExperienceActive)
        {
            _savedPreviewPosition = _camera.transform.position;
            _savedPreviewRotation = _camera.transform.rotation;
            _savedFieldOfView = _camera.fieldOfView;
            _hasSavedPreviewState = true;
        }

        IsExperienceActive = true;
        // Tag the session with the theatre it actually belongs to, rather
        // than the literal "demo_venue" placeholder — analytics that can't
        // tell two theatres apart is worse than no analytics.
        TheatreConfigPayload config = VenueGenerator.Instance != null
            ? VenueGenerator.Instance.Configuration
            : null;
        CurrentSession = config == null
            ? new ExperienceSession(seat)
            : new ExperienceSession(seat, config.theatreId, config.theatreName);

        if (_orbitCamera != null)
        {
            _orbitCamera.AllowMovement = false; // look around only, no walking (spec section 8)
        }

        Vector3 targetPosition = CalculateEyePosition(seat);
        Quaternion targetRotation = CalculateLookAtScreenRotation(targetPosition);

        if (_transitionCoroutine != null) StopCoroutine(_transitionCoroutine);
        _transitionCoroutine = StartCoroutine(TransitionCamera(targetPosition, targetRotation, _venueGenerator.Parameters.experienceFieldOfView, onComplete: () =>
        {
            // Only once the camera has actually arrived — not on button
            // press — so screen audio starts in sync with the seated view.
            SpatialAudioManager.Instance?.OnEnteredSeat(seat);
        }));

        Debug.Log($"Entering experience at seat {seat.Id}, eye position {targetPosition}");
    }

    /// <summary>Returns to the venue preview camera, exactly where it was before.</summary>
    public void ExitExperience()
    {
        if (!IsExperienceActive || !_hasSavedPreviewState) return;

        string exitedSeatId = CurrentSession?.SeatId;

        IsExperienceActive = false;
        CurrentSession = null;

        // If a trailer was playing on the cinema screen, stop it now —
        // otherwise its VideoPlayer/RenderTexture/routed AudioSource would
        // keep running after the user has left the seat experience
        // entirely. Safe to call even when nothing is currently playing.
        TrailerScreenPlayer.Instance?.Stop();

        if (_transitionCoroutine != null) StopCoroutine(_transitionCoroutine);
        _transitionCoroutine = StartCoroutine(TransitionCamera(_savedPreviewPosition, _savedPreviewRotation, _savedFieldOfView, onComplete: () =>
        {
            if (_orbitCamera != null)
            {
                _orbitCamera.AllowMovement = true;
            }
            SpatialAudioManager.Instance?.OnExitedSeat();
        }));

        FlutterBridge.NotifyFlutter("experience_exited:" + exitedSeatId);
        Debug.Log("Exited experience, returning to venue preview.");
    }

    /// <summary>
    /// Works out where the camera's "eye" should sit for a given seat —
    /// the seat's floor position, raised by an eye-height that depends on
    /// seat type (spec section 5 and 14). This is NOT a second position
    /// system — it's a small, configurable offset applied to the one
    /// source of truth (SeatData.Position) from Phase 2.
    /// </summary>
    private Vector3 CalculateEyePosition(SeatData seat)
    {
        var p = _venueGenerator.Parameters;
        float eyeHeight;

        switch (seat.Type)
        {
            case SeatType.Premium:
                eyeHeight = p.eyeHeightPremium;
                break;
            case SeatType.Recliner:
                eyeHeight = p.eyeHeightRecliner;
                break;
            default:
                eyeHeight = p.eyeHeightStandard;
                break;
        }

        return seat.Position + new Vector3(0, eyeHeight, 0);
    }

    /// <summary>
    /// Calculates the rotation needed to look at the generated screen from
    /// a given eye position. This is deliberately computed from the real
    /// screen's transform rather than assumed, per spec section 6 — so it
    /// stays correct no matter how the venue is configured.
    /// </summary>
    private Quaternion CalculateLookAtScreenRotation(Vector3 eyePosition)
    {
        if (_venueGenerator.ScreenTransform == null)
        {
            return Quaternion.identity;
        }

        Vector3 screenCenter = _venueGenerator.ScreenTransform.position;
        Vector3 direction = (screenCenter - eyePosition).normalized;
        return Quaternion.LookRotation(direction, Vector3.up);
    }

    /// <summary>A short, simple cinematic move from wherever the camera currently is
    /// to the target position/rotation/FOV (spec section 10 — keep transitions short).</summary>
    private IEnumerator TransitionCamera(Vector3 targetPosition, Quaternion targetRotation, float targetFov, System.Action onComplete = null)
    {
        Vector3 startPosition = _camera.transform.position;
        Quaternion startRotation = _camera.transform.rotation;
        float startFov = _camera.fieldOfView;

        float elapsed = 0f;
        while (elapsed < transitionDuration)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.Clamp01(elapsed / transitionDuration);
            // Smooth in/out instead of linear, for a slightly more polished feel.
            float eased = t * t * (3f - 2f * t);

            _camera.transform.position = Vector3.Lerp(startPosition, targetPosition, eased);
            _camera.transform.rotation = Quaternion.Slerp(startRotation, targetRotation, eased);
            _camera.fieldOfView = Mathf.Lerp(startFov, targetFov, eased);

            yield return null;
        }

        _camera.transform.position = targetPosition;
        _camera.transform.rotation = targetRotation;
        _camera.fieldOfView = targetFov;

        _orbitCamera?.SyncAnglesFromTransform();
        onComplete?.Invoke();
    }
}
