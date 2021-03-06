class Gendy extends Chugen {

    // fake init, for easy Chugin translation
    float m_minFreq;
    float m_maxFreq;
    float m_currentFreq;
    float m_pi;
    float m_invPi;
    float m_yVals[0];
    float m_xVals[0];
    float m_addValue;
    float m_currentValue;

    int m_seg;
    int m_count;
    int m_segEnd;
    int m_numSegments;

    // fake constructor, for easy Chugin translation
    fun void constructor() {
        0 => m_seg;

        400 => m_minFreq;
        600 => m_maxFreq;

        // for testing only
        100.1 => m_currentFreq;

        pi => m_pi;
        1.0/pi => m_invPi;
        0 => m_count;
        8 => m_numSegments;
    }

    fun float initVals() {
        m_yVals.size(m_numSegments);
        m_xVals.size(m_numSegments);
        for (0 => int i; i < m_numSegments; i++) {
            // ensures i is zero
            if (i > 0) {
                Math.random2f(-1.0, 1.0) => m_yVals[i];
            }
            (i + 1) * 1.0/m_numSegments => m_xVals[i];
        }
        m_yVals[0] => m_currentValue;
    }

    // set/get minFreq
    fun float minFreq(float f) {
        f => m_minFreq;
    }

    // set/get maxFreq
    fun float maxFreq(float f) {
        f => m_maxFreq;
    }

    // set/get numSegments
    fun float numSegments(int n) {
        n => m_numSegments;
    }

    // we don't really need a constructor call, but we will later on
    constructor();
    initVals();
    update(m_seg);

    // takes the excess of the input value and
    // reverts it back under the threshold created by
    // the max/min
    fun float mirror(float in, float min, float max) {
        if (in > max) {
            return max - (in % max);
        }
        else if (in < min) {
            return min - (in % min);
        }
        else {
            return in;
        }
    }

    // distributions, algebraic for testing
    fun float distribution(float in) {
        return in/Math.sqrt(1.0 + Math.pow(in, 2));
    }

    // updates every new segment, updates interpolation value (m_addValue)
    // need to start adding stochastic processes, currenly this is only
    // the update method for the interpolation values and segment sizes,
    // both of which should be robust to the stochastic implementation
    fun float update(int idx) {
        // test of the algebraic distribution
        if (idx > 0) {
            mirror(distribution(Math.random2f(-0.4, 0.4)) + m_yVals[idx], -1.0, 1.0) => m_yVals[idx];
        }

        if (idx > 0 && idx < m_numSegments - 1) {
            mirror(distribution(Math.random2f(-0.1, 0.1)) + m_xVals[idx], m_xVals[idx - 1], m_xVals[idx + 1]) => m_xVals[idx];
        }
        else if (idx == 0) {
            mirror(distribution(Math.random2f(-0.1, 0.1)) + m_xVals[idx], 0.0, m_xVals[idx + 1]) => m_xVals[idx];
        }
        else if (idx == m_numSegments - 1) {
            mirror(distribution(Math.random2f(-0.1, 0.1)) + m_xVals[idx], m_xVals[idx - 1], 1.0) => m_xVals[idx];
        }

        mirror(distribution(Math.random2f(-0.1, 0.1)) * m_currentFreq, m_minFreq, m_maxFreq) => m_currentFreq;

        // calculates segment length based on ratios
        if (idx == 0) {
            (m_xVals[idx] * m_currentFreq)$int => m_segEnd;
        }
        else {
            ((m_xVals[idx] - m_xVals[idx - 1]) * m_currentFreq)$int => m_segEnd;
        }

        // interpolation value update
        (m_yVals[(idx + 1) % m_numSegments] - m_yVals[idx])/m_segEnd => m_addValue;
    }

    // tick!
    fun float tick(float in) {
        // sample counter
        m_count++;

        // adds interpolated value if sample counter
        // is less than the number of samples in the current segment
        if (m_count < m_segEnd) {
            m_addValue +=> m_currentValue;
        }
        // updates interpolation and segment length if
        // sample counter is beyond segment length, resets counter
        else {
            (m_seg + 1) % m_numSegments => m_seg;
            m_yVals[m_seg] => m_currentValue;
            update(m_seg);
            0 => m_count;
        }

        // <<< m_currentValue, m_yVals[m_seg] >>>;
        return m_currentValue;
    }
}

Gendy g => dac;

g.minFreq(180);
g.maxFreq(200);
g.numSegments(8);
1::hour => now;
30::samp => now;
