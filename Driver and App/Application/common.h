#ifndef COMMON_H_INCLUDED
#define COMMON_H_INCLUDED

#include <vector>
#include <iostream>
#include <string>
#include <cstdlib>
#include <cmath>
#include <stack>
#include <fstream>
#include <string>
#include <sstream>

#define DP 11
#define MAC_WIDTH 32
#define MASK 0x80000000

typedef double t;
typedef dram_word unsigned long long int;
typedef sint64 long long int;
typedef std :: vector < std :: vector < std :: vector <t>>> float3D;
typedef std :: vector < std :: vector < std :: vector < std :: vector <t>>>> float4D;
const std :: vector <t> mean = {114.44399999999999, 111.4605, 103.02000000000001};

// Dodatne funkcije
// kakav pointer vraca drajver? Verovatno unsigned char
void Write_DRAM_content(vector <dram_word> &data, vector <dram_word> &weights, dram_word* dram);
t Fxp2Float(dram_word *data);
dram_word Float2Fxp(t &data, int n, int f); // proveriti ovu funkciju!

#endif // COMMON_H_INCLUDED
