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
            for(int c = 0; c < (int)OFM[0][0].size(); c++)
            {
                str = to_string(OFM[x][y][c]);
                file << str << ",";
            }
        }
    }
    file.close();
}

// Ucitavanje tezina
// Fajl je sledeceg formata: Za svaki filtar stapic imamo jednu lniju
// Unutar linije imamo zaredjano 64 kernela, pri cemu je forma vidljiva na primeru
// [[1, 2, 3],  ovaj kernel ce se ispraviti u 1D niz 1,2,3,4,5,6,7,8,9
//  [4, 5, 6],
//  [7, 8, 9]]
// Ako je sledeci kernel unutar tog filter stapica bio
// [[3, 4, 1], onda se on spaja na prethodni, pa se u liniji nalazi 1,2,3,4,5,6,7,8,9,3,4,1,5,1,45,32,12,2
//  [5, 1, 45],
//  [32, 12, 2]]
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

        for(int d = 0; d < (int)(W[0][0][0].size()); d++)
        {
            for(int x = 0; x < (int)(W[0].size()); x++)
            {
                for(int y = 0; y < (int)(W[0][0].size()); y++)
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
        for(int x = 0; x < (int)OFM.size(); x++)
        {
            for(int y = 0; y < (int)OFM[0].size(); y++)
            {
                OFM[x][y][ci] = 0;
            }
        }
    }

    // dodavanje nula oko IFM[height][width][channel]
    for(int c = 0; c < (int)IFM_new[0][0].size(); c++) // 0 - 63
    {
        for(int x = 0; x < (int)(IFM_new.size()); x++) // 0 - 119
        {
            for(int y = 0; y < (int)(IFM_new[0].size()); y++) // 0 - 125
            {
                // ako je w = 124 i h = 118, onda gledam da li se nalazim na pikselu sa kordinatama
                // x pripada [1, 122] i y pripada [1, 116]
                if((x > 0) && (x < ((int)(IFM_new.size()) - 1)) && (y > 0) && (y < ((int)(IFM_new[0].size()) - 1)))
                    IFM_new[x][y][c] = IFM[x - 1][y - 1][c];
                else
                    IFM_new[x][y][c] = 0;
            }
        }
    }

    for(int kd = 0; kd < (int)W[0][0][0].size(); kd++) // Odaberi ulazni kanal
    {
        for(int x = 1; x < (int)IFM_new.size() - 1; x++) // setam se izmedju 1 i 118(max 0 do 119)
        {
            for(int y = 1; y < (int)IFM_new[0].size() - 1; y++) // setam se izmedju 1 i 124(max 0 do 125)
            {
                for(int kn = 0; kn < (int)W.size(); kn++) // stema se kroz svaki filter stapic 3x3x64
                {
                    for(int kh = 0; kh < (int)W[0].size(); kh++) // prodji kroz svaku vrstu 3x3 kernela
                    {
                        for(int kw = 0; kw < (int)W[0][0].size(); kw++) // prodji kroz svaku kolonu 3x3 kernela
                        {
                            OFM[x - 1][y - 1][kn] += IFM_new[x - 1 + kh][y - 1 + kw][kd] * W[kn][kh][kw][kd];
                        }
                    }
                }
            }
        }
    }
}

/*
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
void Add(vector<vector<vector<float>>> &IFM1, const vector<vector<vector<float>>> &IFM2)
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
*/

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

    vector < vector < vector <float>>> IFM(h, vector <vector <float>> (w, vector <float> (c)));
    vector < vector < vector <float>>> OFM(h, vector <vector <float>> (w, vector <float> (c)));
    vector < vector < vector < vector <float>>>> W(kn, vector<vector<vector<float>>>(kh, vector<vector<float>>(kw, vector<float>(kd))));

    /*
    // inicijalizacija IFM sa nekim slucajnim vrednostima
    for(int x = 0; x < (int)IFM.size(); x++)
    {
        for(int y = 0; y < (int)IFM[0].size(); y++)
        {
            for(int z = 0; z < (int)IFM[0][0].size(); z++)
            {
                IFM[x][y][z] = (float)rand() / 100.0;
            }
        }
    }
    */

    ifstream file;
    vector <float> numbers;
    file.open("test_input.txt");
    string line;
    getline(file, line);
    stringstream sline(line);
    while(sline.good())
    {
        string str;
        getline(sline, str, ',');
        if(numbers.size() < IFM.size() * IFM[0].size() * IFM[0][0].size())
            numbers.push_back(stof(str));
    }
    cout << "Dovde sam stigao" << endl;
    cout << numbers.size() << endl;
    for(int c = 0; c < (int)IFM[0][0].size(); c++)
    {
        for(int x = 0; x < (int)IFM.size(); x++)
        {
            for(int y = 0; y < (int)IFM[0].size(); y++)
            {
                IFM[x][y][c] = numbers[0];
                numbers.erase(numbers.begin());
            }
        }
    }
    file.close();
    cout << "Ucitan je ulaz" << endl;

    LoadFile("test_weights.txt", W);
    cout << "Ucitane su tezine" << endl;
    Conv2D(W, IFM, OFM);
    cout << "Odradjena je konvolucija" << endl;
    WriteFile("Conv2D_result.txt", OFM);
    cout << "Rezultat je upisan" << endl;

    return 0;
}
