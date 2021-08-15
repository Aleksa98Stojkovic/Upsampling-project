#include "DRAM.hpp"

using namespace std;
using namespace sc_core;

DRAM::DRAM(sc_module_name name) : sc_channel(name)
{
    // Filling in dram with data drom a txt file
    ifstream file;
    file.open("data_sysc.txt");
    if(file.fail())
    {
        cerr << "DRAM::Error opening file!" << endl;
        exit(1);
    }

    while(!file.eof())
    {
        dram_word temp;
        file >> temp;
        input.push_back(temp);
    }

    file.close();


    cout << "DRAM::DRAM is constructed!" << endl;
}

void DRAM::read_router_dram(const int &address, vector<dram_word> &data)
{
    data.clear();
    for(int i = 0; i < DATA_DEPTH / 4; i++)
    {
        data.push_back(input[address + i]);
    }
}

void DRAM::write_pb_dram(vector<data_point> &data)
{
    for(int i = 0; i < DATA_DEPTH; i++)
        output.push_back(data[i]);


    // Writing results in a txt file
    if(output.size() == OUTPUT_DRAM_SIZE)
    {

        ofstream file;
        file.open("result_sysc.txt");
        if(file.fail())
        {
            cerr << "DRAM::Error opening file!" << endl;
            exit(1);
        }

        for(int i = 0; i < OUTPUT_DRAM_SIZE; i++)
        {
            file << output[i];
            file << endl;
        }

        file.close();

        // Signaling end of calculating output
        cout << "DRAM::Data has been written to a txt file" << endl;
    }
}
