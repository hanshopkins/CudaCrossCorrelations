import ctypes
import pathlib
from albatrostools import get_data
import matplotlib.pyplot as plt
import numpy as np
import sys

if __name__ == "__main__":
    libname = pathlib.Path().absolute() / "libccc.so"
    clib = ctypes.CDLL(libname)
    clib.cross_correlations.restype = None
    clib.cross_correlations.argtypes = ctypes.POINTER(ctypes.c_float), ctypes.POINTER(ctypes.c_float), ctypes.POINTER(ctypes.c_float), ctypes.POINTER(ctypes.c_float), ctypes.c_uint, ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_float)
    
    header,data = get_data(sys.argv[1],unpack_fast=True,float=True,byte_delta=-8)
    
    #creating all the pointers
    length = 500 #this is the length of your input vectors
    
    A_real_pointer = (ctypes.c_float * length)()
    A_imaginary_pointer = (ctypes.c_float * length)()
    B_real_pointer = (ctypes.c_float * length)()
    B_imaginary_pointer = (ctypes.c_float * length)()
    
    #setting the value for each array
    for i in range(length):
        A_real_pointer[i] = np.real(data['pol0'][i][4])
        
    for i in range(length):
        A_imaginary_pointer[i] = np.imag(data['pol0'][i][4])
        
    for i in range(length):
        B_real_pointer[i] = np.real(data['pol1'][i][4])
        
    for i in range(length):
        B_imaginary_pointer[i] = np.imag(data['pol1'][i][4])
    
    #parameters determining how far we're shifting to each side. This is INCLUDING the startShift and stopShift. To only test one shift number, set these to both be the same.
    startShift = 0
    stopShift = 200
    
    N = stopShift - startShift + 1 #this is the number of shifts that it finds the cross correlations for

    #createing the ouput pointer. It is structured like [0_real, 0_imaginary, 1_real, 1_imaginary, ... (N-1)_real, (N-1)_imaginary]
    outputPointer = (ctypes.c_float * (2 * N))()
    
    clib.cross_correlations(A_real_pointer, A_imaginary_pointer, B_real_pointer, B_imaginary_pointer, length, startShift, stopShift, outputPointer)
    
    outputArray = np.zeros(dtype = np.cfloat, shape = N) #this part is pretty slow and not necessary if you can work with the values from outputPointer, but this looks nicer
    for i in range(N):
        outputArray[i] = outputPointer[2 * i] + outputPointer[2*i+1] * 1j

    #print(outputArray)
    
    outputX = np.zeros(shape = N)
    for i in range(N):
        outputX[i] = (startShift + i) * (1.0/length)
    
    realfig, realax = plt.subplots()
    realax.plot(outputX,np.real(outputArray))
    realax.set_xlabel('Shift time')
    realax.set_ylabel('Real Cross correlation value')
    realfig.savefig('ccoutputReal')
    
    imagfig, imagax = plt.subplots()
    imagax.plot(outputX,np.imag(outputArray))
    imagax.set_xlabel('Shift time')
    imagax.set_ylabel('Imaginary Cross correlation value')
    imagfig.savefig('ccoutputImaginary')
