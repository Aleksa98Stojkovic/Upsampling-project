#include "Conv2D.h"

void Conv2D(const vector<vector<vector<vector<float>>>> &W, const vector<vector<vector<float>>> &IFM, vector<vector<vector<float>>> &OFM)
{
    vector<vector<vector<float>>> IFM_new(IFM.size() + 2 , vector< vector<float>> (IFM[0].size() + 2, vector <float> (IFM[0][0].size())));

    // Inicijalizacija OFM
    for(int ci = 0; ci < (int)OFM[0][0].size(); ci++)
    {
        for(int hi = 0; hi < (int)OFM[0].size(); hi++)
        {
            for(int wi = 0; wi < (int)OFM.size(); wi++)
            {
                OFM[wi][hi][ci] = 0;
            }
        }
    }

    // dodavanje nula oko IFM
    for(int ci = 0; ci < (int)IFM.size(); ci++)
    {
        for(int hi = 0; hi < (int)IFM[0].size() + 2; hi++)
        {
            for(int wi = 0; wi < (int)IFM[0][0].size() + 2; wi++)
            {
                if(wi == 0 || hi == 0 || wi == (int)IFM[0][0].size() + 1 || hi == (int)IFM[0].size() + 1)
                    IFM_new[wi][hi][ci] = 0;
                else
                    IFM_new[wi][hi][ci] = (int)IFM[wi - 1][hi - 1][ci];
            }
        }
    }

   // Konvolucija
    for(int y = 0; y < (int)IFM[0].size(); y++)
    {
        for(int x = 0; x < (int)IFM[0][0].size(); x++)
        {
            for(int kn = 0; kn < (int)W.size(); kn++)
            {
                for(int kd = 0; kd < (int)W[0][0][0].size(); kd++)
                {
                    for(int kw = 0; kw < (int)W[0].size(); kw++)
                    {
                        for(int kh = 0; kh < (int)W[0][0].size(); kh++)
                        {
                            if((y < (int)IFM[0].size() - 1) && ((x < (int)IFM.size() - 1)))
                                OFM[x][y][kn] += IFM_new[x + kw][y + kh][kd] * W[kn][kw][kh][kd];
                        }
                    }
                }
            }
        }
    }
}
}
