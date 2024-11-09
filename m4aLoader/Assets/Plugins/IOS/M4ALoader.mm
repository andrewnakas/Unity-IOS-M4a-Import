#import <AVFoundation/AVFoundation.h>

// Helper function to convert AVAudioPCMBuffer to float array
void ConvertAudioBufferToFloatArray(AVAudioPCMBuffer* pcmBuffer, float* outputBuffer) {
    float* channelData = pcmBuffer.floatChannelData[0];
    int frameLength = (int)pcmBuffer.frameLength;
    int channels = (int)pcmBuffer.format.channelCount;
    
    memcpy(outputBuffer, channelData, frameLength * channels * sizeof(float));
}

extern "C" {
    void* LoadM4AFromPath(const char* path) {
        NSString* filePath = [NSString stringWithUTF8String:path];
        NSURL* fileURL = [NSURL fileURLWithPath:filePath];
        
        NSError* error = nil;
        AVAudioFile* audioFile = [[AVAudioFile alloc] initForReading:fileURL error:&error];
        if (error) {
            NSLog(@"Error loading audio file: %@", error);
            return NULL;
        }
        
        AVAudioFormat* format = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                                sampleRate:audioFile.fileFormat.sampleRate
                                                                channels:audioFile.fileFormat.channelCount
                                                                interleaved:NO];
        
        AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format
                                                              frameCapacity:(AVAudioFrameCount)audioFile.length];
        
        [audioFile readIntoBuffer:buffer error:&error];
        if (error) {
            NSLog(@"Error reading audio file: %@", error);
            return NULL;
        }
        
        return (__bridge_retained void*)buffer;
    }
    
    int GetAudioDataLength(void* audioData) {
        AVAudioPCMBuffer* buffer = (__bridge AVAudioPCMBuffer*)audioData;
        return (int)(buffer.frameLength * buffer.format.channelCount);
    }
    
    void GetAudioData(void* audioData, float* outputBuffer, int length) {
        AVAudioPCMBuffer* buffer = (__bridge AVAudioPCMBuffer*)audioData;
        ConvertAudioBufferToFloatArray(buffer, outputBuffer);
    }
    
    int GetSampleRate(void* audioData) {
        AVAudioPCMBuffer* buffer = (__bridge AVAudioPCMBuffer*)audioData;
        return (int)buffer.format.sampleRate;
    }
    
    int GetChannelCount(void* audioData) {
        AVAudioPCMBuffer* buffer = (__bridge AVAudioPCMBuffer*)audioData;
        return (int)buffer.format.channelCount;
    }
    
    void ReleaseAudioData(void* audioData) {
        if (audioData) {
            CFRelease(audioData);
        }
    }
}