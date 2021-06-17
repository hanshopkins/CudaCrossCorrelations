import os
import sys

#builds into the same directory as the setup file
path = os.path.realpath(__file__+r"/..")

def build():
    if os.path.exists(path+"/albatrostools.c"):
        os.system("gcc-9 -O3 -o \""+ path + "/libalbatrostools.so\" -fPIC --shared \"" + path + "/albatrostools.c\" -fopenmp")
    else:
        print("Cannot find the file albatrostools.c in the directory "+path)
    
    if os.path.exists(path+"/ccc.cu"):
        os.system("nvcc -Xcompiler -fPIC -shared -o \""+ path + "/libccc.so\" \"" + path + "/ccc.cu\"")
    else:
        print("Cannot find the file ccc.cu in the directory "+path)