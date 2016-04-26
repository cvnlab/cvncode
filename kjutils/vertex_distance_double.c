#include "mex.h"
#include "math.h"

/*
 * Fidx=vertex_faces(Fa,Fb,Fc,Vx,Vy,Vz)
 *
 */

/* Coordinates to index */
int mindex3(int x, int y, int z, int sizx, int sizy) { return z*sizx*sizy+y*sizx+x;}
int mindex2(int x, int y, int sizx) { return y*sizx+x;}
double edgelen(double *x, double *y, double *z, int a, int b) {
    return sqrt((x[a]-x[b])*(x[a]-x[b]) + (y[a]-y[b])*(y[a]-y[b]) + (z[a]-z[b])*(z[a]-z[b]));
}
double max(double a, double b) { return a>b ? a : b; }
double min(double a, double b) { return a<b ? a : b; }

/* The matlab mex function */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
    /* All inputs */
    double *FacesA, *FacesB, *FacesC, *VerticesX, *VerticesY, *VerticesZ;

    const double *metrictmp=NULL;
    int whichmetric=0;
    
    /* Unsorted Neighborh list */
    double *VertexDist;
    int *NeiCount;

    /* Number of faces */
    const mwSize *FacesDims;
    int FacesN=0;
    
    /* Number of vertices */
    const mwSize *VertexDims;
    int VertexN=0;
    
    
    /* Loop variable */
    int i, j, index1, index2;
    
    /* Found */
    double sidelen1, sidelen2, sidelen3;
    
    /* face vertices int */
    int vertexa, vertexb, vertexc;
    
    /* neighbour cell array length (same as vertices) */
    mwSize outputdims[2]={0,1};
    
    /* Check for proper number of arguments. */
    if(!(nrhs==6 || nrhs==7)) {
        mexErrMsgTxt("6 or 7 inputs are required.");
    } else if(nlhs!=1) {
        mexErrMsgTxt("1 output is required");
    }

    
    /* Read all inputs (faces and vertices) */
    FacesA=mxGetPr(prhs[0]);
    FacesB=mxGetPr(prhs[1]);
    FacesC=mxGetPr(prhs[2]);
    VerticesX=mxGetPr(prhs[3]);
    VerticesY=mxGetPr(prhs[4]);
    VerticesZ=mxGetPr(prhs[5]);
    
    metrictmp = (const double*) mxGetData(prhs[6]);
    whichmetric = *metrictmp;
    if (!mxIsInf(*metrictmp) &&
        !mxIsNaN(*metrictmp))
        whichmetric = (int)*metrictmp;
    
    /* Get number of FacesN */
    FacesDims = mxGetDimensions(prhs[0]);
    FacesN=FacesDims[0]*FacesDims[1];
    
    /* Get number of VertexN */
    VertexDims = mxGetDimensions(prhs[3]);
    VertexN=VertexDims[0]*VertexDims[1];
    
    outputdims[0]=VertexN;

    plhs[0]= mxCreateNumericArray(2, outputdims, mxDOUBLE_CLASS, mxREAL);
    /* Connect Outputs */
    
    VertexDist = (double *)mxGetPr(plhs[0]);
    
    /* Neighborhs Unsorted */
    /*VertexDist = (double *)malloc( VertexN* sizeof(double) );*/
    NeiCount = (int *)malloc( VertexN* sizeof(int) );
    for (i=0; i<VertexN; i++) {
        /* Set number of vertex neighbors to zero */
        if(whichmetric==1)
            VertexDist[i]=-1;
        else if(whichmetric==2)
            VertexDist[i]=mxGetInf();
        else
            VertexDist[i]=0;
        NeiCount[i]=0;
    }

    
    /* Loop throuh all faces */
    for (i=0; i<FacesN; i++) {
        /* Add the neighbors of each vertice of a face
         * to his neighbors list. */
        
        vertexa=(int)FacesA[i]-1; vertexb=(int)FacesB[i]-1; vertexc=(int)FacesC[i]-1;
        sidelen1=edgelen(VerticesX,VerticesY,VerticesZ,vertexa,vertexb);
        sidelen2=edgelen(VerticesX,VerticesY,VerticesZ,vertexa,vertexc);
        sidelen3=edgelen(VerticesX,VerticesY,VerticesZ,vertexb,vertexc);
      

        if(whichmetric==1){
            VertexDist[vertexa]=max(max(VertexDist[vertexa],sidelen1),sidelen2);
            VertexDist[vertexb]=max(max(VertexDist[vertexb],sidelen1),sidelen3);
            VertexDist[vertexc]=max(max(VertexDist[vertexc],sidelen2),sidelen3);
        }else if(whichmetric==2){
            VertexDist[vertexa]=min(min(VertexDist[vertexa],sidelen1),sidelen2);
            VertexDist[vertexb]=min(min(VertexDist[vertexb],sidelen1),sidelen3);
            VertexDist[vertexc]=min(min(VertexDist[vertexc],sidelen2),sidelen3);
        }else {
            VertexDist[vertexa]+=sidelen1+sidelen2;
            VertexDist[vertexb]+=sidelen1+sidelen3;
            VertexDist[vertexc]+=sidelen2+sidelen3;
            NeiCount[vertexa]+=2;
            NeiCount[vertexb]+=2;
            NeiCount[vertexc]+=2;
        }
    }
    
    /*  Loop through all neighbor arrays and sort them (Rotation same as faces) */
    
    
    for (i=0; i<VertexN; i++) {
        if(NeiCount[i]>0) {
            VertexDist[i]/=NeiCount[i];
        }
    }
    /* Free memory */
    free(NeiCount);
    
}
