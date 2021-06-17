# CudaCrossCorrelations

* Put all files in the same directory.

* Run setup.py to compile all the shared object files

* Run cross_correlations.py with `python3 cross_correlations <.raw file>`

&nbsp;

* The parameters to set in cross_correlations.py are StartShift and StopShift which determine which time values of the cross correlation function you're calculating. I'll make these command line arguments later.

* You can also choose the input data in the "#setting the value for each array" section. For the current implementation, each input array needs to be the same length.

* Right now, the input data is set to compare the first 500 values of the two polarizations. I just chose this arbitrarily to test out whether get_data was working properly.

* It will output two graphs called ccoutputReal and ccoutputImaginary for the real part of the cross correlation and the imaginary part respectively. It would be more helpful to output a file containing the numbers instead of those graphs, but this is just for testing visualization.

&nbsp;

* I'm also going to include the trig_example version, which doesn't use any imported date from albatrostools.
