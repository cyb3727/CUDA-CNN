#include "cuBase.h"

__device__ double d_nonLinearity(double val, int NONLIN){
	if(NONLIN == NL_RELU)
	{
		if(val < 0.0) return 0.0;
		else return val;
	}
	else if(NONLIN == NL_TANH)
	{
		return tanh(val * 2.0 / 3.0) * 1.7159;
	}
	return 0.0;
}

__device__ double d_dnonLinearity(double val,int NONLIN){
	if(NONLIN == NL_RELU)
	{
		if(val > 0.0) return 1.0;
		else return 0.0;
	}
	else if(NONLIN == NL_TANH)
	{
		double res = 1.7159;
		double temp = val * val / 1.7159;
		res = (res - temp) * 2.0 / 3.0;
		return res;
	}
}

__global__ void g_dnonLinearity(double* delta, double*acti, int len, int NONLIN)
{
	for(int i = 0; i < len; i += gridDim.x * blockDim.x)
	{
		int id = blockDim.x * blockIdx.x + threadIdx.x + i;
		if(id < len)
		{	
			delta[id] *= d_dnonLinearity(acti[id], NONLIN);
		}
	}
}

__global__ void g_nonLinearity(double* inputs, int len, int NONLIN)
{
	for(int i = 0; i < len; i += gridDim.x * blockDim.x)
	{
		int id = blockDim.x * blockIdx.x + threadIdx.x + i;
		if(id < len)
		{	
			inputs[id] *= d_nonLinearity(inputs[id], NONLIN);
		}
	}
}

__device__ double atomicAdd(double* address, double val)
{ 	
	unsigned long long int* address_as_ull =
		(unsigned long long int*)address;
	unsigned long long int old = *address_as_ull, assumed;
	do {
		assumed = old;
		old = atomicCAS(address_as_ull, assumed,
			__double_as_longlong(val +
			__longlong_as_double(assumed)));
	} while (assumed != old);
	return __longlong_as_double(old);
}

__device__ void swap(double& val1, double& val2){
	double tmp = val1;
	val1 = val2;
	val2 = tmp;
}


__global__ void g_vecAdd(double**_v_w, double** _wgrad,double** _w,
	double** _v_b, double** _bgrad, double** _b, 
	int lenw, int lenb,
	double momentum, double lrate)
{
	double* v_w   = _v_w[blockIdx.x];
	double* wgrad = _wgrad[blockIdx.x];
	double* w     = _w[blockIdx.x];
	double* v_b   = _v_b[blockIdx.x];
	double* bgrad = _bgrad[blockIdx.x];
	double* b     = _b[blockIdx.x];

	int idx = threadIdx.x;
	for(int i = 0; i < lenw; i += blockDim.x)
	{
		int id = i + idx;
		if(id < lenw)
		{
			v_w[id] = v_w[id] * momentum + wgrad[id] * lrate;
			w[id] -= v_w[id];
		}
	}
	for(int i = 0; i < lenb; i += blockDim.x)
	{
		int id = i + idx;
		if(id < lenb)
		{
			v_b[id] = v_b[id] * momentum + bgrad[id] * lrate;
			b[id] -= v_b[id];
		}
	}
}

__global__ void g_vecAdd(double*v_w, double*wgrad,double* w,
	double* v_b, double* bgrad, double* b, 
	int lenw, int lenb,
	double momentum, double lrate)
{
	int idx = blockDim.x * blockIdx.x + threadIdx.x;
	for(int i = 0; i < lenw; i += blockDim.x * gridDim.x)
	{
		int id = i + idx;
		if(id < lenw)
		{
			v_w[id] = v_w[id] * momentum + wgrad[id] * lrate;
			w[id] -= v_w[id];
		}
	}
	for(int i = 0; i < lenb; i += blockDim.x * gridDim.x)
	{
		int id = i + idx;
		if(id < lenb)
		{
			v_b[id] = v_b[id] * momentum + bgrad[id] * lrate;
			b[id] -= v_b[id];
		}
	}
}