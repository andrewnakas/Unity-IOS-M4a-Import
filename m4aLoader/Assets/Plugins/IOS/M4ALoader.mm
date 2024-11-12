#import <AVFoundation/AVFoundation.h>

// Helper function to convert AVAudioPCMBuffer to float array
void ConvertAudioBufferToFloatArray(AVAudioPCMBuffer* pcmBuffer, float* outputBuffer) {
    int frameLength = (int)pcmBuffer.frameLength;
    int channels = (int)pcmBuffer.format.channelCount;
    
    if (channels == 1) {
        // Mono data - duplicate to both channels of the interleaved output
        float* sourceData = pcmBuffer.floatChannelData[0];
        for (int i = 0; i < frameLength; i++) {
            outputBuffer[i * 2] = sourceData[i];       // Left channel
            outputBuffer[i * 2 + 1] = sourceData[i];   // Right channel
        }
    } else if (channels == 2 && pcmBuffer.floatChannelData[1] != NULL) {
        // Stereo data - interleave the channels
        float* leftChannel = pcmBuffer.floatChannelData[0];
        float* rightChannel = pcmBuffer.floatChannelData[1];
        for (int i = 0; i < frameLength; i++) {
            outputBuffer[i * 2] = leftChannel[i];
            outputBuffer[i * 2 + 1] = rightChannel[i];
        }
    } else {
        // Handle unexpected channel configurations
        NSLog(@"Warning: Unexpected channel configuration. Defaulting to silence.");
        int totalSamples = frameLength * 2; // Always output stereo
        for (int i = 0; i < totalSamples; i++) {
            outputBuffer[i] = 0.0f;
        }
    }
}

extern "C" {
    void* LoadM4AFromPath(const char* path) {
        if (!path) {
            NSLog(@"Error: Null path provided to LoadM4AFromPath");
            return NULL;
        }
        
        NSString* filePath = [NSString stringWithUTF8String:path];
        NSURL* fileURL = [NSURL fileURLWithPath:filePath];
        
        NSLog(@"Loading audio file from path: %@", filePath);
        
        NSError* error = nil;
        AVAudioFile* audioFile = [[AVAudioFile alloc] initForReading:fileURL error:&error];
        if (error) {
            NSLog(@"Error loading audio file: %@", error);
            return NULL;
        }
        
        // Get the original format details
        AVAudioFormat* originalFormat = audioFile.processingFormat;
        NSLog(@"Original format - Sample Rate: %.0f Hz, Channels: %d", 
              originalFormat.sampleRate,
              (int)originalFormat.channelCount);
        
        // Create stereo format
        AVAudioFormat* stereoFormat = [[AVAudioFormat alloc] 
                                     initWithCommonFormat:AVAudioPCMFormatFloat32
                                     sampleRate:originalFormat.sampleRate
                                     channels:2
                                     interleaved:NO];
        
        if (!stereoFormat) {
            NSLog(@"Error: Failed to create stereo audio format");
            return NULL;
        }
        
        // Create buffer with stereo format
        AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] 
                                  initWithPCMFormat:stereoFormat
                                  frameCapacity:(AVAudioFrameCount)audioFile.length];
        
        if (!buffer) {
            NSLog(@"Error: Failed to create audio buffer");
            return NULL;
        }
        
        // Read the file into the buffer
        if (![audioFile readIntoBuffer:buffer error:&error]) {
            NSLog(@"Error reading audio file into buffer: %@", error);
            return NULL;
        }
        
        // Verify buffer contents
        if (!buffer.floatChannelData) {
            NSLog(@"Error: No channel data in buffer");
            return NULL;
        }
        
        NSLog(@"Successfully loaded audio file:");
        NSLog(@"- Frame Length: %d", (int)buffer.frameLength);
        NSLog(@"- Channel Count: %d", (int)buffer.format.channelCount);
        NSLog(@"- Sample Rate: %.0f Hz", buffer.format.sampleRate);
        
        return (__bridge_retained void*)buffer;
    }
    
    int GetAudioDataLength(void* audioData) {
        if (!audioData) {
            NSLog(@"Error: Null audio data in GetAudioDataLength");
            return 0;
        }
        
        AVAudioPCMBuffer* buffer = (__bridge AVAudioPCMBuffer*)audioData;
        // Return total number of samples (frames * channels)
        return (int)(buffer.frameLength * buffer.format.channelCount);
    }
    
    void GetAudioData(void* audioData, float* outputBuffer, int length) {
        if (!audioData || !outputBuffer) {
            NSLog(@"Error: Null pointer in GetAudioData");
            return;
        }
        
        AVAudioPCMBuffer* buffer = (__bridge AVAudioPCMBuffer*)audioData;
        if (!buffer.floatChannelData) {
            NSLog(@"Error: No channel data available");
            return;
        }
        
        ConvertAudioBufferToFloatArray(buffer, outputBuffer);
    }
    
    int GetSampleRate(void* audioData) {
        if (!audioData) {
            NSLog(@"Error: Null audio data in GetSampleRate");
            return 44100; // Default sample rate as fallback
        }
        
        AVAudioPCMBuffer* buffer = (__bridge AVAudioPCMBuffer*)audioData;
        return (int)buffer.format.sampleRate;
    }
    
    int GetChannelCount(void* audioData) {
        if (!audioData) {
            NSLog(@"Error: Null audio data in GetChannelCount");
            return 2; // Default to stereo as fallback
        }
        
        AVAudioPCMBuffer* buffer = (__bridge AVAudioPCMBuffer*)audioData;
        return (int)buffer.format.channelCount;
    }
    
    void ReleaseAudioData(void* audioData) {
        if (audioData) {
            CFRelease(audioData);
        }
    }
}
