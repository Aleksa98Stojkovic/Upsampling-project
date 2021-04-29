#include "common.h"
#include <cmath>

t my_abs(t val)
{
    return (val < 0) ? (-val) : val;
}

void Quantize3D_uniform(float3D &IFM, int w, int f)
{
    num_t quantizer(w, f);

    t val = 0;
    unsigned int cnt = 0;

    for(int x = 0; x < (int)IFM.size(); x++)
    {
        for(int y = 0; y < (int)IFM[0].size(); y++)
        {
            for(int c = 0; c < (int)IFM[0][0].size(); c++)
            {

                cnt++;
                quantizer = IFM[x][y][c];
                val += my_abs(quantizer - IFM[x][y][c]);
                // std :: cout << "Greska je: " << abs(quantizer - IFM[x][y][c]) << std :: endl;
                IFM[x][y][c] = quantizer;

            }
        }
    }

    std :: cout << "Prosecna greska za 3D kvantizaciju je: " << val / ((t)cnt) << std :: endl;
}

void Quantize4D_uniform(float4D &W, int w, int f)
{

    t val = 0;
    unsigned int cnt = 0;

    num_t quantizer(w, f);
    for(int x = 0; x < (int)W.size(); x++)
    {
        for(int y = 0; y < (int)W[0].size(); y++)
        {
            for(int z = 0; z < (int)W[0][0].size(); z++)
            {
                for(int u = 0; u < (int)W[0][0][0].size(); u++)
                {
                    cnt++;
                    quantizer = W[x][y][z][u];
                    val += my_abs(quantizer - W[x][y][z][u]);
                    W[x][y][z][u] = quantizer;
                }
            }
        }
    }

    std :: cout << "Prosecna greska za 4D kvantizaciju je: " << val / ((t)cnt) << std :: endl;
}

void Quantized1D_uniform(std :: vector<t> &b, int w, int f)
{
    t val = 0;
    unsigned int cnt = 0;
    num_t quantizer(w, f);
    for(int x = 0; x < (int)b.size(); x++)
    {
        cnt++;
        quantizer = b[x];
        val += my_abs(quantizer - b[x]);
        b[x] = quantizer;
    }

    std :: cout << "Prosecna greska za 1D kvantizaciju je: " << val / ((t)cnt) << std :: endl;
}

double PSNR(const float3D &Original, const float3D &Quantized)
{
    double psnr = 0;

    for(int x = 0; x < (int)Original.size(); x++)
    {
        for(int y = 0; y < (int)Original[0].size(); y++)
        {
            for(int c = 0; c < (int)Original[0][0].size(); c++)
            {
                psnr += pow(Original[x][y][c] - Quantized[x][y][c], 2.0);
            }
        }
    }

    psnr /= Original.size() * Original[0].size() * Original[0][0].size();
    psnr = 20 * log10(255.0) - 10 * log10(psnr);

    return psnr;
}
