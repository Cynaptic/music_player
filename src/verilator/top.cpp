// Verilator testbench - simulates surrounding circuit

#include <verilated.h>
#include "Vmusic_player.h"
#include "components.h"
#include "sound.h"
#include <iostream>
#include <vector>

#define CLK_FREQ    50000000
#define SAMPLE_RATE 44100
#define SIM_TIME_MS 30000

const char* NOTE_NAMES[] = {"Do", "Re", "Mi", "Fa", "Sol", "La", "Si", "Do'"};

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // Digital
    Vmusic_player* dut = new Vmusic_player;

    // Surrounding circuit
    Decoder3to8 decoder;
    TransistorArray transistors;
    ResistorArray resistors;
    Timer555 timer;

    const double C = 100e-9;
    const double R1_ratio = 0.1;
    const uint64_t cycles_per_ms = CLK_FREQ / 1000;
    const uint64_t total_cycles = (uint64_t)SIM_TIME_MS * cycles_per_ms;
    const uint64_t cycles_per_sample = CLK_FREQ / SAMPLE_RATE;
    const double dt = 1.0 / SAMPLE_RATE;

    std::cout << "=== Music Player Simulation ===" << std::endl;

    std::vector<int16_t> audio;
    audio.reserve(SIM_TIME_MS * SAMPLE_RATE / 1000);

    // Initialize audio
    sound_init();

    // Reset
    dut->clk = 0; dut->rst_n = 0; dut->play = 0;
    for (int i = 0; i < 10; i++) { dut->clk = !dut->clk; dut->eval(); }
    dut->rst_n = 1; dut->play = 1;

    uint64_t cycle = 0, next_sample = 0;
    int last_addr = -1;
    int current_freq = 0;
    uint64_t note_start_cycle = 0;

    while (cycle < total_cycles && !dut->end_flag) {
        dut->clk = !dut->clk;
        dut->eval();

        if (dut->clk) {
            cycle++;

            // Surrounding circuit: decoder -> transistors -> resistors
            decoder.decode(dut->note_out);
            transistors.update(decoder.output);
            double R = resistors.select(transistors.sw);

            // Note change detection
            if (dut->addr_out != last_addr) {
                // Calculate note duration for sleep
                uint64_t note_duration_ms = 0;
                if (last_addr >= 0) {
                    note_duration_ms = (cycle - note_start_cycle) / cycles_per_ms;
                }

                timer.reset();
                current_freq = (int)Timer555::calcFrequency(R * R1_ratio, R * (1 - R1_ratio) / 2, C);
                std::cout << "[" << cycle / cycles_per_ms << "ms] "
                         << NOTE_NAMES[dut->note_out] << " (" << current_freq << "Hz)" << std::endl;
                last_addr = dut->addr_out;
                note_start_cycle = cycle;

                // Update UI and play sound
                sound_update_ui(cycle / cycles_per_ms, SIM_TIME_MS, dut->note_out, dut->rest_out, current_freq);
                circuit_update(dut->note_out, dut->rest_out);
                if (dut->rest_out) {
                    sound_stop();
                } else {
                    sound_play(current_freq);
                }
                yield_to_browser();
            }

            // Audio sampling (for WAV file)
            if (cycle >= next_sample) {
                int16_t sample = 0;
                if (!dut->rest_out) {
                    bool out = timer.step(R * R1_ratio, R * (1 - R1_ratio) / 2, C, dt);
                    sample = out ? 9830 : -9830;
                }
                audio.push_back(sample);
                next_sample += cycles_per_sample;
            }
        }
    }

    sound_stop();
    sound_update_ui(SIM_TIME_MS, SIM_TIME_MS, 0, 1, 0);

    std::cout << "Done. Samples: " << audio.size() << std::endl;
    writeWAV(WAV_OUTPUT_PATH, audio, SAMPLE_RATE);

    delete dut;
    return 0;
}
