#include "common.h"

void Write_DRAM_content(vector <dram_word> &data, vector <dram_word> &weights, dram_word* dram)
{
    for(int i = 0; i < (int)data.size(); i++)
        *(dram + i) = data[i];

    for(int i = 0; i < (int)weights.size(); i++)
        *(dram + (unsigned int)data.size() + i) = weights[i];
}

t Fxp2Float(dram_word *data)
{
    sint64 temp = *data;
    dram_word mask = 1;
    t q = pow(2.0, -2 * DP); // ako je broj bita za razlomljeni deo N, onda je q = 1 / (2 ^ N)
    t fp = 0;

    if(temp < 0)
    {
        temp = -temp;
        for(int i = 0; i < 64; i++)
        {
            if(temp & (mask << i))
                fp += q;
            q *= 2;
        }

        fp = -fp;
    }
    else
    {
        for(int i = 0; i < 64; i++)
        {
            if(temp & (mask << i))
                fp += q;

            q *= 2;
        }
    }

    return fp;
}

dram_word Float2Fxp(t &data, int n, int f)
{
    t q = pow(2.0, -f);
    unsigned temp;
    int temp;
    bool pos;
    dram_word out;
    int limit = pow(2, n) - 1;
    int base_mask = pow(2, f) - 1;

    if(data >= 0)
        pos = true;
    else
        pos = false;

    temp = (t)((int)(data / t));

    if(!pos)
    {
        temp = -temp;
        if((temp >> f) > limit)
        {
            temp &= base_mask;
            temp |= (limit << f);
        }

        temp =- temp;

    }
    else
    {
        if((temp >> f) > limit)
        {
            temp &= base_mask;
            temp |= (limit << f);
        }
    }

    return temp;
}
