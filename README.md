# CudaCrossCorrelations

* Put all files in the same directory.

* Run build in setup.py to compile all the shared object files with the command: python3 -c 'from setup import build; build()'

* Install NVCC

* Run cross_correlations.py with `python3 cross_correlations <.raw file>`

&nbsp;

* The parameters to set in cross_correlations.py are StartShift and StopShift which determine which time values of the cross correlation function you're calculating. I'll make these command line arguments later.

* You can also choose the input data in the "#setting the value for each array" section. For the current implementation, each input array needs to be the same length.

* Right now, the input data is set to compare the first 500 values of the two polarizations. I just chose this arbitrarily to test out whether get_data was working properly.

* It will output two graphs called ccoutputReal and ccoutputImaginary for the real part of the cross correlation and the imaginary part respectively. It would be more helpful to output a file containing the numbers instead of those graphs, but this is just for testing visualization.

&nbsp;

* I'm also going to include the trig_example version, which doesn't use any imported data from albatrostools.

&nbsp;

The way the cross correlations are implemented currently, for the regions where the signals don't overlap after being shifted, all of the multiplications are just sent to 0. This causes the magnitude of the result to decrease linearlyish away from time = 0. This can be easily seen in the trig example. An alternative for this definition of cross correlation is to multiply circularly, so that it wraps around.

It would be nice to be able to set the second input to be larger than the first, so that you could compare a small part of one signal to a larger part of another signal, and then you wouldn't have to deal with the amplitude falloff. If that's helpful I could add that.
