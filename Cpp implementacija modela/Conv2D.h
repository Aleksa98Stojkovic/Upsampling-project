#ifndef CONV2D_H_INCLUDED
#define CONV2D_H_INCLUDED

#include <vector>
#include <iostream>

using namespace std;

void Conv2D(const vector<vector<vector<vector<float>>>> &W, const vector<vector<vector<float>>> &IFM, vector<vector<vector<float>>> &OFM);

#endif // CONV2D_H_INCLUDED
