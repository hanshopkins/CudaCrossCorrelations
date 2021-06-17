import ctypes
import pathlib
import matplotlib.pyplot as plt
import numpy as np
import sys

if __name__ == "__main__":
    libname = pathlib.Path().absolute() / "libccc.so"
    clib = ctypes.CDLL(libname)
    clib.cross_correlations.restype = None
    clib.cross_correlations.argtypes = ctypes.POINTER(ctypes.c_float), ctypes.POINTER(ctypes.c_float), ctypes.POINTER(ctypes.c_float), ctypes.POINTER(ctypes.c_float), ctypes.c_uint, ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_float)
    
    #creating all the pointers
    length = 200 #this is the length of your input vectors
    
    A_real_pointer = (ctypes.c_float * length)()
    A_imaginary_pointer = (ctypes.c_float * length)()
    B_real_pointer = (ctypes.c_float * length)()
    B_imaginary_pointer = (ctypes.c_float * length)()
    
    #setting the value for each array
    for i in range(length):
        A_real_pointer[i] = np.sin((10*np.pi*i)/length)
        
    for i in range(length):
        A_imaginary_pointer[i] = 0
        
    for i in range(length):
        B_real_pointer[i] = np.cos((10*np.pi*i)/length)
        
    for i in range(length):
        B_imaginary_pointer[i] = 0
    
    #parameters determining how far we're shifting to each side. This is INCLUDING the startShift and stopShift. To only test one shift number, set these to both be the same.
    startShift = -200
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
        
    plt.plot(outputX,np.real(outputArray))
    plt.xlabel('Shift time')
    plt.ylabel('Cross correlation value')
    plt.savefig('ccoutput')
