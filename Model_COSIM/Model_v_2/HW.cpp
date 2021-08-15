#include "HW.hpp"

using namespace std;
using namespace sc_core;
using namespace tlm;
using namespace sc_dt;

HW::HW(sc_module_name name) :
    sc_module(name),
    ip_rtl_full("IP_rtl_full"),
    interconnect("Interconnect"),
    dram("DRAM")

{
    cpu_soc.register_b_transport(this, &HW::b_transport_cpu);

    // Remaining IP_rtl_full connections
    ip_rtl_full.ip_rtl_full_dram_port.bind(dram);       // DRAM
    ip_rtl_full.bus_soc.bind(interconnect.config_soc); // Interconnect

    // Interconnect
    Interconnect_soc.bind(interconnect.cpu_soc);

    cout << "HW::HW is constructed!" << endl;

}

void HW::b_transport_cpu(pl_t& pl, sc_core::sc_time& offset)
{
    Interconnect_soc->b_transport(pl, offset);
}
