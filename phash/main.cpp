// Copyright 2008 Evan Klinger. All rights reserved.
#include "pHash.h"

using namespace std;

int main(int argc, char *argv[])
{
    pHash p1, p2;
    p1.setFile(argv[1]);
    bitset<64> h1 = p1.computeHash();
    cout <<  h1 << endl;
    if(argv[2]) {
      p2.setFile(argv[2]);
      bitset<64> h2 = p2.computeHash();
      unsigned int n = p1.hamming_distance(h1,h2);
      cout <<  h2 << endl;
      printf("The hamming distance was %d\n", n);
    }
    return 0;
}
