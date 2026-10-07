using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Generates VISUAL-ONLY cinema speaker objects inside the 3D theatre.
///
/// Principles:
/// 1. These objects are purely for visual representation so the Unity auditorium
///    visually resembles the real theatre.
/// 2. Visual speaker GameObjects have NO AudioSource, NO audio channel bindings,
///    and NO spatial audio routing.
/// 3. The LiveScreen spatial audio system runs independently in SpatialAudioManager.
/// </summary>
public static class SpeakerGenerator
{
    public static GameObject Generate(Transform parent, VenueParameters p, SpeakerPlacement[] placements)
    {
        var root = new GameObject("VisualSpeakers");
        root.transform.SetParent(parent, false);

        if (placements == null || placements.Length == 0)
        {
            return root;
        }

        float halfWidth = p.roomWidth * 0.5f;

        for (int i = 0; i < placements.Length; i++)
        {
            SpeakerPlacement sp = placements[i];
            if (sp == null) continue;

            string speakerName = string.IsNullOrEmpty(sp.name) ? $"VisualSpeaker_{i + 1}" : $"VisualSpeaker_{sp.name}";
            GameObject speakerObj = new GameObject(speakerName);
            speakerObj.transform.SetParent(root.transform, false);

            // Position at admin's saved coordinate
            Vector3 pos = sp.Position;
            // Ensure realistic wall-mount height if Y is unassigned
            if (pos.y <= 0.1f)
            {
                pos.y = Mathf.Clamp(p.roomHeight * 0.6f, 2.2f, 3.5f);
            }
            speakerObj.transform.localPosition = pos;

            // Orient naturally toward the auditorium:
            Quaternion rot;
            if (Mathf.Abs(sp.rotationY) > 0.01f)
            {
                rot = Quaternion.Euler(0f, sp.rotationY, 0f);
            }
            else if (pos.x < -halfWidth * 0.4f)
            {
                // Left wall: angled inward
                rot = Quaternion.Euler(0f, 75f, 0f);
            }
            else if (pos.x > halfWidth * 0.4f)
            {
                // Right wall: angled inward
                rot = Quaternion.Euler(0f, -75f, 0f);
            }
            else if (pos.z > p.roomLength * 0.6f)
            {
                // Rear wall: facing forward
                rot = Quaternion.Euler(0f, 180f, 0f);
            }
            else
            {
                // Front / Screen zone: facing audience
                rot = Quaternion.Euler(0f, 0f, 0f);
            }
            speakerObj.transform.localRotation = rot;

            // Build realistic cinema cabinet + driver mesh without any AudioSource
            SpeakerVisual.Build(speakerObj, sp.ToChannel(), sp.type);
        }

        Debug.Log($"[SpeakerGenerator] Generated {placements.Length} visual-only cinema speaker objects.");
        return root;
    }
}
