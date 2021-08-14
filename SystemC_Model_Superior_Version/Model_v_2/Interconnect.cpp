#include "Interconnect.hpp"

using namespace std;
using namespace sc_core;
using namespace tlm;
using namespace sc_dt;

Interconnect::Interconnect(sc_module_name name) : sc_module(name)
{
    cpu_soc.register_b_transport(this, &Interconnect::b_transport_cpu);
    cout << "Interconnect::Interconnect is constructed!" << endl;
}

void Interconnect::b_transport_cpu(pl_t &pl, sc_core::sc_time &offset)
{
    offset += sc_time(30 * CLK_PERIOD, SC_NS);
    config_soc->b_transport(pl, offset);
}
