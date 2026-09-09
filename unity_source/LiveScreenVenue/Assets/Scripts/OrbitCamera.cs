using UnityEngine;

/// <summary>
/// A simple free-look camera for previewing the generated venue.
/// Attach this to your Main Camera.
///
/// Controls:
///   Right-click + drag  = look around
///   W/A/S/D              = move forward/left/back/right
///   Q/E                   = move down/up
///   Scroll wheel          = move forward/back (zoom-like)
/// </summary>
public class OrbitCamera : MonoBehaviour
{
    public float moveSpeed = 8f;
    public float lookSpeed = 2f;

    /// <summary>
    /// When false, W/A/S/D and scroll-to-zoom are disabled — only looking
    /// around is allowed. Used during the Phase 3 seat experience, where
    /// the spec requires "look around, don't walk around".
    /// </summary>
    public bool AllowMovement = true;

    private float _yaw;
    private float _pitch;

    private void Start()
    {
        // "Outside the theatre" renders as the SAME color as the theatre's
        // own walls (not pure black) — so there's no visible seam/edge
        // where the walls end, per your request that users shouldn't be
        // able to tell where the theatre stops and the environment starts.
        // Sourced from RoomGenerator.WallColor rather than a separate
        // literal, so the two can never drift out of sync.
        var cam = GetComponent<Camera>();
        if (cam != null)
        {
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = RoomGenerator.WallColor;
        }

        Vector3 angles = transform.eulerAngles;
        _yaw = angles.y;
        _pitch = angles.x;

        // Start at a reasonable vantage point looking into the auditorium.
        transform.position = new Vector3(0, 12, -15);
        transform.LookAt(new Vector3(0, 4, 20));
        SyncAnglesFromTransform();
    }

    private void Update()
    {
        HandleLook();
        if (AllowMovement)
        {
            HandleMove();
        }
    }

    private void HandleLook()
    {
        if (Input.GetMouseButton(1)) // right mouse button held
        {
            _yaw += Input.GetAxis("Mouse X") * lookSpeed;
            _pitch -= Input.GetAxis("Mouse Y") * lookSpeed;
            _pitch = Mathf.Clamp(_pitch, -80f, 80f);
            transform.eulerAngles = new Vector3(_pitch, _yaw, 0);
        }
    }

    private void HandleMove()
    {
        float speed = moveSpeed * Time.deltaTime;
        Vector3 move = Vector3.zero;

        if (Input.GetKey(KeyCode.W)) move += transform.forward;
        if (Input.GetKey(KeyCode.S)) move -= transform.forward;
        if (Input.GetKey(KeyCode.A)) move -= transform.right;
        if (Input.GetKey(KeyCode.D)) move += transform.right;
        if (Input.GetKey(KeyCode.E)) move += Vector3.up;
        if (Input.GetKey(KeyCode.Q)) move -= Vector3.up;

        // Scroll wheel moves forward/back, like a zoom.
        move += transform.forward * Input.GetAxis("Mouse ScrollWheel") * 20f;

        transform.position += move * speed;
    }

    /// <summary>
    /// Call this any time something else (like ExperienceController) sets
    /// transform.position/rotation directly, so the next right-click-drag
    /// continues smoothly from the new orientation instead of snapping back.
    /// </summary>
    public void SyncAnglesFromTransform()
    {
        Vector3 angles = transform.eulerAngles;
        _yaw = angles.y;
        _pitch = angles.x;
    }
}
