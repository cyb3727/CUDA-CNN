#ifndef __SOFT_MAX_H__
#define __SOFT_MAX_H__

#include "LayerBase.h"
#include "../common/cuMatrix.h"
#include <vector>
#include "../common/util.h"
#include "../common/cuMatrixVector.h"

class SoftMax: public LayerBase
{
public:
	void feedforward();
	void backpropagation();
	void getGrad();
	void updateWeight() ;
	void clearMomentum();
	void getCost(cuMatrix<double>*cost, int* y);

	cuMatrix<double>* getOutputs();
	cuMatrix<double>* getPreDelta();
	cuMatrix<double>* getCurDelta() ;

	void setPreDelta(cuMatrix<double>* _preDelta);

	void initRandom();
	void initFromCheckpoint(FILE* file);
	void save(FILE* file);


	virtual void printParameter(){
		printf("%s:\n",m_name.c_str());
		w->toCpu();
		printf("weight:%lf, %lf;\n", w->get(0,0,0), w->get(0,1,0));
		b->toCpu();
		printf("bias  :%lf\n", b->get(0,0,0));
	}

	SoftMax(std::string name);

private:
	cuMatrix<double>* inputs;
	cuMatrix<double>* outputs;
	cuMatrix<double>* inputs_format;//convert inputs(batch, size, channel) to (batch, size * channel)
	cuMatrix<double>* curDelta;
	cuMatrix<double>* preDelta;
	cuMatrix<double>* preDelta_format;


	cuMatrix<double>* w;
	cuMatrix<double>* wgrad;
	cuMatrix<double>* b;
	cuMatrix<double>* bgrad;
	cuMatrix<double>* groudTruth;

	cuMatrix<double>* momentum_w;
	cuMatrix<double>* momentum_b;

	int inputsize;
	int outputsize; 
	double lambda;
	int batch;
	int NON_LINEARITY;
};
#endif
