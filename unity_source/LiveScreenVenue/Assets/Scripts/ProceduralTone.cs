using UnityEngine;

/// <summary>
/// Generates a short sine-wave tone entirely in code, with a soft fade
/// in/out to avoid audible clicks. Exists purely so SpatialAudioManager's
/// diagnostic speaker sweep works out of the box, without needing any
/// actual audio asset files shipped alongside this project — this sandbox
/// has no way to author real audio assets, and a real project may not have
/// placeholder sound effects on hand yet either.
/// </summary>
public static class ProceduralTone
{
    public static AudioClip Generate(float frequencyHz, float durationSeconds, float volume = 0.4f, int sampleRate = 44100)
    {
        int sampleCount = Mathf.Max(1, Mathf.RoundToInt(durationSeconds * sampleRate));
        var clip = AudioClip.Create($"ProceduralTone_{frequencyHz}Hz", sampleCount, 1, sampleRate, false);

        float[] samples = new float[sampleCount];
        float fadeSeconds = Mathf.Min(0.05f, durationSeconds * 0.2f);

        for (int i = 0; i < sampleCount; i++)
        {
            float t = i / (float)sampleRate;
            float fadeIn = Mathf.Clamp01(t / fadeSeconds);
            float fadeOut = Mathf.Clamp01((durationSeconds - t) / fadeSeconds);
            float envelope = Mathf.Min(fadeIn, fadeOut);

            samples[i] = Mathf.Sin(2f * Mathf.PI * frequencyHz * t) * volume * envelope;
        }

        clip.SetData(samples, 0);
        return clip;
    }
}
