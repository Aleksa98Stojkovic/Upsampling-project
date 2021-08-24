#include "IP_rtl_full.hpp"

using namespace std;
using namespace sc_core;
using namespace sc_dt;
using namespace tlm;

IP_rtl_full::IP_rtl_full(sc_module_name name) :
    sc_module(name),
    clk_i("clk_i", 10, SC_NS),
    ip_rtl("HDL_Design")
{

    bus_soc.register_b_transport(this, &IP_rtl_full::b_transport_bus);

    SC_THREAD(AXI_read);
    SC_THREAD(AXI_write);
    SC_THREAD(Reset);
    SC_THREAD(ChangeConfig);

    // Clock and reset
    ip_rtl.clk_i(clk_i);
    ip_rtl.rst_i(rst_i);

    // Config registers
    ip_rtl.config1(config1);
    ip_rtl.config2(config2);
    ip_rtl.config3(config3);
    ip_rtl.config4(config4);
    ip_rtl.config5(config5);
    ip_rtl.config6(config6);

    // Axi write port
    ip_rtl.axi_write_address_o(axi_write_address_o);
    ip_rtl.axi_write_init_o(axi_write_init_o);
    ip_rtl.axi_write_data_o(axi_write_data_o);
    ip_rtl.axi_write_next_i(axi_write_next_i);
    ip_rtl.axi_write_done_i(axi_write_done_i);

    // Axi read port
    ip_rtl.axi_read_init_o(axi_read_init_o);
    ip_rtl.axi_read_data_i(axi_read_data_i);
    ip_rtl.axi_read_addr_o(axi_read_addr_o);
    ip_rtl.axi_read_last_i(axi_read_last_i);
    ip_rtl.axi_read_valid_i(axi_read_valid_i);
    ip_rtl.axi_read_ready_o(axi_read_ready_o);

    // Initializing config registers to 0
    config1.write(0);
    config2.write(0);
    config3.write(0);
    config4.write(0);
    config5.write(0);
}

void IP_rtl_full::ChangeConfig()
{

    while(true)
    {
        wait(clk_i.posedge_event());

        sc_lv<32> c6 = config6;
        if(c6.to_int() == 1)
        {
            config3.write(0x00190153);
        }
    }
}

// Reset signal has a value of one for 300ns, after that moments its value is 0
void IP_rtl_full::Reset()
{
    rst_i.write(SC_LOGIC_1);
    wait(20, SC_NS);
    rst_i.write(SC_LOGIC_0);
}

void IP_rtl_full::AXI_read()
{
    // LEGEND - state values
    // 0 - wait_init
    // 1 - delay
    // 2 - data

    int state = 0;
    int cnt_32 = 0;
    int cnt_64 = 0;
    int cnt_wmem_trans = 0;
    int address;
    int exit_flag = 0;
    vector <dram_word> data;
    
    int temp_state = -1;

    axi_read_data_i.write(0);
    axi_read_last_i.write(SC_LOGIC_0);
    axi_read_valid_i.write(SC_LOGIC_0);

    while(true)
    {
        wait(clk_i.posedge_event());

        axi_read_data_i.write(0);
        axi_read_last_i.write(SC_LOGIC_0);
        axi_read_valid_i.write(SC_LOGIC_0);

        switch(state)
        {
            case 0:
                {
                    cnt_64 = 0;
                    if(axi_read_init_o == SC_LOGIC_1)
                    {
                        state = 1;
                        sc_lv<32> temp = axi_read_addr_o;
                        address = temp.to_int() / 8;
                        data.clear();
                        ip_rtl_full_dram_port->read_ip_rtl_full_dram(address, data);
                    
			cnt_wmem_trans++;
		    }
                    else
                        state = 0;

                }
                break;

            case 1:
                {
                    cnt_32++;
                    state= 1;

                    if(cnt_32 == 32)
                    {
                        cnt_32 = 0;
                        state = 2;
                    }
                }

                break;

            case 2:
                {
			
		    // cout <<  "IP_rtl_full::cnt_64 is: " << cnt_64  << endl;

                    axi_read_valid_i.write(SC_LOGIC_1);
                    axi_read_data_i.write(data[cnt_64]);

                    state = 2;

                    if(cnt_64 == 63)
                        axi_read_last_i.write(SC_LOGIC_1);

                    if(axi_read_ready_o == SC_LOGIC_1)
                    {
                        if(cnt_64 == 63)
                        {
                            state = 0;

                            if(address == INPUT_DRAM_SIZE - 3 * 16)
                                exit_flag = 1;
                        }

                        cnt_64++;
			
			if(cnt_wmem_trans > WMEM_TRANS)
			{
			   axi_read_data_i.write(data[cnt_64]);
			}

		    }
                }
                break;
            default:
                cout << "IP_rtl_full::Wrong state!" << endl;
        }

	if(temp_state != state)
	{
		temp_state = state;
		cout << "IP_rtl_full::Current state of AXI_read is: " << temp_state << endl;
	}

        if(exit_flag)
        {
            wait(clk_i.posedge_event());
            axi_read_data_i.write(0);
            axi_read_last_i.write(SC_LOGIC_0);
            axi_read_valid_i.write(SC_LOGIC_0);
            break;
        }

    }

}

void IP_rtl_full::AXI_write()
{
    // LEGEND - state values
    // 0 - wait_init
    // 1 - delay
    // 2 - data
    // 3 - done

    int state = 0;
    int cnt_32 = 0;
    int cnt_64 = 0;
    int count_output = 0;
    int exit_flag = 0;
    int first = false;
    vector <dram_word> data;

    int temp_state = -1;

   for(int i = 0; i < 64; i++)
        data.push_back(0);

    axi_write_next_i.write(SC_LOGIC_0);
    axi_write_done_i.write(SC_LOGIC_0);

    while(true)
    {
        wait(clk_i.posedge_event());

        axi_write_next_i.write(SC_LOGIC_0);
        axi_write_done_i.write(SC_LOGIC_0);

        switch(state)
        {
            case 0:
                {
                    cnt_64 = 0;
                    if(axi_write_init_o == SC_LOGIC_1)
                    {
                        state = 1;
			first = false;
                    }
                    else
                        state = 0;

                }
                break;

            case 1:
                {
                    cnt_32++;
                    state= 1;

                    if(cnt_32 == 32)
                    {
                        cnt_32 = 0;
                        state = 2;
                    }
                }

                break;

            case 2:
                {	

                    axi_write_next_i.write(SC_LOGIC_1);
                    sc_lv<64> temp = axi_write_data_o;
                    
                    state = 2;

                    if(cnt_64 == 63)
                        state = 3;

		    if(!first)
		    {
			    data[cnt_64] = temp.to_int();
			    cout << "IP_rtl_full::Vreme odabiranja je AXI write data_o je: " << sc_time_stamp() << ", podatak je: " << data[cnt_64] << ", cnt_64 je: " << cnt_64 << endl;
			    cnt_64++;
	 	    }

		    first = false;
                }
                break;

            case 3:

		state = 0;

                ip_rtl_full_dram_port->write_ip_rtl_full_dram(data);
                axi_write_done_i.write(SC_LOGIC_1);
                count_output++;
                if(count_output == OUTPUT_DRAM_SIZE / DATA_DEPTH)
                    exit_flag = 1;

                break;

            default:
                cout << "IP_rtl_full::Wrong state!" << endl;
        }

	if(temp_state != state)
	{
		temp_state = state;
		cout << "IP_rtl_full::Current state of AXI_write is: " << temp_state << endl;
	}

        if(exit_flag)
        {
            wait(clk_i.posedge_event());
            axi_write_next_i.write(SC_LOGIC_0);
            axi_write_done_i.write(SC_LOGIC_0);
            break;
        }

    }

}

// TLM communicaion for writing and reading config registers
void IP_rtl_full::b_transport_bus(pl_t& pl, sc_core::sc_time& offset)
{
    uint64 addr = pl.get_address();
    tlm_command cmd = pl.get_command();
    unsigned char* data_ptr = pl.get_data_ptr();
    int data = *(reinterpret_cast<int*>(pl.get_data_ptr()));

    if(cmd == TLM_WRITE_COMMAND)
    {
        switch(addr)
        {
            case CONFIG1:
                config1.write(data);
                pl.set_response_status(TLM_OK_RESPONSE);
                break;

            case CONFIG2:
                config2.write(data);
                pl.set_response_status(TLM_OK_RESPONSE);
                break;

            case CONFIG3:
                config3.write(data);
                pl.set_response_status(TLM_OK_RESPONSE);

                break;

            case CONFIG4:
                config4.write(data);
                pl.set_response_status(TLM_OK_RESPONSE);
                break;

            case CONFIG5:
                config5.write(data);
                pl.set_response_status(TLM_OK_RESPONSE);
                break;

            default:
                pl.set_response_status(TLM_ADDRESS_ERROR_RESPONSE);
                cout << "Config::Error while trying to write data" << endl;

        }

    }
    else if(cmd == TLM_READ_COMMAND)
    {
        if(addr == CONFIG6)
        {
            sc_lv<32> temp = config6;
            data_ptr = reinterpret_cast<unsigned char*>(temp.to_int());
            pl.set_response_status(TLM_OK_RESPONSE);
        }
        else
        {
            pl.set_response_status(TLM_ADDRESS_ERROR_RESPONSE);
            cout << "Config::Error while trying to read data" << endl;
        }
    }
    else
    {
        pl.set_response_status(TLM_COMMAND_ERROR_RESPONSE);
        cout << "Config::Wrong command!" << endl;
    }

}

