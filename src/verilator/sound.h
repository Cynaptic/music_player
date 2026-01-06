#ifndef SOUND_H
#define SOUND_H

#include <fstream>
#include <vector>
#include <cstdint>
#include <string>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>

// Real-time audio: play note immediately via Web Audio API
EM_JS(void, sound_init, (), {
    if (!window.audioCtx) {
        window.audioCtx = new AudioContext();
        window.oscillator = null;
        window.gainNode = window.audioCtx.createGain();
        window.gainNode.connect(window.audioCtx.destination);
        window.gainNode.gain.value = 0.3;
    }
});

EM_JS(void, sound_play, (int freq), {
    if (!window.audioCtx) return;
    if (window.oscillator) {
        window.oscillator.frequency.setValueAtTime(freq, window.audioCtx.currentTime);
    } else {
        window.oscillator = window.audioCtx.createOscillator();
        window.oscillator.type = 'square';
        window.oscillator.frequency.value = freq;
        window.oscillator.connect(window.gainNode);
        window.oscillator.start();
    }
});

EM_JS(void, sound_stop, (), {
    if (window.oscillator) {
        window.oscillator.stop();
        window.oscillator.disconnect();
        window.oscillator = null;
    }
});

EM_JS(void, sound_update_ui, (int ms, int total_ms, int note, int rest, int freq), {
    if (window.onSimProgress) window.onSimProgress(ms, total_ms, note, rest, freq);
});

EM_JS(void, circuit_update, (int note, int rest), {
    if (window.onCircuitUpdate) window.onCircuitUpdate(note, rest);
});

EM_JS(void, sound_sleep_ms, (int ms), {
    // Handled by emscripten_sleep
});

inline void yield_to_browser() { emscripten_sleep(0); }

// Wrapper for web
extern int main(int, char**);
extern "C" {
    EMSCRIPTEN_KEEPALIVE
    int web_run() {
        return main(0, nullptr);
    }
}

#else
// Native stubs
inline void sound_init() {}
inline void sound_play(int) {}
inline void sound_stop() {}
inline void sound_update_ui(int, int, int, int, int) {}
inline void circuit_update(int, int) {}
inline void yield_to_browser() {}
#endif

// WAV file writing (for native and optional web download)
#ifdef __EMSCRIPTEN__
#define WAV_OUTPUT_PATH "/output.wav"
#else
#define WAV_OUTPUT_PATH "music_555.wav"
#endif

inline void writeWAV(const std::string& filename, const std::vector<int16_t>& samples, uint32_t sampleRate = 44100) {
    struct {
        char riff[4] = {'R', 'I', 'F', 'F'};
        uint32_t fileSize;
        char wave[4] = {'W', 'A', 'V', 'E'};
        char fmt[4] = {'f', 'm', 't', ' '};
        uint32_t fmtSize = 16;
        uint16_t audioFormat = 1;
        uint16_t numChannels = 1;
        uint32_t sampleRate;
        uint32_t byteRate;
        uint16_t blockAlign = 2;
        uint16_t bitsPerSample = 16;
        char data[4] = {'d', 'a', 't', 'a'};
        uint32_t dataSize;
    } header;

    header.sampleRate = sampleRate;
    header.byteRate = sampleRate * 2;
    header.dataSize = samples.size() * sizeof(int16_t);
    header.fileSize = 36 + header.dataSize;

    std::ofstream file(filename, std::ios::binary);
    file.write(reinterpret_cast<char*>(&header), sizeof(header));
    file.write(reinterpret_cast<const char*>(samples.data()), header.dataSize);
}

#endif
