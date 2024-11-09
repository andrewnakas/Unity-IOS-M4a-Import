using UnityEngine;
using System.Runtime.InteropServices;
using System;
using System.Collections;

public class M4AAudioLoader : MonoBehaviour
{
    // Plugin name matches what we'll define in the native code
    private const string PluginName = "__Internal";

    // Import native iOS functions
    [DllImport(PluginName)]
    private static extern IntPtr LoadM4AFromPath(string path);
    
    [DllImport(PluginName)]
    private static extern int GetAudioDataLength(IntPtr audioData);
    
    [DllImport(PluginName)]
    private static extern void GetAudioData(IntPtr audioData, float[] buffer, int length);
    
    [DllImport(PluginName)]
    private static extern int GetSampleRate(IntPtr audioData);
    
    [DllImport(PluginName)]
    private static extern int GetChannelCount(IntPtr audioData);
    
    [DllImport(PluginName)]
    private static extern void ReleaseAudioData(IntPtr audioData);

    // Main function to load M4A file into AudioClip
    public static AudioClip LoadM4A(string path)
    {
        IntPtr audioData = LoadM4AFromPath(path);
        if (audioData == IntPtr.Zero)
        {
            Debug.LogError("Failed to load M4A file");
            return null;
        }

        try
        {
            int length = GetAudioDataLength(audioData);
            int sampleRate = GetSampleRate(audioData);
            int channels = GetChannelCount(audioData);

            float[] buffer = new float[length];
            GetAudioData(audioData, buffer, length);

            AudioClip clip = AudioClip.Create("M4AClip", length / channels, channels, sampleRate, false);
            clip.SetData(buffer, 0);

            return clip;
        }
        finally
        {
            ReleaseAudioData(audioData);
        }
    }
}