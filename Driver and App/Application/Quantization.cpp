#include "common.h"

using namespace std;

void Write_DRAM_content(vector <dram_word> &data, vector <dram_word> &weights, dram_word* dram)
{
    for(int i = 0; i < (int)data.size(); i++)
        *(dram + i) = data[i];

    for(int i = 0; i < (int)weights.size(); i++)
        *(dram + (unsigned int)data.size() + i) = weights[i];
}

t Fxp2Float(dram_word *data) // Ovo radi
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

dram_word Float2Fxp(t &data, int n, int f) // Ovo radi
{
    t q = pow(2.0, -f); // 2^-11
    int temp;
    bool pos;
    int limit = pow(2, n) - 1;
    int base_mask = pow(2, f) - 1;

    if(data >= 0)
        pos = true;
    else
        pos = false;

    temp = (int)floor(data / q);

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

void formatData(vector <dram_word> &data_o, float3D &data_i)
{
    data_o.clear();
    dram_word data_t;
    dram_word data_q;

    for(int y = 0; y < (int)data_i[0].size(); y++)
    {
        for(int x = 0; x < (int)data_i.size(); x++)
        {
            // Podrazumevamo da imamo 64 kanala
            for(int c1 = 0; c1 < (int)data_i[0][0].size() / 4; c1++) // 16 iteracija
            {
                data_t = 0;

                for(int c2 = 0; c2 < 4; c2++) // 4 iteracije
                {
                    data_q = Float2Fxp(data_i[x][y][c1 * 4 + c2], 5, 11); // radimo kvantizaciju podataka
                    data_t |= (data_q & DATA_MASK) << (DATA_WIDTH * c2);
                }

                data_o.push_back(data_t);
            }
        }
    }
}

void formatWeight(vector <dram_word> &weight_o, string path)
{
    weight_o.clear();
    ifstream file;
    file.open(path);

    if(file.fail())
    {
        cerr << "Greska prilikom otvaranja fajla!" << endl;
        exit(1);
    }

    while(!file.eof())
    {
        dram_word temp;
        file >> temp;
        weight_o.push_back(temp);
    }

    file.close();
}

void formatDataIP(float3D &data, dram_word* data_ip)
{
    // izlaz ima manju sirinu i visinu za 2 od ulaza
    int height = (int)data.size() - 2;
    int width = (int)data[0].size() - 2;
    int depth = (int)data[0][0].size();

    float3D new_data(height, vector <vector <t>> (width, vector <t> (depth)));

    // pokazivac na pocetak izlaza
    dram_word* start_out;
    start_out = data_ip;
    start_out += (unsigned int)data.size() * (unsigned int)data[0].size() * (unsigned int)data[0][0].size() / 4 + 9 * 64 * 64 / 4;

    for(int x = 0; x < width; x++)
    {
        for(int y = 0; y < height; y++)
        {
            for(int c = 0; c < depth; c++)
            {
                new_data[x][y][c] = Fxp2Float(start_out++);
            }
        }
    }

    data = new_data;
    new_data.clear();
}

void zero_padding(float3D &data)
{
    int height = (int)data.size() + 2;
    int width = (int)data[0].size() + 2;
    int depth = (int)data[0][0].size();

    float3D new_data(height, vector <vector <t>> (width, vector <t> (depth)));

    // Inicijalizujemo vektor sa nulama
    for(int x = 0; x < width; x++)
    {
        for(int y = 0; y < height; y++)
        {
            for(int c = 0; c < depth; c++)
            {
                new_data[x][y][c] = 0;
            }
        }
    }

    // Dodajemo nenulte elemente na odgovarajuce pozicije
    for(int x = 0; x < width - 2; x++)
    {
        for(int y = 0; y < height - 2; y++)
        {
            for(int c = 0; c < depth; c++)
            {
                new_data[x + 1][y + 1][c] = data[x][y][c];
            }
        }
    }
}
