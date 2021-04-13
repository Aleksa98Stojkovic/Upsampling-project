#include "Add.h"

void Add(const vector<vector<vector<float>>> &IFM1, const vector<vector<vector<float>>> &IFM2)
{
    for(int wi = 0; wi < (int)IFM1.size(); wi++)
    {
        for(int hi = 0; hi < (int)IFM1[0].size(); hi++)
        {
            for(int ci = 0; ci < (int)IFM1[0][0].size(); ci++)
            {
                IFM1[wi][hi][ci] += IFM2[wi][hi][ci];
            }
        }
    }
}
