// Copyright 2008 Evan Klinger. All rights reserved.
#define cimg_use_jpeg 1
#define cimg_display 0

#include "CImg.h"

#include "fftw3.h"

#include <iostream>
#include <bitset>
#include <exception>
#include <sys/types.h>
#include <sys/stat.h>

#ifndef S_ISREG
#define S_ISREG(x) (((x) & S_IFMT) == S_IFREG)
#endif


using namespace std;
using namespace cimg_library;

class pHash {
private:
    fftw_plan plan;
    CImg<double> *src;
    /*
    * The following code is public domain.
    * Algorithm by Torben Mogensen, implementation by N. Devillard.
    * This code in public domain.
    */

    double torben_median(double m[], int n);
    class pHashFileNotSetException : public exception
    {
    public:
        virtual const char* what() const throw()
        {
            return "Audio, video, or image file not set for hash computation.";
        }
    };
public:
    template <size_t N>
    size_t hamming_distance(bitset<N>& h1, bitset<N>& h2)
    {
        if(h1.size() != h2.size())
            return -1;
        return (h1 ^ h2).count();
    }
    bitset<64> computeHash();
    bitset<64> computeHash(CImg<double> *img);		
    void reset();			
    void setFile(const char* file);
    ~pHash();

};
