#include <cstdint>
#include "audio_engine.h"

static AudioEngine *engine = nullptr;

// set the recording state for the audio recorder
extern "C" __attribute__((visibility("default"))) __attribute__((used))
void native_audio_create() {
    if (!engine) engine = new AudioEngine();
}

// set the recording state for the audio recorder
extern "C" __attribute__((visibility("default"))) __attribute__((used))
void native_audio_start() {
    if (engine) engine->start();
}`