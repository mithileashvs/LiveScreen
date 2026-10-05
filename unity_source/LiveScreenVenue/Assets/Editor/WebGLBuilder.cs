using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

public static class WebGLBuilder
{
    public static void Build()
    {
        string[] scenes = new string[] { "Assets/Scenes/SampleScene.unity" };
        string outputPath = Path.GetFullPath(Path.Combine(Application.dataPath, "../../../web/unity_venue"));
        Debug.Log($"[WebGLBuilder] Starting WebGL build to: {outputPath}");

        BuildPlayerOptions buildPlayerOptions = new BuildPlayerOptions
        {
            scenes = scenes,
            locationPathName = outputPath,
            target = BuildTarget.WebGL,
            options = BuildOptions.None
        };

        BuildReport report = BuildPipeline.BuildPlayer(buildPlayerOptions);
        BuildSummary summary = report.summary;

        if (summary.result == BuildResult.Succeeded)
        {
            Debug.Log($"[WebGLBuilder] WebGL build SUCCEEDED: {summary.totalSize} bytes in {summary.totalTime.TotalSeconds:F1}s");
        }
        else
        {
            Debug.LogError($"[WebGLBuilder] WebGL build FAILED: result={summary.result}, errors={summary.totalErrors}");
            EditorApplication.Exit(1);
        }
    }
}
