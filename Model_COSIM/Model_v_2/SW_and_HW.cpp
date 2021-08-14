#include "TB.hpp"

using namespace std;
using namespace sc_core;
using namespace tlm;
using namespace sc_dt;

SW_and_HW::SW_and_HW(sc_module_name name) : sc_module(name)
{
    cout << "SW_and_HW::SW_and_HW is constructed" << endl;
    SC_METHOD(Software);
}

void SW_and_HW::Software()
{
}
