//
// Created by thaihuynhxyz on 10/25/20.
//

#ifndef SPEECH_COMMANDS_AUDIO_ENGINE_H
#define SPEECH_COMMANDS_AUDIO_ENGINE_H

#include <oboe/Oboe.h>

class AudioEngine {
public:
    void start();

private:
    bool isRecording;
};


#endif //SPEECH_COMMANDS_AUDIO_ENGINE_H
