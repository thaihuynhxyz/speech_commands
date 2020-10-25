//
// Created by thaihuynhxyz on 10/25/20.
//

#include "audio_engine.h"
#include "logging_macros.h"

using namespace oboe;

void AudioEngine::start() {
    AudioStreamBuilder builder;
    builder.setDirection(Direction::Input);
    builder.setPerformanceMode(PerformanceMode::LowLatency);

    AudioStream *stream;
    Result r = builder.openStream(&stream);
    if (r != Result::OK) {
        LOGE("Error opening stream: %s", convertToText(r));
    }

    r = stream->requestStart();
    if (r != Result::OK) {
        LOGE("Error starting stream: %s", convertToText(r));
    }

    constexpr int kMillisecondsToRecord = 2;
    const auto requestedFrames = (int32_t) (kMillisecondsToRecord *
                                            (stream->getSampleRate() / kMillisPerSecond));
    int16_t myBuffer[requestedFrames];

    constexpr int64_t kTimeoutValue = 3 * kNanosPerMillisecond;

    int framesRead;
    do {
        auto result = stream->read(myBuffer, stream->getBufferSizeInFrames(), 0);
        if (result != Result::OK) break;
        framesRead = result.value();
    } while (framesRead);

    isRecording = true;
    while (isRecording) {
        auto result = stream->read(myBuffer, requestedFrames, kTimeoutValue);

        if (result != Result::OK) {
            LOGD("Read %d frames", result.value());
        } else {
            LOGE("Error reading stream: %s", convertToText(result.error()));
        }
    }
    isRecording = false;

    stream->close();
}