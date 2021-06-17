#include <stdio.h>
#include <stdlib.h>

#include "/usr/include/cuda_runtime.h"
#include "/usr/include/device_launch_parameters.h"

__global__ void CCKernel(float* d_vecA_re, float* d_vecA_im, float* d_vecB_re, float* d_vecB_im, unsigned int len, float* d_multvalues_re, float* d_multvalues_im, int startShift, unsigned int N)
{
	int i = blockDim.x * blockIdx.x + threadIdx.x; //this i value is the position in the A vector
	int j = blockDim.y * blockIdx.y + threadIdx.y; //the j value is the shift
	
	if ((i < len) && (j < N)) //making sure this thread is in the matrix
	{
		unsigned int pos = j * len + i; //going left to right then top to bottom

		int B_Index = i + startShift + j; //the B coordinate we're taking for this particular thread
		
		if ((B_Index >= 0) && (B_Index < len)) //this if checks whether the shifted position is still inside the B vector
		{
			if (threadIdx.z == 0) //this splits up whether we're calculating the real or complex part. 0 is for real, 1 is for complex.
			{
				d_multvalues_re[pos] = d_vecA_re[i] * d_vecB_re[B_Index] + d_vecA_im[i] * d_vecB_im[B_Index]; //performing the complex conjugate multiplication for the real part
			}
			else
			{
				d_multvalues_im[pos] = - d_vecA_re[i] * d_vecB_im[B_Index] + d_vecA_im[i] * d_vecB_re[B_Index]; //performing the complex conjugate multiplication for the complex part
			}
		}
		else
		{
			if (threadIdx.z == 0)
			{
				d_multvalues_re[pos] = 0; //in this version of cross correlation, if they're shifted too far, the value is set to 0 instead of wrapping around
			}
			else
			{
				d_multvalues_im[pos] = 0;
			}
		}
	}
}

__global__ void sumRows(float* d_multValues_re, float* d_multValues_im, float* d_outputVec, unsigned int len, unsigned int N)
{
	unsigned int i = blockDim.x * blockIdx.x + threadIdx.x; //i is the row, where even corresponds to a real row and odd corresponds to an imaginary row.

	if (i < 2 * N)
	{
		float sum = 0;
		if (i % 2 == 0) //splitting between the even real case and the odd imaginary case
		{
			for (unsigned int j = 0; j < len; j++) //the actual summing loop
			{
				sum = sum + d_multValues_re[i/2 * len + j];
			}
		}
		else
		{
			for (unsigned int j = 0; j < len; j++)
			{
				sum = sum + d_multValues_im[(i-1) / 2 * len + j];
			}
		}
		sum = sum/len; //normalization
		d_outputVec[i] = sum;
	}
}

extern "C" {
	void cross_correlations(const float* vecA_re, const float* vecA_im, const float* vecB_re, const float* vecB_im, const unsigned int len, const int startShift, const int stopShift, float* outputVec) //len is the length of the input vectors
	{
		if (stopShift >= startShift)
		{
			unsigned int N = stopShift - startShift + 1; //N is how many shifting values you're checking. The output vector will contain 2N floats since it's complex.

			//allocating memory on the decide for both input vectors and copying them over
			size_t inputSize = len * sizeof(float);
			float* d_vecA_re = NULL;
			cudaMalloc((void**)&d_vecA_re, inputSize);
			cudaMemcpy(d_vecA_re, vecA_re, inputSize, cudaMemcpyHostToDevice);

			float* d_vecA_im = NULL;
			cudaMalloc((void**)&d_vecA_im, inputSize);
			cudaMemcpy(d_vecA_im, vecA_im, inputSize, cudaMemcpyHostToDevice);

			float* d_vecB_re = NULL;
			cudaMalloc((void**)&d_vecB_re, inputSize);
			cudaMemcpy(d_vecB_re, vecB_re, inputSize, cudaMemcpyHostToDevice);

			float* d_vecB_im = NULL;
			cudaMalloc((void**)&d_vecB_im, inputSize);
			cudaMemcpy(d_vecB_im, vecB_im, inputSize, cudaMemcpyHostToDevice);

			float* d_multValues_re = NULL;
			cudaMalloc((void**)&d_multValues_re, len * N * sizeof(float));

			float* d_multValues_im = NULL;
			cudaMalloc((void**)&d_multValues_im, len * N * sizeof(float));

			/*finding the kernel dimensions
			*
			* The multiplication values matrix is going to look like this
			* [[,,, ... ,,,] <- each row contains all the multiplications for each shift, so this would be shit by startShift
			* [,,, ... ,,,] <- shift by startShift + 1
			* ...
			* [,,, ... ,,,] <- shift by endShift - 1
			* [,,, ... ,,,]] <- shift by endShift
			*
			* so there are N rows and len colums. z = 0 is the real value, and z = 1 is the imaginary value.
			*
			*/

			dim3 dimBlock(16, 16, 2);
			dim3 dimGrid((len + 15) / 16, (N + 15) / 16, 1);

			cudaError_t err = cudaSuccess;
			CCKernel <<<dimGrid, dimBlock>>> (d_vecA_re, d_vecA_im, d_vecB_re, d_vecB_im, len, d_multValues_re, d_multValues_im, startShift, N);
			err = cudaGetLastError();

			if (err != cudaSuccess)
			{
				fprintf(stderr, "Failed to launch kernel (error code %s)!\n", cudaGetErrorString(err));
				exit(EXIT_FAILURE);
			}

			
			/*float* h_mvaluestodisplay = (float*) malloc(len * N * sizeof(float));
			cudaMemcpy(h_mvaluestodisplay, d_multValues_re, len * N * sizeof(float), cudaMemcpyDeviceToHost);
			for (int i = 0; i < len * N; i++)
			{
				printf("%f ", h_mvaluestodisplay[i]);
				if ((i+1)%len == 0)
				{
					printf("\n");
				}
			}
			printf("\n");*/

			//we don't need the input vectors on the device anymore
			cudaFree(d_vecA_re);
			cudaFree(d_vecA_im);
			cudaFree(d_vecB_re);
			cudaFree(d_vecB_im);

			//creating the output vector. It contains 2N floats since each value is complex.
			size_t outputSize = 2 * N * sizeof(float);
			float* d_outputVec = NULL;
			cudaMalloc((void**)&d_outputVec, outputSize);

			//finally summing all the values into the output vec. I'm going to sort this like [0_real, 0_imaginary, 1_real, 1_imaginary, ... (N-1)_real, (N-1)_imaginary]
			unsigned int threadsPerBlock = 256;
			unsigned int blocksPerGrid = (2 * N + threadsPerBlock - 1) / threadsPerBlock;
			sumRows <<<threadsPerBlock, blocksPerGrid>>> (d_multValues_re, d_multValues_im, d_outputVec, len, N);

			//freeing up these
			cudaFree(d_multValues_re);
			cudaFree(d_multValues_im);

			//copying the output vector back to the host
			cudaMemcpy(outputVec, d_outputVec, outputSize, cudaMemcpyDeviceToHost);
			cudaFree(d_outputVec);
		}
		else
		{
			printf("Error: Starting shift is higher than the stopping shift.");
		}
	}
}
