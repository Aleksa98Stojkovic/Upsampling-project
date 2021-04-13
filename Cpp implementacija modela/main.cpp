#include <iostream>
#include <cstdlib>
#include <ctime>
#include <sstream>
#include <string>
#include <vector>
#include <fstream>

using namespace std;

// Srednje vrednosti dataseta po kanalu slike
const vector <float> mean = {114.44399999999999, 111.4605, 103.02000000000001};

// Upisivanje rezultata
void WriteFile(string path, const vector <vector <vector <float>>> &OFM)
{
    string str;
    ofstream file;
    file.open(path, ios_base :: app);
    for(int x = 0; x < (int)OFM.size(); x++)
    {
        for(int y = 0; y < (int)OFM[0].size(); y++)
        {
            for(int c = 0; x < (int)OFM[0][0].size(); c++)
            {
                str = to_string(OFM[x][y][c]);
                file << str << ",";
            }
        }
    }
    file.close();
}

// Ucitavanje tezina
void LoadFile(string path, vector < vector < vector < vector <float>>>> &W)
{
    ifstream file(path);
    vector <float> numbers;
    string line;
    int n = 0;

    while(getline(file, line))
    {
        stringstream sline(line);
        n = 0;
        while(sline.good())
        {
            string str;
            getline(sline, str, ',');
            if(numbers.size() < W.size() * W[0].size() * W[0][0].size())
                numbers.push_back(stof(str));
        }

        for(int x = 0; x < (int)(W[0].size()); x++)
        {
            for(int y = 0; y < (int)(W[0][0].size()); y++)
            {
                for(int d = 0; d < (int)(W[0][0][0].size()); d++)
                {
                    W[n][x][y][d] = numbers[0];
                    numbers.erase(numbers.begin());
                }
            }
        }
        n++;
    }
    file.close();
}

// Konvolucija
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

// Normalizacija podataka
void Normalize(vector<vector<vector<float>>> &IFM)
{
    for(int wi = 0; wi < (int)IFM.size(); wi++)
    {
        for(int hi = 0; hi < (int)IFM[0].size(); hi++)
        {
            for(int ci = 0; ci < (int)IFM[0][0].size(); ci++)
            {
                IFM[wi][hi][ci] = (IFM[wi][hi][ci] - mean[ci]) / 127.5;
            }
        }
    }
}

// Denormalizacija podataka
void Denormalize(vector<vector<vector<float>>> &IFM)
{
    for(int wi = 0; wi < (int)IFM.size(); wi++)
    {
        for(int hi = 0; hi < (int)IFM[0].size(); hi++)
        {
            for(int ci = 0; ci < (int)IFM[0][0].size(); ci++)
            {
                IFM[wi][hi][ci] = 127.5 * IFM[wi][hi][ci] + mean[ci];
            }
        }
    }
}

// Sabiranje
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

// Glavna funkcija
int main()
{

    int kn, kd, kw, kh, w, h, c;

    w = 124;
    h = 118;
    c = 64;
    kw = kh = 3;
    kd = 64;
    kn = 64;

    vector < vector < vector <float>>> IFM(w, vector <vector <float>> (h, vector <float> (c)));
    vector < vector < vector <float>>> OFM(w, vector <vector <float>> (h, vector <float> (c)));
    vector < vector < vector < vector <float>>>> W(kn, vector<vector<vector<float>>>(kw, vector<vector<float>>(kh, vector<float>(kd))));

    for(int x = 0; x < h; x++)
    {
        for(int y = 0; y < w; y++)
        {
            for(int z = 0; z < c; z++)
            {
                IFM[x][y][z] = (float)rand() / 100.0;
            }
        }
    }

    LoadFile("weights10.txt", W);
    cout << W.size() << " " << W[0].size() << " " << W[0][0].size() << " " << W[0][0][0].size() << endl;
    Conv2D(W, IFM, OFM);


    return 0;
}
