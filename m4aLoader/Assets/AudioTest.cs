using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
public class AudioTest : MonoBehaviour
{
   
    // Start is called before the first frame update
    void Start()
    {
        Load();
    }

    public void Load(){

        // Assuming the M4A file is in your StreamingAssets folder
string path = Path.Combine(Application.streamingAssetsPath, "unitym4a.m4a");
AudioClip clip = M4AAudioLoader.LoadM4A(path);

// Use the audio clip
AudioSource audioSource = GetComponent<AudioSource>();
audioSource.clip = clip;
audioSource.Play();
    }

    // Update is called once per frame
    void Update()
    {
        
    }
    
}
