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

    private float _yaw;
    private float _pitch;

    private void Start()
    {
        Vector3 angles = transform.eulerAngles;
        _yaw = angles.y;
        _pitch = angles.x;

        // Start at a reasonable vantage point looking into the auditorium.
        transform.position = new Vector3(0, 12, -15);
        transform.LookAt(new Vector3(0, 4, 20));
    }

    private void Update()
    {
        HandleLook();
        HandleMove();
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
}
