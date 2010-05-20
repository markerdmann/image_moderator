// Copyright 2008 Evan Klinger. All rights reserved.
#include "pHash.h"
#include <bitset>
using namespace std;
using namespace cimg_library;

/*
* The following code is public domain.
* Algorithm by Torben Mogensen, implementation by N. Devillard.
* This code in public domain.
*/

double pHash::torben_median(double m[], int n)
{
    int         i, less, greater, equal;
    double  min, max, guess, maxltguess, mingtguess;

    min = max = m[0] ;
    for (i=1 ; i<n ; i++) {
        if (m[i]<min) min=m[i];
        if (m[i]>max) max=m[i];
    }

    while (1) {
        guess = (min+max)/2;
        less = 0; greater = 0; equal = 0;
        maxltguess = min ;
        mingtguess = max ;
        for (i=0; i<n; i++) {
            if (m[i]<guess) {
                less++;
                if (m[i]>maxltguess) maxltguess = m[i] ;
            } else if (m[i]>guess) {
                greater++;
                if (m[i]<mingtguess) mingtguess = m[i] ;
            } else equal++;
        }
        if (less <= (n+1)/2 && greater <= (n+1)/2) break ; 
        else if (less>greater) max = maxltguess ;
        else min = mingtguess;
    }
    if (less >= (n+1)/2) return maxltguess;
    else if (less+equal >= (n+1)/2) return guess;
    else return mingtguess;
}


bitset<64> pHash::computeHash()
{
    return computeHash(src);

}
bitset<64> pHash::computeHash(CImg<double> *img)
{
    if(img == NULL)
        throw new pHashFileNotSetException();

    if(img->dimv() == 3)
        img->RGBtoYCbCr();

    img->channel(0).blur(0.5f);

    bitset<64> hash;

    fftw_r2r_kind kind[] = {FFTW_REDFT10,FFTW_REDFT10,FFTW_REDFT10};

    if(img->dimz() > 1)
    {
        img->resize(32, 32, 64);
    } 
    else if(img->dimz() == 1)
    {
        img->resize(32, 32);
    }

    const int n[] = {img->width, img->height, img->depth};
    plan = fftw_plan_r2r(n[2]>1?3:2, n, img->ptr(), img->ptr(), kind, FFTW_ESTIMATE);
    fftw_execute(plan);

    if(img->depth > 1)
    {
        img->crop(1, 1, 1, 4, 4, 4);

    }
    else if(img->depth == 1)
    {
        img->crop(1, 1, 8, 8);
    }	

    int dimens = img->dimx()*img->dimy()*img->dimz();
    double median = torben_median(img->ptr(), dimens);
    for(int i = 0; i < dimens; i++)
        if(img->ptr()[i] >= median)
            hash[i] = true;

    return hash;

}		
void pHash::reset() {
    fftw_cleanup();
}			
void pHash::setFile(const char* file)
{
    struct stat finfo;
    if(file == NULL)
        throw pHashFileNotSetException();
    if(stat(file, &finfo) == 0 && S_ISREG(finfo.st_mode))
    {	
        src = new CImg<double>(file);
    }
}
pHash::~pHash()
{
    if(plan != NULL)
    {
        fftw_destroy_plan(plan);
        fftw_cleanup();
        plan = NULL;
    }

}	


