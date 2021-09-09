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
    int limit = (pow(2, n) - 1) >> 1; // 01111
    int base_mask = pow(2, f) - 1; // 0x000007ff

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
    int mask = 0x0000ffff;
    dram_word data_item;

    ifstream file;
    vector <int> numbers;
    string line;
    file.open(path);
    while(getline(file, line))
    {
        stringstream sline(line);

        while(sline.good())
        {
            string str;
            getline(sline, str, ',');
            if(numbers.size() < 4)
                numbers.push_back(stoi(str));
        }

        data_item = 0;
        for(int i = 0; i < 4; i++)
            data_item |= (mask & numbers[i]) << ((3 - i) * DATA_WIDTH);

        weight_o.push_back(data_item);
        numbers.clear();

    }
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
    start_out += ((height + 2) * (width + 2) * depth / 4 + 9 * 64 * 64 / 4) * 8;

    for(int x = 0; x < width; x++)
    {
        for(int y = 0; y < height; y++)
        {
            for(int c = 0; c < depth; c++)
            {
                new_data[x][y][c] = Fxp2Float(start_out);
				start_out += 8;
            }
        }
    }
	
	data.clear();
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

    data.clear();
    data = new_data;
    new_data.clear();
}

void zero_padding_input(float3D &data)
{
    int height = (int)data.size();
    int width = (int)data[0].size();
    int depth = 64;
    float3D new_data(height, vector <vector <t>> (width, vector <t> (depth)));

    for(int x = 0; x < width; x++)
    {
        for(int y = 0; y < height; y++)
        {
            for(int c = 0; c < depth; c++)
            {
				if(c < 3)
					new_data[x][y][c] = data[x][y][c];
				else
					new_data[x][y][c] = 0;
            }
        }
    }

    data.clear();
    data = new_data;
    new_data.clear();
}

void write_driver(string path, int reg_num, int val)
{
        string write_item = to_string(reg_num) + "=" + to_string(val);

        ofstream file;
        file.open(path);
        if(file.fail())
        {
            cerr << "Greska prilikom upisivanja!" << endl;
            exit(1);
        }

        file << write_item;

        file.close();
}

int read_driver(string path, bool read_pointer)
{
    string read_item;

    ifstream file;
    file.open(path);
    if(file.fail())
    {
        cerr << "Greska prilikom citanja!" << endl;
        exit(1);
    }

    file >> read_item;

    file.close();

    string pointer, reg;
    int len = 0;

    for(int i = 0; i < (int)read_item.length(); i++)
    {
        len++;

        if(read_item[i] == ',')
        {
            pointer = read_item.substr(0, len - 1);
            reg = &read_item[i + 1];
            break;
        }
    }

    if(read_pointer)
        return stoi(pointer);
    else
        return stoi(reg);
}

void convlove(float3D &data_i, string w_path, int layer_num, int relu)
{
    string driver_path = "/dev/upsampling";

    // Dodaj nule oko ulaza
    zero_padding(data_i);
    // Citamo i formatiramo tezine
    vector<dram_word> weights;
    formatWeight(weights, w_path);
    // Formatiramo ulaze
    vector<dram_word> data;
    formatData(data, data_i);


    // Upis u registre
    int height = (int)data_i.size();
    int width = (int)data_i[0].size();
    int depth = (int)data_i[0][0].size();
    int val;
    int temp;

    val = layer_num * 64;
    temp = 12;
    val |= ((width - 2) * (height - 2)) << temp;
    write_driver(driver_path, 4, val);      // config4

    val = width - 2;
    write_driver(driver_path, 5, val);      // config5

    val = 0;                                // sel
    val |= relu << 1;                       // relu
    val |= height << 5;                     // height
    val |= (height * width) << 14;          // total
    write_driver(driver_path, 3, val);      // config3
	
	write_driver(driver_path, -1, 0);       // Rezervacija memorije
	
	// Procitaj pokazivac
    dram_word* dram = (dram_word*)(read_driver(driver_path, true));
	
	// Upis podataka u blok memorije u DDR-u
    Write_DRAM_content(data, weights, dram);
	
	int base = (read_driver(driver_path, true));
	
	val = base + (height * width * depth / 4) * 8;
    write_driver(driver_path, 1, val);      // config1

    val = base + (height * width * depth / 4 + 3 * 3 * 64 * 16) * 8;
    write_driver(driver_path, 2, val);      // config2
	
	val |= 1 << 3;							// Pokrecemo popunjavanje memorije
	write_driver(driver_path, 3, val);      // config3

    // Cekamo da se memorija popuni
    while(read_driver(driver_path, false) == 1); // 00, 01, 10, 11

    val = 1;                                // sel
    val |= relu << 1;                       // relu
    val |= 0 << 3;                          // wmem_start
    val |= 1 << 4;                          // cache_start
    val |= height << 5;                     // height
    val |= (height * width) << 14;          // total
    write_driver(driver_path, 3, val);      // config3

    // Cekamo da se zavrsi obrada podataka
    while(read_driver(driver_path, false) == 3);

    // Formatira izlaze
    data_i.clear();
    formatDataIP(data_i, dram + (height * width * depth / 4 + 3 * 3 * 64 * 16) * 8);
	
	write_driver(driver_path, -1, 1);       // Oslobadjanje memorije
}
