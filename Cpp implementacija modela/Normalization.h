#ifndef NORMALIZATION_H_INCLUDED
#define NORMALIZATION_H_INCLUDED

#include <iostream>
#include <vector>

using namespace std;

const vector <float> mean = {114.44399999999999, 111.4605, 103.02000000000001};

void Normalize(vector<vector<vector<float>>> &IFM);
void Denormalize(vector<vector<vector<float>>> &IFM);

#endif // NORMALIZATION_H_INCLUDED
