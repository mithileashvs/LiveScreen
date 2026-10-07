using UnityEngine;
using UnityEngine.Video;

/// <summary>
/// Plays a trailer's video file ONTO the generated cinema screen's own
/// material, via a VideoPlayer rendering to a RenderTexture — so the
/// person can see roughly how a movie will actually look (and, via
/// SpatialAudioManager, sound) from the seat they're sitting in.
///
/// IMPORTANT — WHY THIS ONLY EVER HANDLES DIRECT VIDEO FILES:
///
/// This is genuinely different from, and does not replace, Flutter's own
/// full-screen trailer overlay
/// (lib/shared/widgets/trailer_player.dart/TrailerScreen). That one can
/// play anything a browser <video>/<iframe> can — YouTube, Vimeo, a direct
/// file. THIS one can only ever play a direct file: a WebGL mesh material
/// can only ever display a decoded video texture. There is no way to
/// place an embedded YouTube/Vimeo *player* — which is itself a whole web
/// page running in an iframe — "onto" a 3D surface; that is not something
/// any WebGL renderer can do, not a limitation specific to this script.
///
/// Flutter is responsible for only ever sending a direct-file URL here
/// (see TrailerSource.kind in trailer_url.dart) and falling back to its
/// own full-screen overlay for anything else (YouTube/Vimeo). If nothing
/// arrives here for a YouTube/Vimeo trailer, that is Flutter correctly
/// not calling this at all — not a bug in this script.
///
/// Attach this to the same persistent GameObject FlutterBridge lives on
/// (so FlutterBridge.LoadTrailer/StopTrailer can find it via Instance).
/// This deliberately does NOT cache a reference to the screen at Awake —
/// the generated venue (and its screen) is destroyed and rebuilt every
/// time VenueGenerator.Generate() runs, so the screen is looked up fresh
/// on every Play() call via VenueGenerator.Instance.ScreenTransform.
///
/// NOTE ON CURVED SCREENS: ScreenGenerator.cs currently only ever builds a
/// flat Cube — there is no curved-screen mesh anywhere in this project
/// (VenueParameters.curveRadius/"Curved" arrangement controls how SEATING
/// rows are arranged in an arc, not the screen's own geometry). This
/// material-swap approach is therefore already complete for every screen
/// this app can generate; it is not a stand-in for curved-screen support
/// that exists elsewhere.
/// </summary>
public class TrailerScreenPlayer : MonoBehaviour
{
    public static TrailerScreenPlayer Instance { get; private set; }

    // Only a fallback for a video that never reports its own width/height
    // (rare, but Prepare() with a broken stream can leave these at 0) —
    // Play() otherwise sizes the actual RenderTexture below to the
    // SCREEN's aspect ratio, not this.
    private const int FallbackRenderTextureWidth = 1280;
    private const int FallbackRenderTextureHeight = 720;

    private VideoPlayer _videoPlayer;
    private RenderTexture _renderTexture;

    // The screen's own material and its pre-trailer appearance, so Stop()
    // can put it back exactly as ScreenGenerator left it rather than
    // leaving it permanently swapped to a (by then stopped, blank) video
    // texture.
    private Renderer _screenRenderer;
    private Material _screenMaterial;
    private Material _videoMaterial;
    private Texture _originalMainTexture;
    private bool _hadEmissionMap;
    private Texture _originalEmissionMap;

    // The speaker this trailer's audio is currently routed through (see
    // RouteAudio below) — remembered so Stop() can explicitly silence it
    // rather than relying only on VideoPlayer.Stop()'s documented (but not
    // independently verified here) side effect on its target AudioSource.
    private AudioSource _trailerAudioSource;

    // Cinematic auditorium lighting management during trailer playback:
    private readonly System.Collections.Generic.Dictionary<Light, float> _originalLightIntensities =
        new System.Collections.Generic.Dictionary<Light, float>();
    private Coroutine _lightingCoroutine;
    private bool _lightingDimmed = false;

    private void Awake()
    {
        Instance = this;
    }

    /// <summary>
    /// Starts playing [url] (a direct video file — .mp4/.webm/.ogv/.mov/
    /// etc.) on the currently generated screen. Safe to call again with a
    /// different url while already playing — cleanly swaps rather than
    /// stacking players. No-ops (with a warning, and a trailer_error
    /// notification to Flutter) if no screen exists yet, which should not
    /// normally happen since the Flutter button that triggers this only
    /// appears once the seat experience is already up.
    /// </summary>
    public void Play(string url)
    {
        Debug.Log($"[TrailerScreenPlayer] Play called — url={url}");

        if (string.IsNullOrEmpty(url))
        {
            Debug.LogWarning("[TrailerScreenPlayer] Play called with an empty url — ignoring.");
            FlutterBridge.NotifyFlutter("trailer_error:empty_url");
            return;
        }

        Transform screenTransform = VenueGenerator.Instance != null ? VenueGenerator.Instance.ScreenTransform : null;
        if (screenTransform == null)
        {
            Debug.LogWarning("[TrailerScreenPlayer] Play: no generated screen exists yet — ignoring.");
            FlutterBridge.NotifyFlutter("trailer_error:no_screen");
            return;
        }

        Renderer screenRenderer = screenTransform.GetComponent<Renderer>();
        if (screenRenderer == null)
        {
            Debug.LogWarning("[TrailerScreenPlayer] Play: the screen has no Renderer — ignoring.");
            FlutterBridge.NotifyFlutter("trailer_error:no_screen_renderer");
            return;
        }

        // Tear down any previous playback first, WITHOUT restoring the
        // material yet — we're about to immediately overwrite it with the
        // new trailer's texture, so restoring first would just cause a
        // one-frame flash back to the idle screen.
        StopVideoPlayer();

        // .material (not .sharedMaterial) — this returns/creates a
        // per-instance copy the first time it's accessed, so swapping its
        // texture here can never bleed into any other screen or into the
        // shared prefab material ScreenGenerator created.
        _screenRenderer = screenRenderer;
        _screenMaterial = screenRenderer.material;
        _originalMainTexture = _screenMaterial.HasProperty("_MainTex") ? _screenMaterial.GetTexture("_MainTex") : null;
        _hadEmissionMap = _screenMaterial.HasProperty("_EmissionMap");
        _originalEmissionMap = _hadEmissionMap ? _screenMaterial.GetTexture("_EmissionMap") : null;

        // Allocate initial RenderTexture (will be resized upon prepareCompleted to match source video resolution)
        int rtWidth = 1920;
        int rtHeight = 1080;

        if (_renderTexture != null && (_renderTexture.width != rtWidth || _renderTexture.height != rtHeight))
        {
            _renderTexture.Release();
            _renderTexture = null;
        }
        if (_renderTexture == null)
        {
            _renderTexture = new RenderTexture(rtWidth, rtHeight, 0)
            {
                name = "TrailerRenderTexture",
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
            };
        }
        Debug.Log($"[TrailerScreenPlayer] Initial RenderTexture ready: {rtWidth}x{rtHeight}.");

        _videoPlayer = gameObject.AddComponent<VideoPlayer>();
        _videoPlayer.playOnAwake = false;
        _videoPlayer.source = VideoSource.Url;
        _videoPlayer.url = url;
        _videoPlayer.renderMode = VideoRenderMode.RenderTexture;
        _videoPlayer.targetTexture = _renderTexture;
        _videoPlayer.aspectRatio = VideoAspectRatio.FitInside;
        _videoPlayer.isLooping = true;
        _videoPlayer.errorReceived += OnVideoError;
        _videoPlayer.prepareCompleted += OnVideoPrepared;
        Debug.Log(
            $"[TrailerScreenPlayer] VideoPlayer configured — source={_videoPlayer.source}, "
            + $"renderMode={_videoPlayer.renderMode}, aspectRatio={_videoPlayer.aspectRatio}, "
            + $"isLooping={_videoPlayer.isLooping}.");

        RouteAudio(_videoPlayer);

        _videoPlayer.Prepare();
        Debug.Log("[TrailerScreenPlayer] Prepare() called — waiting for prepareCompleted/errorReceived.");
        FlutterBridge.NotifyFlutter("trailer_loading");

        // WebGL's VideoPlayer has a real, documented failure mode: for some
        // URLs/codecs/CORS setups it neither completes nor errors — it just
        // never calls back, at all, ever. Without this, that leaves Flutter
        // stuck on "Loading Trailer..." forever with no diagnostic — which
        // is exactly the reported symptom this watchdog exists to rule in
        // or out. If OnVideoPrepared/OnVideoError already fired by the time
        // this runs, _videoPlayer will have been reassigned/nulled by a
        // subsequent Play()/Stop() and the stale capture below is checked
        // for accordingly.
        StopAllCoroutines();
        StartCoroutine(PrepareTimeoutWatchdog(_videoPlayer, url));

        // Applied immediately (before the video has actually loaded a
        // frame) rather than waiting for prepareCompleted, so the screen
        // visibly responds to the tap right away instead of appearing to
        // do nothing while the video buffers — same UX reasoning as the
        // Flutter overlay's own loading spinner.
        _screenMaterial.mainTexture = _renderTexture;
        if (_hadEmissionMap)
        {
            // The screen's glow (spec section 6/14) is driven by
            // _EmissionColor/_EmissionMap, not _MainTex alone — without
            // also setting this, the video would render correctly but
            // look dim/unlit compared to the screen's normal glowing
            // appearance.
            _screenMaterial.SetTexture("_EmissionMap", _renderTexture);
        }
        Debug.Log("[TrailerScreenPlayer] Screen material updated with the trailer's RenderTexture.");
    }

    /// <summary>
    /// WebGL's VideoPlayer can, for some URL/codec/CORS combinations,
    /// neither call prepareCompleted NOR errorReceived — it just silently
    /// never finishes preparing. Without this watchdog that leaves Flutter
    /// stuck on "Loading Trailer..." forever with zero diagnostic, which is
    /// indistinguishable from a dozen other possible causes unless this
    /// specifically rules it in or out.
    /// </summary>
    private System.Collections.IEnumerator PrepareTimeoutWatchdog(VideoPlayer player, string url)
    {
        const float timeoutSeconds = 35f;
        yield return new WaitForSeconds(timeoutSeconds);

        // player is the exact instance Play() started this watchdog for —
        // if a newer Play()/Stop() call has since replaced or cleared
        // _videoPlayer, this stale watchdog does nothing (its job is
        // already moot either way: either that video already resolved, or
        // Stop() already cleaned everything up).
        if (player == null || player != _videoPlayer) yield break;

        if (!player.isPrepared)
        {
            Debug.LogError(
                $"[TrailerScreenPlayer] Prepare() TIMED OUT after {timeoutSeconds}s with no "
                + $"prepareCompleted or errorReceived callback at all — url={url}. This usually means "
                + "Unity WebGL's VideoPlayer could not even begin fetching/decoding this URL (a codec, "
                + "container, or CORS problem the browser never surfaced as a catchable error).");
            FlutterBridge.NotifyFlutter("trailer_error:prepare_timeout");
            RestoreLighting(1.5f);
        }
    }

    /// <summary>
    /// Routes [player]'s decoded audio track. On WebGL, AudioSource routing
    /// is unsupported by Unity and causes video preparation stalls, so
    /// Direct output mode is used. On standalone/editor builds, it routes
    /// through the theatre's screen speaker rig.
    /// </summary>
    private void RouteAudio(VideoPlayer player)
    {
#if UNITY_WEBGL && !UNITY_EDITOR
        player.audioOutputMode = VideoAudioOutputMode.Direct;
        _trailerAudioSource = null;
#else
        AudioSource target = SpatialAudioManager.Instance != null
            ? SpatialAudioManager.Instance.GetScreenAudioTarget()
            : null;

        if (target == null)
        {
            Debug.LogWarning("TrailerScreenPlayer: no SpatialAudioManager speaker available — trailer will play without audio.");
            _trailerAudioSource = null;
            return;
        }

        player.audioOutputMode = VideoAudioOutputMode.AudioSource;
        player.SetTargetAudioSource(0, target);
        player.controlledAudioTrackCount = 1;
        target.volume = 1f;
        _trailerAudioSource = target;
#endif
    }

    private void OnVideoPrepared(VideoPlayer source)
    {
        Debug.Log(
            $"[TrailerScreenPlayer] prepareCompleted fired — decoded video is {source.width}x{source.height}, "
            + $"duration={source.length:F1}s, audioTrackCount={source.audioTrackCount}.");

        uint vidWidth = source.width;
        uint vidHeight = source.height;

        // 1. Native-resolution RenderTexture based on decoded source video dimensions
        if (vidWidth > 0 && vidHeight > 0)
        {
            int safeWidth = (int)Mathf.Clamp(vidWidth, 640, 3840);
            int safeHeight = (int)Mathf.Clamp(vidHeight, 360, 2160);

            if (_renderTexture == null || _renderTexture.width != safeWidth || _renderTexture.height != safeHeight)
            {
                if (_renderTexture != null) _renderTexture.Release();
                _renderTexture = new RenderTexture(safeWidth, safeHeight, 0)
                {
                    name = "TrailerRenderTexture",
                    filterMode = FilterMode.Bilinear,
                    wrapMode = TextureWrapMode.Clamp,
                };
                source.targetTexture = _renderTexture;
                Debug.Log($"[TrailerScreenPlayer] RenderTexture dynamically matched to source resolution: {safeWidth}x{safeHeight}.");
            }
        }

        // 2. Compute letterbox / pillarbox fit on the physical cinema screen
        Transform screenTransform = VenueGenerator.Instance != null ? VenueGenerator.Instance.ScreenTransform : null;
        float screenW = screenTransform != null ? screenTransform.localScale.x : 18f;
        float screenH = screenTransform != null ? screenTransform.localScale.y : 8f;
        float screenAspect = screenH > 0.0001f ? screenW / screenH : 2.25f;
        float videoAspect = vidHeight > 0 ? (float)vidWidth / vidHeight : 16f / 9f;

        float scaleX = 1f;
        float scaleY = 1f;
        float offsetX = 0f;
        float offsetY = 0f;

        if (videoAspect < screenAspect)
        {
            // Video is narrower than screen -> Pillarboxing (black bars on left & right)
            scaleX = videoAspect / screenAspect;
            scaleY = 1f;
            offsetX = (1f - scaleX) * 0.5f;
            offsetY = 0f;
        }
        else
        {
            // Video is wider than screen -> Letterboxing (black bars on top & bottom)
            scaleX = 1f;
            scaleY = screenAspect / videoAspect;
            offsetX = 0f;
            offsetY = (1f - scaleY) * 0.5f;
        }

        Vector4 fitParams = new Vector4(scaleX, scaleY, offsetX, offsetY);
        Debug.Log($"[TrailerScreenPlayer] Cinema screen aspect={screenAspect:F3}, video aspect={videoAspect:F3}, fitParams={fitParams}.");

        // 3. Assign dedicated unlit cinema screen material
        Shader cinemaShader = Shader.Find("LiveScreen/CinemaScreen");
        if (cinemaShader == null)
        {
            cinemaShader = Shader.Find("Unlit/Texture");
        }

        if (cinemaShader != null)
        {
            if (_videoMaterial != null) Destroy(_videoMaterial);
            _videoMaterial = new Material(cinemaShader);
            _videoMaterial.mainTexture = _renderTexture;
            if (_videoMaterial.HasProperty("_FitParams"))
            {
                _videoMaterial.SetVector("_FitParams", fitParams);
            }
            else
            {
                _videoMaterial.mainTextureScale = new Vector2(scaleX, scaleY);
                _videoMaterial.mainTextureOffset = new Vector2(offsetX, offsetY);
            }
            if (_screenRenderer != null)
            {
                _screenRenderer.material = _videoMaterial;
            }
            Debug.Log($"[TrailerScreenPlayer] Applied {cinemaShader.name} material with aspect fit.");
        }
        else
        {
            Debug.LogWarning("[TrailerScreenPlayer] Dedicated shader not found, falling back to screen material.");
            if (_screenMaterial != null)
            {
                _screenMaterial.mainTexture = _renderTexture;
                _screenMaterial.mainTextureScale = new Vector2(scaleX, scaleY);
                _screenMaterial.mainTextureOffset = new Vector2(offsetX, offsetY);
                if (_hadEmissionMap)
                {
                    _screenMaterial.SetTexture("_EmissionMap", _renderTexture);
                    _screenMaterial.SetTextureScale("_EmissionMap", new Vector2(scaleX, scaleY));
                    _screenMaterial.SetTextureOffset("_EmissionMap", new Vector2(offsetX, offsetY));
                }
            }
        }

        FlutterBridge.NotifyFlutter("trailer_ready");
        source.Play();
        Debug.Log($"[TrailerScreenPlayer] Play() called on VideoPlayer — isPlaying={source.isPlaying}.");
        StartLightingDim(1.5f);
        FlutterBridge.NotifyFlutter("trailer_started");
    }

    private void OnVideoError(VideoPlayer source, string message)
    {
        RestoreLighting(1.5f);
        Debug.LogError($"[TrailerScreenPlayer] errorReceived fired — {message}");
        string sanitized = string.IsNullOrEmpty(message) ? "unknown" : message.Replace(':', '/');
        FlutterBridge.NotifyFlutter($"trailer_error:{sanitized}");
    }

    /// <summary>Stops playback and restores the screen to its pre-trailer appearance.</summary>
    public void Stop()
    {
        StopVideoPlayer();
        RestoreLighting(1.5f);

        if (_screenRenderer != null && _screenMaterial != null)
        {
            _screenRenderer.material = _screenMaterial;
            _screenMaterial.mainTexture = _originalMainTexture;
            if (_hadEmissionMap)
            {
                _screenMaterial.SetTexture("_EmissionMap", _originalEmissionMap);
            }
        }

        if (_videoMaterial != null)
        {
            Destroy(_videoMaterial);
            _videoMaterial = null;
        }

        if (_renderTexture != null)
        {
            _renderTexture.Release();
            _renderTexture = null;
        }

        _screenRenderer = null;
        _screenMaterial = null;

        FlutterBridge.NotifyFlutter("trailer_stopped");
    }

    private void StopVideoPlayer()
    {
        if (_trailerAudioSource != null)
        {
            // Explicit, rather than assuming VideoPlayer.Stop() below
            // silences its target AudioSource on its own — this is the
            // actual requirement ("prevent audio continuing in the
            // background"), not an assumption about VideoPlayer's
            // internals.
            _trailerAudioSource.Stop();
            _trailerAudioSource = null;
        }

        if (_videoPlayer == null) return;

        _videoPlayer.errorReceived -= OnVideoError;
        _videoPlayer.prepareCompleted -= OnVideoPrepared;
        _videoPlayer.Stop();
        Destroy(_videoPlayer);
        _videoPlayer = null;
    }

    /// <summary>
    /// Captures the auditorium's original lighting intensities once,
    /// so repeated start/stop cycles do not accumulate dimming changes.
    /// </summary>
    private void CaptureLightingState()
    {
        if (_originalLightIntensities.Count > 0) return;

        Light[] allLights = FindObjectsByType<Light>(FindObjectsSortMode.None);
        foreach (Light l in allLights)
        {
            if (l == null) continue;
            string parentName = l.transform.parent != null ? l.transform.parent.name : string.Empty;
            string lightName = l.gameObject.name;

            // Only capture auditorium ceiling downlights and aisle floor lights
            if (parentName.Contains("CeilingLights") || lightName.Contains("CeilingLight") ||
                parentName.Contains("AisleLights") || lightName.Contains("AisleLight"))
            {
                _originalLightIntensities[l] = l.intensity;
            }
        }
        Debug.Log($"[TrailerScreenPlayer] Captured original lighting state for {_originalLightIntensities.Count} auditorium lights.");
    }

    /// <summary>
    /// Smoothly dims auditorium ceiling and aisle lights over [duration] seconds.
    /// Screen becomes the dominant visual light source.
    /// </summary>
    public void StartLightingDim(float duration = 1.5f)
    {
        CaptureLightingState();
        if (_lightingCoroutine != null) StopCoroutine(_lightingCoroutine);
        _lightingCoroutine = StartCoroutine(AnimateLighting(dim: true, duration: duration));
        _lightingDimmed = true;
    }

    /// <summary>
    /// Smoothly restores auditorium lighting to original intensities over [duration] seconds.
    /// </summary>
    public void RestoreLighting(float duration = 1.5f)
    {
        if (!_lightingDimmed && _originalLightIntensities.Count == 0) return;
        if (_lightingCoroutine != null) StopCoroutine(_lightingCoroutine);
        _lightingCoroutine = StartCoroutine(AnimateLighting(dim: false, duration: duration));
        _lightingDimmed = false;
    }

    private System.Collections.IEnumerator AnimateLighting(bool dim, float duration)
    {
        float elapsed = 0f;
        var startIntensities = new System.Collections.Generic.Dictionary<Light, float>();

        foreach (var kvp in _originalLightIntensities)
        {
            if (kvp.Key != null)
            {
                startIntensities[kvp.Key] = kvp.Key.intensity;
            }
        }

        while (elapsed < duration)
        {
            elapsed += Time.unscaledDeltaTime;
            float t = Mathf.Clamp01(elapsed / duration);
            float smoothT = Mathf.SmoothStep(0f, 1f, t);

            foreach (var kvp in _originalLightIntensities)
            {
                Light l = kvp.Key;
                if (l == null) continue;

                float orig = kvp.Value;
                string pName = l.transform.parent != null ? l.transform.parent.name : string.Empty;
                string lName = l.gameObject.name;

                // Ceiling lights dim to 8%, aisle lights dim to 25% for subtle orientation/safety
                float targetFraction = (pName.Contains("Ceiling") || lName.Contains("Ceiling")) ? 0.08f : 0.25f;
                float target = dim ? (orig * targetFraction) : orig;
                float start = startIntensities.TryGetValue(l, out float sVal) ? sVal : l.intensity;

                l.intensity = Mathf.Lerp(start, target, smoothT);
            }

            yield return null;
        }

        // Snap cleanly to target
        foreach (var kvp in _originalLightIntensities)
        {
            Light l = kvp.Key;
            if (l == null) continue;

            float orig = kvp.Value;
            string pName = l.transform.parent != null ? l.transform.parent.name : string.Empty;
            string lName = l.gameObject.name;
            float targetFraction = (pName.Contains("Ceiling") || lName.Contains("Ceiling")) ? 0.08f : 0.25f;

            l.intensity = dim ? (orig * targetFraction) : orig;
        }

        _lightingCoroutine = null;
        Debug.Log($"[TrailerScreenPlayer] Lighting transition finished — dim={dim}.");
    }

    /// <summary>
    /// Resets captured lighting cache when a venue is destroyed/rebuilt.
    /// </summary>
    public void ResetLightingCache()
    {
        if (_lightingCoroutine != null)
        {
            StopCoroutine(_lightingCoroutine);
            _lightingCoroutine = null;
        }
        _originalLightIntensities.Clear();
        _lightingDimmed = false;
    }

    private void OnDestroy()
    {
        if (_trailerAudioSource != null)
        {
            _trailerAudioSource.Stop();
            _trailerAudioSource = null;
        }
        if (_videoMaterial != null)
        {
            Destroy(_videoMaterial);
            _videoMaterial = null;
        }
        if (_renderTexture != null)
        {
            _renderTexture.Release();
            _renderTexture = null;
        }
    }
}
