#ifndef INTERFACES_HPP_INCLUDED
#define INTERFACES_HPP_INCLUDED

// Interface between pb and cache : CACHE IS TARGET
class pb_cache_if: virtual public sc_core::sc_interface
{
    public:
        virtual void read_pb_cache() = 0;
};

// Interface between registers and cache : CACHE IS TARGET
class reg_cache_if: virtual public sc_core::sc_interface
{
    public:
        virtual void write_reg_cache(const int sahe_number, int &data) = 0;
};

// Interface between registers and PB : PB IS TARGET
class reg_pb_if: virtual public sc_core::sc_interface
{
    public:
        virtual void write_reg_pb(const int sahe_number, int &data) = 0;
};

// Interface between registers and WMEM : WMEM IS TARGET
class reg_wmem_if: virtual public sc_core::sc_interface
{
    public:
        virtual void write_reg_wmem(const int sahe_number, int &data) = 0;
};

// Interface between registers and router : ROUTER IS TARGET
class reg_router_if: virtual public sc_core::sc_interface
{
    public:
        virtual void write_reg_router(int &data) = 0;
};

// Interface between cache and the router : CACHE IS INITIATOR
class cache_router_if: virtual public sc_core::sc_interface
{
    public:
        virtual void read_cache_router(const int &address, std::vector<dram_word> &data) = 0;
};

// Interface between cache and PB : CACHE IS INITIATOR
class cache_pb_if: virtual public sc_core::sc_interface
{
    public:
        virtual void write_cache_pb(std::vector<data_point> &data) = 0;
        virtual void run_cache_pb() = 0;
};

// Interface between PB and WMEM : PB IS INITIATOR
class pb_wmem_if: virtual public sc_core::sc_interface
{
    public:
        virtual void read_pb_wmem(const int &packet, std::vector<data_point> &data) = 0;
};

// Interface between PB and DRAM : PB IS INITIATOR
class pb_dram_if: virtual public sc_core::sc_interface
{
    public:
        // dram has to format the data properly
        virtual void write_pb_dram(std::vector<data_point> &data) = 0;
};

// Interface between router and DRAM : ROUTER IS INITIATOR
class router_dram_if: virtual public sc_core::sc_interface
{
    public:
        virtual void read_router_dram(const int &address, std::vector<dram_word> &data) = 0;
};

// Interface between IP_rtl_full and DRAM : IP_RTL_FULL IS INITIATOR
class ip_rtl_full_dram_if: virtual public sc_core::sc_interface
{
    public:
        virtual void read_ip_rtl_full_dram(const int &address, std::vector<dram_word> &data) = 0;
        virtual void write_ip_rtl_full_dram(std::vector<dram_word> &data) = 0;
};

#endif // INTERFACES_HPP_INCLUDED
