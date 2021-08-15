#include "HW.hpp"

using namespace std;
using namespace sc_core;
using namespace tlm;
using namespace sc_dt;

HW::HW(sc_module_name name) :
    sc_module(name),
    ip("IP"),
    interconnect("Interconnect"),
    dram("DRAM"),
    config("Configuration_registers")

{
    cpu_soc.register_b_transport(this, &HW::b_transport_cpu);

    // Remaining IP connections
    ip.pb.pb_dram_port.bind(dram);         // PB
    ip.router.router_dram_port.bind(dram); // router

    // Config
    config.reg_router_port.bind(ip.router);
    config.reg_cache_port.bind(ip.cache);
    config.reg_wmem_port.bind(ip.wmem);
    config.reg_pb_port.bind(ip.pb);
    config.bus_soc.bind(interconnect.config_soc);

    // Interconnect
    Interconnect_soc.bind(interconnect.cpu_soc);

    cout << "HW::HW is constructed!" << endl;

}

void HW::b_transport_cpu(pl_t& pl, sc_core::sc_time& offset)
{
    Interconnect_soc->b_transport(pl, offset);
}
