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
/// NOT yet wired to an admin's actual configured SpeakerModel positions —
/// Flutter doesn't send theatre configuration to Unity at all yet (a
/// separate, larger piece of work). This produces a reasonable default
/// 7-speaker layout (L/C/R front, side surrounds, one overhead, one LFE)
/// scaled to the room in the meantime, and every method here takes a
/// [SpeakerChannel] rather than a raw AudioSource — so swapping the
/// positioning logic for admin-configured positions later never has to
/// touch anything that calls this class.
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
    private readonly Dictionary<SpeakerChannel, AudioSource> _speakers = new Dictionary<SpeakerChannel, AudioSource>();

    private void Awake()
    {
        Instance = this;
        _venueGenerator = GetComponent<VenueGenerator>();
    }

    private void Start()
    {
        BuildSpeakerRig(_venueGenerator.Parameters);

        if (ambientClip != null)
        {
            PlayAmbient(ambientClip);
        }

        if (playStartupTestSweep)
        {
            StartCoroutine(TestSweep());
        }
    }

    private void BuildSpeakerRig(VenueParameters p)
    {
        var root = new GameObject("SpatialAudioRig");
        root.transform.SetParent(transform, false);

        float halfWidth = p.roomWidth / 2f;
        float screenZ = p.screenDistanceFromFrontWall;
        const float earHeight = 1.4f; // roughly average seated ear height across seat types

        AddSpeaker(root.transform, SpeakerChannel.Left, new Vector3(-halfWidth * 0.35f, earHeight + 1f, screenZ), p);
        AddSpeaker(root.transform, SpeakerChannel.Center, new Vector3(0, earHeight + 1f, screenZ), p);
        AddSpeaker(root.transform, SpeakerChannel.Right, new Vector3(halfWidth * 0.35f, earHeight + 1f, screenZ), p);

        float midDepth = p.firstRowDistanceFromScreen + ((p.rows - 1) * p.rowSpacing * 0.5f);
        AddSpeaker(root.transform, SpeakerChannel.LeftSurround, new Vector3(-halfWidth * 0.9f, earHeight, midDepth), p);
        AddSpeaker(root.transform, SpeakerChannel.RightSurround, new Vector3(halfWidth * 0.9f, earHeight, midDepth), p);

        float rearDepth = p.firstRowDistanceFromScreen + ((p.rows - 1) * p.rowSpacing);
        AddSpeaker(root.transform, SpeakerChannel.Overhead, new Vector3(0, p.roomHeight - 1f, rearDepth * 0.6f), p);

        // LFE: near-field, wide max distance — bass is felt more than
        // localized. A true dedicated low-frequency-only bus would need an
        // AudioMixer with a lowpass send, which felt like unnecessary
        // complexity/weight for this pass (spec: keep WebGL lightweight).
        AddSpeaker(root.transform, SpeakerChannel.Lfe, new Vector3(0, 0.3f, screenZ), p, maxDistanceOverride: p.roomLength * 1.5f);
    }

    private void AddSpeaker(Transform parent, SpeakerChannel channel, Vector3 localPosition, VenueParameters p, float? maxDistanceOverride = null)
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

        _speakers[channel] = source;
    }

    /// <summary>Plays a one-off or looping clip from a single named channel — e.g. a
    /// directional effect, or routing dialogue specifically through Center.</summary>
    public void PlayOnChannel(SpeakerChannel channel, AudioClip clip, bool loop = false, float volume = 1f)
    {
        if (clip == null) return;
        if (!_speakers.TryGetValue(channel, out var source)) return;

        source.clip = clip;
        source.loop = loop;
        source.volume = volume;
        source.Play();
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
        if (_speakers.TryGetValue(channel, out var source)) source.Stop();
    }

    /// <summary>Low, non-directional background room tone — plays from every
    /// speaker at once, quietly, to give the space a sense of scale.</summary>
    public void PlayAmbient(AudioClip clip)
    {
        foreach (var source in _speakers.Values)
        {
            source.clip = clip;
            source.loop = true;
            source.volume = ambientVolume;
            source.Play();
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
