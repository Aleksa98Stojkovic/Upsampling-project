#include "SW.hpp"

using namespace std;
using namespace sc_core;
using namespace tlm;
using namespace sc_dt;

SW::SW(sc_module_name name) : sc_module(name)
{
    cout << "SW::SW is constructed" << endl;
    SC_METHOD(Software);
}

void SW::Software()
{

    pl_t pl;
    uint64 address;
    sc_time offset(0, SC_NS);
    tlm_command cmd;
    unsigned int data;
    unsigned int* data_ptr;

    // Config1
    cout << "SW::Writing config1" << endl;
    address = CONFIG1;
    data = 1600*8;
    data_ptr = &data;
    cmd = TLM_WRITE_COMMAND;
    pl.set_command(cmd);
    pl.set_address(address);
    pl.set_data_ptr(reinterpret_cast<unsigned char*> (data_ptr));
    soc->b_transport(pl, offset);

    // Config2
    cout << "SW::Writing config2" << endl;
    address = CONFIG2;
    data = 10816*8;
    data_ptr = &data;
    cmd = TLM_WRITE_COMMAND;
    pl.set_command(cmd);
    pl.set_address(address);
    pl.set_data_ptr(reinterpret_cast<unsigned char*> (data_ptr));
    soc->b_transport(pl, offset);

    // Config4
    cout << "SW::Writing config4" << endl;
    address = CONFIG4;
    data = 0;
    data |= (64 << 12);
    data_ptr = &data;
    cmd = TLM_WRITE_COMMAND;
    pl.set_command(cmd);
    pl.set_address(address);
    pl.set_data_ptr(reinterpret_cast<unsigned char*> (data_ptr));
    soc->b_transport(pl, offset);

    // Config5
    cout << "SW::Writing config5" << endl;
    address = CONFIG5;
    data = 8;
    data_ptr = &data;
    cmd = TLM_WRITE_COMMAND;
    pl.set_command(cmd);
    pl.set_address(address);
    pl.set_data_ptr(reinterpret_cast<unsigned char*> (data_ptr));
    soc->b_transport(pl, offset);

    // Config3
    cout << "SW::Writing config3" << endl;
    address = CONFIG3;
    data = 0x0019014a; // 0000 0000 0001 1001 0000 0001 0100 1010 // 0101 0011
    data_ptr = &data;
    cmd = TLM_WRITE_COMMAND;
    pl.set_command(cmd);
    pl.set_address(address);
    pl.set_data_ptr(reinterpret_cast<unsigned char*> (data_ptr));
    soc->b_transport(pl, offset);
}
