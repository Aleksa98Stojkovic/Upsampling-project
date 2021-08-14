#include "WMEM.hpp"

using namespace std;
using namespace sc_core;


WMEM::WMEM(sc_module_name name) : sc_channel(name)
{

    // Generate a signal when WMEM is full
    // ################################### //

    // Loading weights from a file
    vector<data_point> t1, t2;

    ifstream file;
    file.open("weights_sysc.txt");
    if(file.fail())
    {
        cerr << "WMEM::Error opening file!" << endl;
        exit(1);
    }

    for(int i = 0; i < 3 * 3 * DATA_DEPTH * DATA_DEPTH; i++)
    {
        data_point temp;
        file >> temp;
        t1.push_back(temp);
    }

    file.close();

    for(int p = 0; p < DATA_DEPTH; p++)
    {
        for(int off = 0; off < 3 * 3 * DATA_DEPTH; off++)
        {
            t2.push_back(t1[p * (3 * 3 * DATA_DEPTH) + off]);
        }

        weights.push_back(t2);
        t2.clear();
    }

    cout << "WMEM::WMEM is constractued!" << endl;
}

void WMEM::read_pb_wmem(const int &packet, std::vector<data_point> &data)
{
    data = weights[packet];
}

void WMEM::write_reg_wmem(const int sahe_number, int &data)
{
    switch(sahe_number)
    {
        case WEIGHT_BASE_ADDRESS_SAHE:
            weight_base_address = data;
            break;
        case WMEM_START_SAHE:
            start = data;
            break;
        default:
            cout << "WMEM::This SAHE does not exist!" << endl;
    }
}
