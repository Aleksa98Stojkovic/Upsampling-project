#include "Router.hpp"

using namespace std;
using namespace sc_core;

Router::Router(sc_module_name name) : sc_channel(name)
{
    cout << "Router is constructed!" << endl;
}

void Router::read_cache_router(const int &address, vector<dram_word> &data)
{
    router_dram_port->read_router_dram(address, data);
}

void Router::write_reg_router(int &data)
{
    sel_mux = data;
}
