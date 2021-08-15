#include "PB.hpp"

using namespace std;
using namespace sc_core;

PB::PB(sc_module_name name) : sc_channel(name)
{
    SC_THREAD(Process);
    sensitive << run;
    dont_initialize();

    // initializing bias (for modeling purposes)
    for(int i = 0; i < DATA_DEPTH; i++)
    {
        bias.push_back(0); // all zeros
    }

    // initializing data_stick
    for(int i = 0; i < KERNEL_SIZE * DATA_DEPTH; i++)
    {
        data_stick.push_back(0); // all zeros
    }

    cout << "PB::PB is constructed!" << endl;
}

void PB::Process()
{

    vector<data_point> output_data;
    vector<data_point> weight;

    for(int x = 0; x < num_of_pix / output_width; x++)
    {
        for(int y = 0; y < output_width; y++)
        {

            pb_cache_port->read_pb_cache();             // requesting data from cache
            wait();                                     // waiting for data

            for(int packet = 0; packet < DATA_DEPTH; packet++)
            {
                weight.clear();
                pb_wmem_port->read_pb_wmem(packet, weight); // requesting weights from WMEM

                // Calaculating output value
                data_point acc = 0;
                for(int i = 0; i < (int)weight.size(); i++)
                {
                    acc += weight[i] * data_stick[i];
                }

                // adding bias
                acc += bias[packet];

                // applying relu
                if(relu)
                {
                    if(acc < 0)
                        acc = 0;
                }

                // adding final result to output data stick
                output_data.push_back(acc);
            }

            // -------------------- DEBUG --------------------//
//            if(x == 0 && y == 0)
//            {
//                cout << "PB::first data stick is: " << endl;
//
//                for(int i = 0; i < (int)data_stick.size(); i++)
//                {
//                    cout << data_stick[i] << endl;
//                }
//            }

            // cout << "PB::PB writes data to a DRAM memory" << endl;

            // ---------------------------------------------- //
            pb_dram_port->write_pb_dram(output_data);
            output_data.clear();
        }
    }
    // Generate signal to inform software that processing is done
    // ######################################################### //
}


void PB::write_cache_pb(std::vector<data_point> &data)
{

    for(int i = 0; i < (int)data.size(); i++)
        data_stick[i] = data[i];

    run.notify();
}

void PB::run_cache_pb()
{
    run.notify();
}

void PB::write_reg_pb(const int sahe_number, int &data)
{
    switch(sahe_number)
    {
        case WRITE_BASE_ADDRESS_SAHE:
            write_base_address = data;
            break;
        case NUM_OF_PIX_SAHE:
            num_of_pix = data;
            break;
        case BIAS_BASE_ADDRESS_SAHE:
            bias_base_address = data;
            break;
        case OUTPUT_WIDTH_SAHE:
            output_width = data;
            break;
        case RELU_SAHE:
            relu = data;
            break;
        default:
            cout << "PB::This SAHE does not exist!" << endl;
    }
}





