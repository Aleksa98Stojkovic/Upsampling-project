#include "Config.hpp"

using namespace std;
using namespace sc_core;
using namespace tlm;
using namespace sc_dt;

Config::Config(sc_module_name name) : sc_module(name)
{
    bus_soc.register_b_transport(this, &Config::b_transport_config);
    cout << "Config::Config is constructed!" << endl;
}

void Config::b_transport_config(pl_t &pl, sc_core::sc_time &offset)
{

    offset += sc_time((576 * OUTPUT_DRAM_SIZE / 64 + 3000), SC_NS); // time spent on calculating output


    uint64 addr = pl.get_address();
    tlm_command cmd = pl.get_command();
    int data = *(reinterpret_cast<int*>(pl.get_data_ptr()));

    if(cmd == TLM_WRITE_COMMAND)
    {
        switch(addr)
        {
            case CONFIG1:
                reg_wmem_port->write_reg_wmem(WEIGHT_BASE_ADDRESS_SAHE, data);
                pl.set_response_status(TLM_OK_RESPONSE);
                break;
            case CONFIG2:
                reg_pb_port->write_reg_pb(WRITE_BASE_ADDRESS_SAHE, data);
                pl.set_response_status(TLM_OK_RESPONSE);
                break;
            case CONFIG3:
                {
                    int t_data = data & C3_MASK0;
                    reg_router_port->write_reg_router(t_data);
                    t_data = (data & C3_MASK1) >> 1;
                    reg_pb_port->write_reg_pb(RELU_SAHE, t_data);
                    t_data = (data & C3_MASK2) >> 3;
                    reg_wmem_port->write_reg_wmem(WMEM_START_SAHE, t_data);
                    t_data = (data & C3_MASK3) >> 4;
                    reg_cache_port->write_reg_cache(CACHE_START_SAHE, t_data);
                    t_data = (data & C3_MASK4) >> 5;
                    reg_cache_port->write_reg_cache(HEIGHT_SAHE, t_data);
                    t_data = (data & C3_MASK5) >> 14;
                    reg_cache_port->write_reg_cache(TOTAL_SAHE, t_data);
                    pl.set_response_status(TLM_OK_RESPONSE);
                }
                break;
            case CONFIG4:
                {
                    int t_data = (data & C4_MASK1);
                    reg_pb_port->write_reg_pb(BIAS_BASE_ADDRESS_SAHE, t_data);
                    t_data = (data & C4_MASK2) >> 12;
                    reg_pb_port->write_reg_pb(NUM_OF_PIX_SAHE, t_data);
                    pl.set_response_status(TLM_OK_RESPONSE);
                }
                break;
            case CONFIG5:
                reg_pb_port->write_reg_pb(OUTPUT_WIDTH_SAHE, data);
                pl.set_response_status(TLM_OK_RESPONSE);
                break;
            default:
                pl.set_response_status(TLM_ADDRESS_ERROR_RESPONSE);
                cout << "Config::Error while trying to write data" << endl;

        }

    }
    else
    {
        // TLM read operation not yet implemented
        // ###################################### //
        pl.set_response_status(TLM_COMMAND_ERROR_RESPONSE);
        cout << "Config::Wrong command!" << endl;
    }

}

