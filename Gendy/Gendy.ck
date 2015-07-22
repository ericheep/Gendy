public class Gendy extends Chugen
{
  1 / pi => float inverse_pi;
  int x_idx, y_idx;

  // input parameters into two grous:
  100 => int num_segments; // # of segs in a given waveform, I
  Math.random2f(0.0, 1.0) => float Y;
  float x_vals[num_segments];
  float y_vals[num_segments];

  // stochastic distribution of duration
  -1 => int xadd_min; // limit the values added to the xs of a waveform
  1  => int xadd_max;
  100 => int mir_smin; // limit the number of samples per waveform segment
  1000  => int mir_smax; 

  // stochastic distribution of our amplitude
  float yadd_min, yadd_max; // limit the values added to the ys of a waveform
  -1.0  => float mir_ymin; // limit the possible values of the ys of a waveform 
  1.0   => float mir_ymax;

  for(int i; i < num_segments; i++)
  {
    1.0 => y_vals[i];
    mir_smin => x_vals[i];
  }
  int t;
  float seg_end;


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
      mirror_x(exponential(x_vals[x_idx], Y) + x_vals[x_idx]) => seg_end;

      if(y_idx + 1 % num_segments == 0) {
        y_vals[y_idx] => y_vals[y_idx + 1];    
      } else {
        mirror_y(exponential(y_vals[y_idx] , Y) + y_vals[y_idx]) => y_vals[(y_idx + 1) % num_segments];
      }
      (y_idx + 1) % num_segments => y_idx;
    } else {
      (y_vals[(y_idx + 1) % num_segments] - y_vals[y_idx]) / x_vals[x_idx] +=> y_vals [y_idx];
    }

    return y_vals[y_idx];
  }

  fun float mirror_x(float old_x)
  {
    while(old_x >= mir_smax || old_x <= mir_smin)
    {
      0.5 *=> old_x;
    }
    return old_x;
  }

  fun float mirror_y(float old_y)
  {
    while(old_y >= mir_ymax || old_y <= mir_ymin)
    {
      -0.9 *=> old_y;
    }
    return old_y;
  }

  // probability distributions - actually inverses of the realy distributions
  fun float exponential(float a, float y)
  {
    if(a == 0) 1 +=> a;
    return (-1 / (a * a)) * Math.log10(1 - y);
  }
}

Gendy g => Gain gain => dac;
gain.gain(0.1);
second => now;
for(int i; i < 10; i++)
{
  Math.random2(100, 1000) => g.mir_smin;
  Math.random2(g.mir_smin, 1000) => g.mir_smax;
  500::ms => now;
}
