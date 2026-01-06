#ifndef COMPONENTS_H
#define COMPONENTS_H

#include <cmath>

// 3-to-8 Decoder (like 74HC138)
class Decoder3to8 {
public:
    bool output[8];

    void decode(int addr) {
        for (int i = 0; i < 8; i++)
            output[i] = (i != (addr & 0x7));  // active LOW
    }
};

// PNP Transistor Switch Array
class TransistorArray {
public:
    bool sw[8];

    void update(const bool decoder_out[8]) {
        for (int i = 0; i < 8; i++)
            sw[i] = !decoder_out[i];  // PNP: active when input LOW
    }
};

// Resistor Array for note frequencies
class ResistorArray {
public:
    double R[8];
    static constexpr double C = 100e-9;

    ResistorArray() {
        double freqs[] = {262, 294, 330, 349, 392, 440, 494, 523};
        for (int i = 0; i < 8; i++)
            R[i] = 1.4 / (freqs[i] * C);
    }

    double select(const bool sw[8]) {
        for (int i = 0; i < 8; i++)
            if (sw[i]) return R[i];
        return R[0];
    }
};

// 555 Timer Astable Mode
class Timer555 {
private:
    double r1, r2, c1, t;

public:
    Timer555() : r1(10000), r2(10000), c1(100e-9), t(0) {}

    double frequency() { return 1.4 / ((r1 + 2.0 * r2) * c1); }
    double dutyCycle() { return (r1 + r2) / (r1 + 2.0 * r2); }

    bool output() {
        double period = 1.0 / frequency();
        return fmod(t, period) / period < dutyCycle();
    }

    bool step(double R1, double R2, double C, double dt) {
        r1 = R1; r2 = R2; c1 = C;
        t += dt;
        return output();
    }

    void reset() { t = 0; }

    static double calcFrequency(double R1, double R2, double C) {
        return 1.4 / ((R1 + 2.0 * R2) * C);
    }
};

#endif
