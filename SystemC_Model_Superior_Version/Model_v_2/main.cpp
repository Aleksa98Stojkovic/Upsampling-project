#include <iostream>

#include "HW.hpp"
#include "SW.hpp"

using namespace std;
using namespace sc_core;
using namespace tlm;
using namespace sc_dt;

typedef tlm::tlm_base_protocol_types::tlm_payload_type pl_t;


int sc_main(int argc ,char* argv[])
{

	SW sw("Software");
	HW hw("Hardware");

    sw.soc.bind(hw.cpu_soc);

	sc_start();

	return 0;
}
