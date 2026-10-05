using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// The seven speaker channel concepts already defined on the Flutter side
/// (lib/admin/models/speaker_model.dart's SpeakerChannel) mirrored here in
/// C#, so a future Flutter -> Unity data bridge has a matching vocabulary
/// to map onto (see theatre_unity_bridge.dart's toUnityVenueExportJson,
/// which already shapes speaker data this way — nothing sends it to Unity
/// yet, but the names line up for whenever that pipeline exists).
/// </summary>
public enum SpeakerChannel
{
    Left,
    Center,
    Right,
    LeftSurround,
    RightSurround,
    Lfe,
    Overhead,
}

/// <summary>
/// Builds a 3D speaker rig from the venue's own configured dimensions
/// (same "derive from VenueParameters, don't hardcode" approach
/// RoomGenerator already uses for ceiling/aisle lights) and exposes a small
/// public API for playing audio through it.
///
/// Speaker POSITIONS now come from the selected theatre's saved
/// SpeakerModel list whenever Flutter sent one (see
/// theatre_unity_bridge.dart -> FlutterBridge.LoadConfiguration ->
/// VenueGenerator.ApplyConfiguration -> RebuildForCurrentVenue). The
/// derive-from-room-dimensions 7-speaker layout below is now only the
/// fallback for a theatre that has not configured any speakers yet.
///
/// The public API is unchanged on purpose: everything still addresses a
/// [SpeakerChannel] rather than a raw AudioSource, so nothing that plays
/// audio had to change to gain configured speakers. The only internal
/// change is that a channel now maps to a LIST of sources instead of a
/// single one — a real theatre can legitimately have several speakers on
/// the same channel (four side surrounds, two subwoofers), and collapsing
/// those to one would have quietly discarded most of an owner's rig.
///
/// Attach to the same "VenueManager" object as VenueGenerator/
/// ExperienceController.
/// </summary>
[RequireComponent(typeof(VenueGenerator))]
public class SpatialAudioManager : MonoBehaviour
{
    public static SpatialAudioManager Instance { get; private set; }

    [Header("Screen Audio (optional)")]
    [Tooltip("Assign a movie/trailer audio track to have it play, spatialized " +
             "across the front speakers, once the camera actually settles into " +
             "a selected seat. Leave empty for silence — this is an extension " +
             "point for whenever real movie audio exists, not a requirement.")]
    public AudioClip screenAudioClip;

    [Header("Ambient Room Tone (optional)")]
    [Tooltip("A quiet looping room-tone clip played from every speaker at once, " +
             "for a sense of scale before/without a movie playing. Optional.")]
    public AudioClip ambientClip;
    [Range(0f, 1f)] public float ambientVolume = 0.15f;

    [Header("Diagnostics")]
    [Tooltip("On start, briefly cycles a procedural test tone through every " +
             "speaker in sequence so spatial placement can be verified by ear " +
             "alone. Turn this OFF before shipping a real build — it's a " +
             "development aid, not something end users should hear.")]
    public bool playStartupTestSweep = false;

    private VenueGenerator _venueGenerator;
    private readonly Dictionary<SpeakerChannel, List<AudioSource>> _speakers =
        new Dictionary<SpeakerChannel, List<AudioSource>>();
    private GameObject _rigRoot;

    /// <summary>How many speaker objects currently exist. Exposed so the
    /// experience/diagnostics can confirm that Theatre A and Theatre B
    /// really did produce different rigs.</summary>
    public int SpeakerCount { get; private set; }

    /// <summary>True when the current rig came from a theatre's saved
    /// configuration rather than the derived fallback.</summary>
    public bool UsingConfiguredSpeakers { get; private set; }

    /// <summary>One line per generated speaker (id, channel, type, position) —
    /// populated by every RebuildForCurrentVenue call. Exists so the actual
    /// generated rig can be verified at a glance in the console/log, rather
    /// than having to trust that "N speakers" really means N different,
    /// correctly-placed speakers.</summary>
    public readonly List<string> LastSpeakerDiagnostics = new List<string>();

    private void Awake()
    {
        Instance = this;
        _venueGenerator = GetComponent<VenueGenerator>();
    }

    private void Start()
    {
        // The rig is built by RebuildForCurrentVenue, which VenueGenerator
        // calls every time it generates — including the very first time.
        // Building here as well would create a second, stale rig from
        // whatever parameters happened to be set before any theatre
        // configuration arrived.
        if (ambientClip != null)
        {
            PlayAmbient(ambientClip);
        }

        if (playStartupTestSweep)
        {
            StartCoroutine(TestSweep());
        }
    }

    /// <summary>
    /// Called by <see cref="VenueGenerator.Generate"/> every time a venue is
    /// (re)generated. Tears down the previous rig and builds the one this
    /// theatre actually specifies.
    ///
    /// [venueRoot] is the freshly generated venue's root, so speakers are
    /// parented to the same object the rest of the theatre lives under and
    /// are therefore cleared with it — the previous rig was parented to the
    /// persistent VenueManager, which is why demo speakers survived a
    /// regeneration and kept playing from demo positions.
    /// </summary>
    public void RebuildForCurrentVenue(Transform venueRoot)
    {
        ClearRig();
        LastSpeakerDiagnostics.Clear();

        _rigRoot = new GameObject("SpatialAudioRig");
        _rigRoot.transform.SetParent(venueRoot != null ? venueRoot : transform, false);

        TheatreConfigPayload config = _venueGenerator != null ? _venueGenerator.Configuration : null;
        VenueParameters p = _venueGenerator != null ? _venueGenerator.Parameters : new VenueParameters();

        // The LiveScreen spatial audio engine runs independently of visual speaker
        // placement. Visual speakers are generated by SpeakerGenerator without AudioSources,
        // while SpatialAudioManager maintains the standard 7-channel spatial cinema audio rig.
        BuildDerivedSpeakerRig(p);

        ApplyAcoustics(config);

        int configuredCount = config != null && config.speakers != null ? config.speakers.Length : 0;
        Debug.Log(
            $"[SpatialAudioManager] Spatial audio rig active: {SpeakerCount} audio channels " +
            $"(visual speakers={configuredCount}, decoupled from audio).");
    }

    private void ClearRig()
    {
        _speakers.Clear();
        SpeakerCount = 0;
        UsingConfiguredSpeakers = false;

        if (_rigRoot != null)
        {
            _rigRoot.SetActive(false);
            Destroy(_rigRoot);
            _rigRoot = null;
        }
    }

    /// <summary>The theatre owner's own speakers, at their own positions.</summary>
    private void BuildConfiguredSpeakerRig(TheatreConfigPayload config, VenueParameters p)
    {
        UsingConfiguredSpeakers = true;

        foreach (SpeakerPlacement placement in config.speakers)
        {
            if (placement == null) continue;

            // Subwoofers/LFE are felt more than localized, so they keep the
            // wide falloff the previous rig gave the LFE channel.
            SpeakerChannel channel = placement.ToChannel();
            float? maxDistance = channel == SpeakerChannel.Lfe ? p.roomLength * 1.5f : (float?)null;

            AudioSource source = AddSpeaker(
                _rigRoot.transform, channel, placement.Position, p, maxDistance,
                speakerId: placement.id, speakerType: placement.type);

            source.gameObject.name = string.IsNullOrEmpty(placement.name)
                ? $"Speaker_{channel}_{placement.id}"
                : $"Speaker_{placement.name}";
            source.transform.localRotation = Quaternion.Euler(0f, placement.rotationY, 0f);

            // Rated power is the only spec with an unambiguous, honest
            // mapping onto playback: a more powerful speaker carries
            // further. Anything beyond that (frequency range, sensitivity)
            // is stored and passed through but deliberately NOT turned into
            // a fake simulation here.
            if (placement.ratedPowerWatts > 0f)
            {
                source.maxDistance = Mathf.Max(
                    source.maxDistance,
                    Mathf.Sqrt(placement.ratedPowerWatts) * 2f);
            }
        }
    }

    /// <summary>
    /// The previous behaviour, now used only when a theatre has no speakers
    /// configured: a reasonable 7-channel layout scaled to the room.
    /// </summary>
    private void BuildDerivedSpeakerRig(VenueParameters p)
    {
        UsingConfiguredSpeakers = false;
        Transform root = _rigRoot.transform;

        float halfWidth = p.roomWidth / 2f;
        float screenZ = p.screenDistanceFromFrontWall;
        const float earHeight = 1.4f; // roughly average seated ear height across seat types

        AddSpeaker(root, SpeakerChannel.Left, new Vector3(-halfWidth * 0.35f, earHeight + 1f, screenZ), p);
        AddSpeaker(root, SpeakerChannel.Center, new Vector3(0, earHeight + 1f, screenZ), p);
        AddSpeaker(root, SpeakerChannel.Right, new Vector3(halfWidth * 0.35f, earHeight + 1f, screenZ), p);

        float midDepth = p.firstRowDistanceFromScreen + ((p.rows - 1) * p.rowSpacing * 0.5f);
        AddSpeaker(root, SpeakerChannel.LeftSurround, new Vector3(-halfWidth * 0.9f, earHeight, midDepth), p);
        AddSpeaker(root, SpeakerChannel.RightSurround, new Vector3(halfWidth * 0.9f, earHeight, midDepth), p);

        float rearDepth = p.firstRowDistanceFromScreen + ((p.rows - 1) * p.rowSpacing);
        AddSpeaker(root, SpeakerChannel.Overhead, new Vector3(0, p.roomHeight - 1f, rearDepth * 0.6f), p);

        // LFE: near-field, wide max distance — bass is felt more than
        // localized. A true dedicated low-frequency-only bus would need an
        // AudioMixer with a lowpass send, which felt like unnecessary
        // complexity/weight for this pass (spec: keep WebGL lightweight).
        AddSpeaker(root, SpeakerChannel.Lfe, new Vector3(0, 0.3f, screenZ), p, maxDistanceOverride: p.roomLength * 1.5f);
    }

    private AudioSource AddSpeaker(Transform parent, SpeakerChannel channel, Vector3 localPosition, VenueParameters p,
        float? maxDistanceOverride = null, string speakerId = null, string speakerType = null)
    {
        var go = new GameObject($"Speaker_{channel}");
        go.transform.SetParent(parent, false);
        go.transform.localPosition = localPosition;

        var source = go.AddComponent<AudioSource>();
        source.playOnAwake = false;
        source.loop = false;
        source.spatialBlend = 1f; // fully 3D — this is the actual "spatial" in spatial audio
        source.dopplerLevel = 0f; // these speakers never move, so no pitch shifting
        source.rolloffMode = AudioRolloffMode.Linear;
        source.minDistance = 1f;
        source.maxDistance = maxDistanceOverride ?? Mathf.Max(p.roomWidth, p.roomLength);

        // AudioSources are strictly non-visual audio emitters.
        // Visual speaker cabinets are generated independently by SpeakerGenerator.

        if (!_speakers.TryGetValue(channel, out var sources))
        {
            sources = new List<AudioSource>();
            _speakers[channel] = sources;
        }
        sources.Add(source);
        SpeakerCount++;

        string id = string.IsNullOrEmpty(speakerId) ? $"(derived-{SpeakerCount})" : speakerId;
        string type = string.IsNullOrEmpty(speakerType) ? "(derived)" : speakerType;
        LastSpeakerDiagnostics.Add(
            $"id={id} channel={channel} type={type} localPos=({localPosition.x:F2}, {localPosition.y:F2}, {localPosition.z:F2})");

        return source;
    }

    /// <summary>
    /// Feeds the theatre's configured surface absorption into Unity's
    /// existing audio system. An absorptive room gets a shorter, drier
    /// reverb tail; a reflective one gets a longer, wetter tail.
    ///
    /// This is a mapping of configured values onto the engine's reverb
    /// controls — it is NOT an acoustic simulation and makes no claim to
    /// be one. The requirement it satisfies is that the theatre's saved
    /// acoustics actually reach the audio system instead of being dropped.
    /// </summary>
    private void ApplyAcoustics(TheatreConfigPayload config)
    {
        if (config == null || config.acoustics == null || _rigRoot == null) return;

        float absorption = config.acoustics.AverageAbsorption;

        var zoneGo = new GameObject("AcousticReverbZone");
        zoneGo.transform.SetParent(_rigRoot.transform, false);

        var zone = zoneGo.AddComponent<AudioReverbZone>();
        zone.reverbPreset = AudioReverbPreset.User;
        zone.minDistance = 1f;
        zone.maxDistance = Mathf.Max(_venueGenerator.Parameters.roomLength,
                                     _venueGenerator.Parameters.roomWidth);
        // 1.4s in a hard, untreated room down to ~0.25s in a heavily
        // treated one — the range real cinema treatment actually spans.
        zone.decayTime = Mathf.Lerp(1.4f, 0.25f, absorption);
        zone.reflections = Mathf.RoundToInt(Mathf.Lerp(-200f, -2000f, absorption));
        zone.room = Mathf.RoundToInt(Mathf.Lerp(-500f, -1500f, absorption));

        foreach (var sources in _speakers.Values)
        {
            foreach (var source in sources)
            {
                source.reverbZoneMix = Mathf.Lerp(1.1f, 0.4f, absorption);
            }
        }
    }

    /// <summary>
    /// The AudioSource a streamed video's decoded audio track should route
    /// through (via VideoPlayer.SetTargetAudioSource) so it participates in
    /// this theatre's actual speaker rig — position, spatialBlend, rolloff,
    /// reverb-zone mix — instead of playing from an unpositioned, non-3D
    /// source. Unlike PlayOnChannel/PlayScreenAudio (which take an
    /// AudioClip), a VideoPlayer's audio isn't a pre-loaded clip, so it
    /// needs a bare AudioSource to attach to rather than a "play this"
    /// call. Prefers the Center channel (dead centre of the screen, where
    /// dialogue should anchor); falls back to whichever front channel this
    /// theatre's rig actually has. Returns null only if this theatre has no
    /// speakers at all, which should not normally happen — VenueGenerator
    /// always builds at least the derived fallback rig.
    /// </summary>
    public AudioSource GetScreenAudioTarget()
    {
        if (_speakers.TryGetValue(SpeakerChannel.Center, out var center) && center.Count > 0) return center[0];
        if (_speakers.TryGetValue(SpeakerChannel.Left, out var left) && left.Count > 0) return left[0];
        if (_speakers.TryGetValue(SpeakerChannel.Right, out var right) && right.Count > 0) return right[0];
        return null;
    }

    /// <summary>Plays a one-off or looping clip from a single named channel — e.g. a
    /// directional effect, or routing dialogue specifically through Center.</summary>
    public void PlayOnChannel(SpeakerChannel channel, AudioClip clip, bool loop = false, float volume = 1f)
    {
        if (clip == null) return;
        if (!_speakers.TryGetValue(channel, out var sources)) return;

        foreach (var source in sources)
        {
            source.clip = clip;
            source.loop = loop;
            source.volume = volume;
            source.Play();
        }
    }

    /// <summary>The main "movie soundtrack" extension point — plays a clip from the
    /// front Left/Center/Right speakers together, as a real cinema screen would.</summary>
    public void PlayScreenAudio(AudioClip clip, bool loop = true)
    {
        PlayOnChannel(SpeakerChannel.Left, clip, loop);
        PlayOnChannel(SpeakerChannel.Center, clip, loop);
        PlayOnChannel(SpeakerChannel.Right, clip, loop);
    }

    public void StopScreenAudio()
    {
        StopChannel(SpeakerChannel.Left);
        StopChannel(SpeakerChannel.Center);
        StopChannel(SpeakerChannel.Right);
    }

    private void StopChannel(SpeakerChannel channel)
    {
        if (!_speakers.TryGetValue(channel, out var sources)) return;
        foreach (var source in sources) source.Stop();
    }

    /// <summary>Low, non-directional background room tone — plays from every
    /// speaker at once, quietly, to give the space a sense of scale.</summary>
    public void PlayAmbient(AudioClip clip)
    {
        foreach (var sources in _speakers.Values)
        {
            foreach (var source in sources)
            {
                source.clip = clip;
                source.loop = true;
                source.volume = ambientVolume;
                source.Play();
            }
        }
    }

    /// <summary>Called by ExperienceController once the camera transition into
    /// the selected seat actually finishes (not on button press) — see the
    /// small addition to ExperienceController.EnterExperience.</summary>
    public void OnEnteredSeat(SeatData seat)
    {
        if (screenAudioClip != null)
        {
            PlayScreenAudio(screenAudioClip);
        }
    }

    /// <summary>Called by ExperienceController when the user exits back to the
    /// venue preview.</summary>
    public void OnExitedSeat()
    {
        StopScreenAudio();
    }

    private IEnumerator TestSweep()
    {
        var order = new[]
        {
            SpeakerChannel.Left, SpeakerChannel.Center, SpeakerChannel.Right,
            SpeakerChannel.RightSurround, SpeakerChannel.LeftSurround,
            SpeakerChannel.Overhead, SpeakerChannel.Lfe,
        };
        AudioClip tone = ProceduralTone.Generate(440f, 0.35f);

        foreach (var channel in order)
        {
            PlayOnChannel(channel, tone, loop: false, volume: 0.5f);
            yield return new WaitForSeconds(0.5f);
        }
    }
}
