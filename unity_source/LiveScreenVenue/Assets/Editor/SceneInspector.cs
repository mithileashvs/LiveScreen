using System.Text;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

public static class SceneInspector
{
    public static void InspectCinemaScreenAndScene()
    {
        EditorSceneManager.OpenScene("Assets/Scenes/SampleScene.unity");
        StringBuilder sb = new StringBuilder();
        sb.AppendLine("==================================================");
        sb.AppendLine("UNITY SCENE & CINEMA SCREEN INSPECTION REPORT");
        sb.AppendLine("==================================================");

        // 1. Inspect all Root GameObjects
        sb.AppendLine("\n--- ROOT GAMEOBJECTS IN SCENE ---");
        GameObject[] roots = EditorSceneManager.GetActiveScene().GetRootGameObjects();
        foreach (var r in roots)
        {
            sb.AppendLine($"Root: {r.name}, Active: {r.activeSelf}");
            DumpHierarchy(r, sb, "  ");
        }

        // 2. Inspect Directional Light
        sb.AppendLine("\n--- DIRECTIONAL LIGHT IN SCENE ---");
        Light[] allLights = Object.FindObjectsByType<Light>(FindObjectsSortMode.None);
        foreach (var l in allLights)
        {
            sb.AppendLine($"Light '{l.name}' (type: {l.type}, enabled: {l.enabled}, intensity: {l.intensity}, color: {l.color}, range: {l.range}, spotAngle: {l.spotAngle})");
            sb.AppendLine($"  Position: {l.transform.position}, Rotation: {l.transform.eulerAngles}, Forward: {l.transform.forward}");
        }

        // 3. Generate Venue using VenueParameters to inspect generated Screen & Lights
        sb.AppendLine("\n--- GENERATING VENUE VIA ScreenGenerator & VenueParameters ---");
        VenueParameters p = new VenueParameters();
        GameObject tempParent = new GameObject("TempParent");
        try
        {
            GameObject screenObj = ScreenGenerator.Generate(tempParent.transform, p);
            sb.AppendLine($"Generated Screen GameObject: '{screenObj.name}'");
            sb.AppendLine($"  Local Position: {screenObj.transform.localPosition}");
            sb.AppendLine($"  Local Rotation: {screenObj.transform.localRotation.eulerAngles}");
            sb.AppendLine($"  Local Scale: {screenObj.transform.localScale}");

            MeshFilter mf = screenObj.GetComponent<MeshFilter>();
            if (mf != null && mf.sharedMesh != null)
            {
                Mesh m = mf.sharedMesh;
                sb.AppendLine($"  Mesh name: '{m.name}', Submesh count: {m.subMeshCount}, Vertex count: {m.vertexCount}");
                sb.AppendLine($"  Local Bounds: center={m.bounds.center}, size={m.bounds.size}, extents={m.bounds.extents}");
                sb.AppendLine($"  Effective World Bounds Size: Vector3({m.bounds.size.x * screenObj.transform.localScale.x}, {m.bounds.size.y * screenObj.transform.localScale.y}, {m.bounds.size.z * screenObj.transform.localScale.z})");
                sb.AppendLine($"  Screen Aspect Ratio: {(m.bounds.size.x * screenObj.transform.localScale.x) / (m.bounds.size.y * screenObj.transform.localScale.y):F4}");

                // Inspect UVs of front face (vertices where normal is pointing roughly forward)
                Vector3[] verts = m.vertices;
                Vector3[] normals = m.normals;
                Vector2[] uvs = m.uv;
                sb.AppendLine("  Front face vertices & UVs (where normal.z > 0.5):");
                for (int i = 0; i < verts.Length; i++)
                {
                    if (normals[i].z > 0.5f)
                    {
                        sb.AppendLine($"    v[{i}]: pos={verts[i]}, normal={normals[i]}, uv={uvs[i]}");
                    }
                }
            }

            MeshRenderer mr = screenObj.GetComponent<MeshRenderer>();
            if (mr != null)
            {
                sb.AppendLine($"  MeshRenderer: materials count={mr.sharedMaterials.Length}");
                for (int i = 0; i < mr.sharedMaterials.Length; i++)
                {
                    Material mat = mr.sharedMaterials[i];
                    if (mat != null)
                    {
                        sb.AppendLine($"    Mat[{i}]: '{mat.name}', Shader='{mat.shader.name}', Color={mat.color}");
                        if (mat.HasProperty("_Glossiness")) sb.AppendLine($"      _Glossiness={mat.GetFloat("_Glossiness")}");
                        if (mat.HasProperty("_Metallic")) sb.AppendLine($"      _Metallic={mat.GetFloat("_Metallic")}");
                        if (mat.HasProperty("_EmissionColor")) sb.AppendLine($"      _EmissionColor={mat.GetColor("_EmissionColor")}");
                    }
                }
            }

            // Inspect ScreenGlowLight
            Transform glowLight = tempParent.transform.Find("ScreenGlowLight");
            if (glowLight != null)
            {
                Light l = glowLight.GetComponent<Light>();
                sb.AppendLine($"  ScreenGlowLight: Position={glowLight.localPosition}, Rotation={glowLight.localRotation.eulerAngles}, Forward={glowLight.forward}");
                sb.AppendLine($"    Light properties: type={l.type}, color={l.color}, intensity={l.intensity}, spotAngle={l.spotAngle}, range={l.range}");
                sb.AppendLine($"    Screen is at Z={screenObj.transform.localPosition.z}, Light is at Z={glowLight.localPosition.z}");
                float dotToScreen = Vector3.Dot(glowLight.forward, (screenObj.transform.position - glowLight.position).normalized);
                sb.AppendLine($"    Dot product of Light.forward toward Screen center: {dotToScreen:F3} (1.0 = pointing directly AT screen!)");
            }

            // Inspect ScreenBezel
            Transform bezel = tempParent.transform.Find("ScreenBezel");
            if (bezel != null)
            {
                sb.AppendLine($"  ScreenBezel: Position={bezel.localPosition}, Scale={bezel.localScale}");
            }
        }
        finally
        {
            Object.DestroyImmediate(tempParent);
        }

        sb.AppendLine("==================================================");
        Debug.Log(sb.ToString());
    }

    private static void DumpHierarchy(GameObject go, StringBuilder sb, string indent)
    {
        for (int i = 0; i < go.transform.childCount; i++)
        {
            Transform child = go.transform.GetChild(i);
            sb.AppendLine($"{indent}- {child.name} (active: {child.gameObject.activeSelf})");
            DumpHierarchy(child.gameObject, sb, indent + "  ");
        }
    }
}
