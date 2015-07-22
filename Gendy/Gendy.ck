public class Gendy extends Chugen
{
  1 / pi => float inverse_pi;
  int x_idx, y_idx;

  // input parameters into two grous:
  10 => int num_segments; // # of segs in a given waveform, I
  Math.random2f(0.0, 1.0) => float Y;
  float x_vals[num_segments];
  float y_vals[num_segments];
  wave_length(10);

  // stochastic distribution of duration
  -100 => float xadd_min; // limit the values added to the xs of a waveform
  100  => float xadd_max;
  Math.random2f(1.0, 100.0) => float mir_xmin; // limit the number of samples per waveform segment
  Math.random2f(1.0, 100.0)  => float mir_xmax; 

  // stochastic distribution of our amplitude
  -0.1 => float yadd_min;
  0.1 => float yadd_max; // limit the values added to the ys of a waveform
  -0.9  => float mir_ymin; // limit the possible values of the ys of a waveform 
  0.9   => float mir_ymax;

  int t;
  float seg_end, xadd, yadd;

  "cauchy" => string dist_type;


  // x array stores the duration values of each waveform segment
  // y array stores the amplitude values of each segment endpoint
  // at each sample, you update the values in those tables by 
  // running them through the stochastic functions
  // over the course of the durations stored in the x val array,
  // you linearly interpolate between the y values
  fun float tick(float in)
  {
    1 +=> t;
    if(t >= seg_end) {
      (x_idx + 1) % num_segments => x_idx;
      mirror(xadd_min, xadd_max, distribution(x_vals[x_idx], Y)) => xadd;

      if(y_idx + 1 % num_segments == 0) {
        y_vals[y_idx] => y_vals[y_idx + 1];    
      } else {
        mirror(yadd_min, yadd_max, distribution(y_vals[y_idx], Y)) => yadd;
        mirror(mir_xmin, mir_xmax, x_vals[x_idx] + xadd) => x_vals[x_idx];
        mirror(mir_ymin, mir_ymax, y_vals[y_idx] + yadd) => y_vals[y_idx];
      }
      (y_idx + 1) % num_segments => y_idx;
    } else {
      (y_vals[(y_idx + 1) % num_segments] - y_vals[y_idx]) / x_vals[x_idx] +=> y_vals [y_idx];
    }

    //<<< y_vals[y_idx], x_vals[x_idx], "" >>>;
    return y_vals[y_idx];
  }

  fun float mirror(float lower, float upper, float val)
  {
    if(val > upper || val < lower)
    {
      upper - lower => float range;
      if(val < lower) 2 * range - val => val; // get val in the range if needed
      fmod(val - upper, 2 * range) => val;
      if(val < range) upper - val => val;
      else val - range => val;
    }

    return val;
  }

  fun void wave_length(int length)
  {
    if(length > num_segments)
    {
      y_vals.size(length);
      x_vals.size(length);
      for(num_segments - 1 => int i; i < length; i++)
      {
        1.0 => y_vals[i];
        mir_xmin => x_vals[i];
      }
      length => num_segments;
    }
    else if(length < num_segments)
    {
      length => num_segments;
      y_vals.size(num_segments);
      x_vals.size(num_segments);
    }
  }

  // probability distributions - actually inverses of the realy distributions
  // NB: really wish we had switch/case here...
  fun float distribution(float a, float y)
  {
    if(a > 1.0) 1.0 => a;       // must be in 0..1
    if(a < 0.0001) 0.0001 => a;
    if(dist_type == "exponential")
    {
      Math.log10(1.0 - (0.999 * a)) => float c;
      Math.log(1.0 - (y * 0.999 * a)) / c => float temp;

      return 2 * temp - 1.0;
    } 
    else if(dist_type == "cauchy")
    {
      Math.atan(10 * a) => float c;
      (1 / a) * Math.tan(c * (2 * y - 1)) => float temp;

      return temp * 0.1;
    } 
    else 
    {
      return 2 * y - 1.0;
    }
  }

  fun float fmod(float numer, float denom)
  {
    (numer / denom) $ int => float tquot;
    return numer - tquot * denom;
  }
}

Gendy g => Gain gain => dac;
Gendy g2 => blackhole;
g2.wave_length(10000);
["cauchy", "exponential"] @=> string types[];
gain.gain(0.1);
1::second => now;
0 => int i;
while(true)
{
  g2.last() / g.last() * Math.random2f(-10, 100)=> g.yadd_min;
  g2.last() / g.last()* Math.random2f(-10, 100)=> g.yadd_max;
  g2.last() / g.last() * Math.random2f(-10, 100)=> g.xadd_min;
  g2.last() / g.last() * Math.random2f(-10, 100)=> g.xadd_max;

  if(i % 2 == 0)
  {
    types[Math.random2(0, types.size() - 1)] @=> g.dist_type;
  }

  100::ms => now;
  i ++;
}
