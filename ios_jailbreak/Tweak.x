#include <AudioToolbox/AudioToolbox.h>
#include <substrate.h>
#include <dispatch/dispatch.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

static int g_socketFd = -1;
static struct sockaddr_in g_destAddr;
static dispatch_queue_t g_queue;

static void PSSetupSocket(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_queue = dispatch_queue_create("com.platicasay.audio", NULL);
        g_socketFd = socket(AF_INET, SOCK_DGRAM, 0);
        memset(&g_destAddr, 0, sizeof(g_destAddr));
        g_destAddr.sin_family = AF_INET;
        g_destAddr.sin_port = htons(48123);
        inet_pton(AF_INET, "127.0.0.1", &g_destAddr.sin_addr);
    });
}

static void PSSendPcm(const void *data, UInt32 length) {
    if (g_socketFd < 0 || !data || length == 0) return;
    sendto(g_socketFd, data, length, 0,
           (struct sockaddr *)&g_destAddr, sizeof(g_destAddr));
}

static OSStatus (*orig_AURenderCallback)(void *, AudioUnitRenderActionFlags *,
    const AudioTimeStamp *, UInt32, UInt32, AudioBufferList *);

%group CallAudioHook

%hookf(OSStatus, AudioUnitRender, AudioUnit inUnit,
       AudioUnitRenderActionFlags *ioActionFlags,
       const AudioTimeStamp *inTimeStamp,
       UInt32 inBusNumber,
       UInt32 inNumberFrames,
       AudioBufferList *ioData) {
    OSStatus status = %orig(inUnit, ioActionFlags, inTimeStamp,
                            inBusNumber, inNumberFrames, ioData);
    if (status == noErr && ioData && ioData->mNumberBuffers > 0) {
        PSSetupSocket();
        AudioBuffer buf = ioData->mBuffers[0];
        PSSendPcm(buf.mData, buf.mDataByteSize);
    }
    return status;
}

%end

%ctor {
    %init(CallAudioHook);
}
