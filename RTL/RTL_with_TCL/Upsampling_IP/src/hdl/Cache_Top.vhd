----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.07.2021 21:30:19
-- Design Name: 
-- Module Name: Cache_Top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Cache_Top is
    Generic(
    
        col_width : natural := 9;
        i_width : natural := 10;
        addr_width : natural := 8;
        cache_line_count : natural := 15;
        kernel_size : natural := 9;
        RF_addr_width : natural := 4;
        cache_width : natural := 64;
        Read_data_width : natural := 16;
        size       : natural := 240
        
    );
    Port (
        clk_i : in std_logic;
        rst_i : in std_logic;
        
        ------------ PB --------------
        reg_i : in std_logic;
        end_i : in std_logic;
        d_valid_o : out std_logic;
        cache_data_o : out std_logic_vector(Read_data_width - 1 downto 0);
        
        ------------ Config -----------
        config3 : in std_logic_vector(31 downto 0);
        config5 : in std_logic_vector(31 downto 0);
        
        ------------ AXI ------------
        axi_read_address_o : out std_logic_vector(31 downto 0);  
		axi_read_init_o	: out std_logic;
		axi_read_data_i	: in std_logic_vector(cache_width - 1 downto 0); 
		axi_read_valid_i : in std_logic;
		axi_read_last_i : in std_logic;          
		axi_read_rdy_o  : out std_logic;
        
        start_processing_o : out std_logic;
        comp5_o : out std_logic
        
    );
end Cache_Top;

architecture Behavioral of Cache_Top is

----------- components -----------

component RF_for_write is
  generic(
       RF_size : natural := 15;
       addr_width : natural := 4);
  Port(
       --------------- Clocking and reset interface ---------------
       clk_i : in std_logic;
       rst_i : in std_logic;
       
       --------------- Input interface ---------------
       empty_line_i : std_logic;
       en_i : in std_logic;
       write_i : in std_logic;
       wdata_i : in std_logic;
       
       --------------- Output interface ---------------
       rdata_o : out std_logic;
       wcounter_o : out std_logic_vector(addr_width - 1 downto 0)
       
       );
end component;

component Dual_Port_BRAM is
    generic(
         width      : natural := 64;
         addr_width : natural := 10; 
         size       : natural := 576);
    Port(
         --------------- Clocking and reset interface ---------------
         clk_i : in std_logic;
         
         ------------------- Input data interface -------------------
         --write0_i : in std_logic;
         --wdata0_i : in std_logic_vector(width - 1 downto 0);
         addr0_i  : in std_logic_vector(addr_width - 1 downto 0);
         
         write1_i : in std_logic;
         wdata1_i : in std_logic_vector(width - 1 downto 0);
         addr1_i  : in std_logic_vector(addr_width - 1 downto 0);
         
         ------------------- Output data interface -------------------
         rdata0_o : out std_logic_vector(width - 1 downto 0);
         rdata1_o : out std_logic_vector(width - 1 downto 0)
      
         
         );
end component;

component Write_Ctrl is
    generic(
            data_width : natural := 64;
            RF_addr_width : natural := 4;
            cache_addr_width : natural := 8;
            dim_width : natural := 9;
            total_dim_width : natural := 18;
            
            -- ADDER
            g_WIDTH : natural := 32
            );
    Port(
         --------------- Clocking and reset interface ---------------
         clk_i : in std_logic;
         rst_i : in std_logic;
         
         --------------- AXI master read interface ---------------
        axi_read_address_o : out std_logic_vector(31 downto 0);  
		axi_read_init_o	: out std_logic;                         
		axi_read_data_i	: in std_logic_vector(data_width - 1 downto 0);    
		axi_read_next_i : in std_logic; -- Umesto next dodati valid
		axi_read_last_i : in std_logic;                        
		axi_read_rdy_o: out std_logic;
        
        --------------- Register File interface ---------------
        en_o : out std_logic;
        write_o : out std_logic;
        wdata_o : out std_logic;
        rdata_i : in std_logic;
        wcounter_i : in std_logic_vector(RF_addr_width - 1 downto 0);
        
        --------------- Cache Memory interface ---------------		
		cache_addr_o : out std_logic_vector(cache_addr_width - 1 downto 0);
		cache_data_o : out std_logic_vector(data_width - 1 downto 0);
		cache_write_o : out std_logic;
		
		--------------- Configuration Registers interface ---------------
        config3 : in std_logic_vector(31 downto 0);
--        start_i : in std_logic;
--        height_i : in std_logic_vector(dim_width - 1 downto 0);
--        total_i : in std_logic_vector(total_dim_width - 1 downto 0); -- visina x sirina = ukupno piksela
        
        --------------- Write interface of the Register File ---------------
        write_RF_o : out std_logic;
        waddress_RF_o : out std_logic_vector(RF_addr_width - 1 downto 0);
        wdata_RF_o : out std_logic_vector(1 downto 0);
        
        --------------- Output signal ---------------
        start_processing_o : out std_logic;
        comp5_o : out std_logic
         
         );
end component;

component Cache_read_control_unit is
    generic(
            col_width : natural := 9;
            i_width : natural := 10;
            addr_width : natural := 8;
            cache_line_count : natural := 15;
            kernel_size : natural := 9;
            RF_addr_width : natural := 4;
            cache_width : natural := 64;
            data_width : natural := 12
            );
    Port(
         --------------- Clocking and reset interface ---------------
         clk_i : in std_logic;
         rst_i : in std_logic;
         
         --------------- Input interface ---------------
         req_i : in std_logic;
         end_i : in std_logic;
         start_i : in std_logic;
         --output_width_i : in std_logic_vector(col_width - 1 downto 0);
         
         --------------- Config registers --------------- 
         config5 : in std_logic_vector(31 downto 0);
         
         --------------- Write interface of the Register File ---------------
         write_RF_i : in std_logic;
         waddress_RF_i : in std_logic_vector(RF_addr_width - 1 downto 0);
         wdata_RF_i : in std_logic_vector(1 downto 0);
         
         --------------- Input from Cache Memory ---------------
         cache_data_i : in std_logic_vector(cache_width - 1 downto 0);
         
         --------------- Output interface ---------------
         empty_line_o : out std_logic;
         -- load_num_o : out std_logic_vector(1 downto 0);
         d_valid_o : out std_logic;
         -- cache_line_o : out std_logic_vector(addr_width - 1 downto 0);
         
         --------------- Address for Cache Memory ---------------
         raddress_cache_o : out std_logic_vector(addr_width - 1 downto 0);
         
         --------------- Data output ---------------
         cache_data_o : out std_logic_vector(data_width - 1 downto 0)
         );
end component;

----------------------------------


-- read
signal reg_s, end_s, write_RF_s, ready_s, empty_line_s, d_valid_s : std_logic;
signal output_width_s : std_logic_vector(col_width - 1 downto 0);
signal waddress_RF_s : std_logic_vector(RF_addr_width - 1 downto 0);
signal wdata_RF_s, load_num_s : std_logic_vector(1 downto 0);
signal cache_data_i_s, cache_data_o_s : std_logic_vector(cache_width - 1 downto 0);
signal cache_line_s : std_logic_vector(addr_width - 1 downto 0);
signal raddress_cache_s : std_logic_vector(addr_width - 1 downto 0);


signal en_s, write_s, wdata_s, rdata_s : std_logic;
signal wcounter_s : std_logic_vector(RF_addr_width - 1 downto 0);

signal cache_addr_s : std_logic_vector(addr_width - 1 downto 0);
signal cache_data_s : std_logic_vector(cache_width - 1 downto 0);
signal cache_write_s : std_logic;

signal start_processing_s : std_logic;
signal comp5_s : std_logic;

-- BRAM
signal write0_s :std_logic;
signal wdata0_s : std_logic_vector(cache_width - 1 downto 0);
signal addr0_s : std_logic_vector(addr_width - 1 downto 0);
signal write1_s :std_logic;
signal wdata1_s : std_logic_vector(cache_width - 1 downto 0);
signal addr1_s : std_logic_vector(addr_width - 1 downto 0);
signal rdata0_s : std_logic_vector(cache_width - 1 downto 0);
signal rdata1_s : std_logic_vector(cache_width - 1 downto 0);

begin

Cache_Read: Cache_read_control_unit
    generic map(
        col_width => col_width,
        i_width => i_width,
        addr_width => addr_width, 
        cache_line_count => cache_line_count,
        kernel_size => kernel_size,
        RF_addr_width => RF_addr_width, 
        cache_width => cache_width,
        data_width => Read_data_width
    )
    port map(
         --------------- Clocking and reset interface ---------------
         clk_i => clk_i,
         rst_i => rst_i,
         --------------- Input interface ---------------
         req_i => reg_i,                                 --  PB
         end_i => end_i,                                 -- PB
         start_i => start_processing_s,
         config5 => config5,
         --------------- Write interface of the Register File ---------------
         write_RF_i => write_RF_s,
         waddress_RF_i => waddress_RF_s,
         wdata_RF_i => wdata_RF_s,
         --------------- Input from Cache Memory ---------------
         cache_data_i => cache_data_i_s,  
         --------------- Output interface ---------------
         empty_line_o => empty_line_s,
         d_valid_o => d_valid_o,                        -- PB
         --------------- Address for Cache Memory ---------------
         raddress_cache_o => raddress_cache_s,
         --------------- Data output ---------------    
         cache_data_o => cache_data_o                 -- PB
    );
    
Cache_Write: Write_Ctrl
    generic map(
        data_width => cache_width,
        RF_addr_width => RF_addr_width,
        cache_addr_width => addr_width,
        dim_width => col_width,
        total_dim_width => 2 * col_width
    )
    port map(
        --------------- Clocking and reset interface ---------------
        clk_i => clk_i,
        rst_i => rst_i,
        --------------- AXI master read interface ---------------
        axi_read_address_o => axi_read_address_o,  
		axi_read_init_o	=> axi_read_init_o,        
		axi_read_data_i	=> axi_read_data_i,        
		axi_read_next_i => axi_read_valid_i,        
		axi_read_last_i => axi_read_last_i,        
		axi_read_rdy_o => axi_read_rdy_o,             
        --------------- Register File interface ---------------
        en_o => en_s,
        write_o => write_s,
        wdata_o => wdata_s,
        rdata_i => rdata_s,
        wcounter_i => wcounter_s,
        --------------- Cache Memory interface ---------------		
		cache_addr_o => cache_addr_s,
		cache_data_o => cache_data_s,
		cache_write_o => cache_write_s,		
		--------------- Configuration Registers interface ---------------
        config3 => config3,
        --------------- Amount Hash Interface ---------------
        write_RF_o => write_RF_s,
        waddress_RF_o => waddress_RF_s,
        wdata_RF_o => wdata_RF_s,
        --------------- Output signal ---------------
        start_processing_o => start_processing_s,
        comp5_o => comp5_s
    );
    
DualPortBRAM: Dual_Port_BRAM
    generic map(
        width      => cache_width,
        addr_width => addr_width,
        size       => size    
    )
    port map(
         --------------- Clocking and reset interface ---------------
         clk_i => clk_i,         
         ------------------- Input data interface -------------------
         -- READ
         addr0_i  => raddress_cache_s,
         
         -- WRITE
         write1_i => cache_write_s,
         wdata1_i => cache_data_s,
         addr1_i  => cache_addr_s,       
         ------------------- Output data interface -------------------
         -- READ
         rdata0_o => cache_data_i_s,
         -- WRITE
         rdata1_o => open
    );
    
Register_File: RF_for_write
    generic map(
       RF_size => cache_line_count, 
       addr_width => RF_addr_width 
    )
    port map(
       --------------- Clocking and reset interface ---------------
       clk_i => clk_i,
       rst_i => rst_i,
       --------------- Input interface ---------------
       empty_line_i => empty_line_s,
       en_i => en_s,
       write_i => write_s,
       wdata_i =>wdata_s,
       --------------- Output interface ---------------
       rdata_o => rdata_s,
       wcounter_o => wcounter_s
    );    

start_processing_o <= start_processing_s;
comp5_o <= comp5_s;

end Behavioral;
