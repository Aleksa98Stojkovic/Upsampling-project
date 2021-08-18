----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 29.07.2021 15:01:45
-- Design Name: 
-- Module Name: IP_top - Behavioral
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

entity IP_top is
    Generic(
        -------------------------- WMEM module -------------------------- 
        DATA_WIDTH       : integer := 64; 
        READ_MEM_ADDR    : integer := 32;
        BRAM_ADDR_OFFSET : integer := 512;
        BRAM_count       : natural := 16;  
        wmem_size        : natural := 9*64;
        
        -------------------------- PB module -------------------------- 
        WIDTH           : natural := 10;
        ADDR_WIDTH      : natural := 10;
        WIDTH_Data      : natural := 16;
        SIGNED_UNSIGNED : string  := "signed";
        MAC_width       : natural := 32;
        bias_base_addr_width : natural := 12; 
        bias_size       : natural := 64*38;
        
        -------------------------- Cache module --------------------------
        col_width        : natural := 9;
        i_width          : natural := 10;
        cache_addr_width : natural := 8;
        cache_line_count : natural := 15;
        kernel_size      : natural := 9;
        RF_addr_width    : natural := 4;
        size             : natural := 240
         
    );
    Port(
        ------------------- Clock and Reset interface -------------------
        clk_i : in std_logic;
        rst_i : in std_logic;
        
        ------------------- AXI WMEM Read interface -------------------
		axi0_read_init_o        : out std_logic;
        axi0_read_data_i        : in std_logic_vector(DATA_WIDTH-1 downto 0);
        axi0_read_addr_o        : out std_logic_vector(READ_MEM_ADDR-1 downto 0);
        axi0_read_last_i        : in std_logic;  
        axi0_read_valid_i       : in std_logic;  
        axi0_read_ready_o       : out std_logic;
        
        ------------------- AXI Cache Read interface -------------------
		axi1_read_init_o        : out std_logic;
        axi1_read_data_i        : in std_logic_vector(DATA_WIDTH-1 downto 0);
        axi1_read_addr_o        : out std_logic_vector(READ_MEM_ADDR-1 downto 0);
        axi1_read_last_i        : in std_logic;  
        axi1_read_valid_i       : in std_logic;  
        axi1_read_ready_o       : out std_logic;
        
        ------------------- AXI Write interface -------------------
        axi_write_address_o  : out std_logic_vector(31 downto 0);
		axi_write_init_o	 : out std_logic;       									
		axi_write_data_o	 : out std_logic_vector(63 downto 0);								
		axi_write_next_i     : in std_logic;                                
		axi_write_done_i     : in std_logic;
		
		------------------- Configuration interface -------------------
		config1 : in std_logic_vector(31 downto 0);
		config2 : in std_logic_vector(31 downto 0);
		config3 : in std_logic_vector(31 downto 0);
		config4 : in std_logic_vector(31 downto 0);
		config5 : in std_logic_vector(31 downto 0);
		config6 : out std_logic_vector(31 downto 0)
		
--		start_i           : in std_logic;
--		base_addr_i       : in std_logic_vector(READ_MEM_ADDR - 1 downto 0);
--		done_o            : out std_logic;
--		height_i          : in std_logic_vector(col_width - 1 downto 0);
--        total_i           : in std_logic_vector(2 * col_width - 1 downto 0);
--        write_base_addr_i : in std_logic_vector(31 downto 0);
--		bias_base_addr_i  : in std_logic_vector(bias_base_addr_width - 1 downto 0);
--		output_width_i    : in std_logic_vector(col_width - 1 downto 0);
--		write_start_i     : in std_logic;
--		num_of_pix_i      : in std_logic_vector(2 * col_width - 1 downto 0);
--		done_processing_o : out std_logic
        
    );
end IP_top;

architecture Behavioral of IP_top is

------------------- components ---------------------

component Weights_Memory_top is
    generic 
    (
        DATA_WIDTH  : integer  := 64; 
        WRITE_MEM_ADDR : integer  := 10;
        READ_MEM_ADDR  : integer  := 32;
        MEM_NMB        : integer  := 16;
        BRAM_ADDR_OFFSET : integer := 512;
        
        BRAM_count : natural := 16;  
        size       : natural := 9*64       
    );
    Port( 
         ------------------- Clock and Reset interface -------------------
         clk_i : in std_logic;
         rst_i : in std_logic;
         
         ------------------- PB interface -------------------
        rdata_o : out std_logic_vector(BRAM_count * DATA_WIDTH - 1 downto 0);
        raddr_i : in std_logic_vector(WRITE_MEM_ADDR - 1 downto 0);
        
        ------------------- Configuraton Register interface -------------------
        config1 : in std_logic_vector(31 downto 0);
        config3 : in std_logic_vector(31 downto 0);
        --config6 : out std_logic_vector(31 downto 0);
        done_mem_o : out std_logic;
        
         ------------------- AXI interface -------------------
		axi_read_init_o        : out std_logic;
        axi_read_data_i        : in std_logic_vector(DATA_WIDTH-1 downto 0);
        axi_read_addr_o        : out std_logic_vector(READ_MEM_ADDR-1 downto 0);
        axi_read_last_i        : in std_logic;  
        axi_read_valid_i       : in std_logic;  
        axi_read_ready_o       : out std_logic
        );
        
end component;

component PB_top is
    generic(
        --fsm
        WIDTH1 : natural := 18;
        WIDTH2 : natural := 10;
        ADDR_WIDTH : natural := 10;
        
        --pb unit
        -- WIDTH_Weight: natural := 16;
        -- WIDTH_Stick:  natural := 16;
        WIDTH_Data:   natural := 16;
        SIGNED_UNSIGNED: string := "signed";
        
        --write controller
        MAC_width  : natural := 32;
        MAC_count  : natural := 64;
        bias_base_addr_width : natural := 12; 
        size       : natural := 64*38
    );
    Port (
        clk_i   : in std_logic;
        rst_i   : in std_logic;
        start_i : in std_logic;
        
        -- FSM inputs
        w_valid_i    : in std_logic;
        d_valid_i    : in std_logic;
        --num_of_pix_i : in std_logic_vector(WIDTH1 - 1 downto 0);
        
        -- FSM outputs
        req_o : out std_logic; 
        ready_o : out std_logic;
        weight_addr_o : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
        
        -- PB group inputs
        data_in : in std_logic_vector(WIDTH_Data-1 downto 0);
        weight_in : in std_logic_vector(MAC_count * WIDTH_Data - 1 downto 0);
        
        ------------------- Config registers -------------------
        config2 : in std_logic_vector(31 downto 0);
        config3 : in std_logic_vector(31 downto 0);
        config4 : in std_logic_vector(31 downto 0);
        --config6 : out std_logic_vector(31 downto 0);
        done_o : out std_logic;
        
        ------------------- AXI Write interface -------------------
        axi_write_address_o : out std_logic_vector(31 downto 0);
		axi_write_init_o	 : out std_logic;       									
		axi_write_data_o	 : out std_logic_vector(63 downto 0);								
		axi_write_next_i    : in std_logic;                                
		axi_write_done_i    : in std_logic
		 
		------------------ Result Write controller -----------------
		--write_base_addr_i : in std_logic_vector(31 downto 0);
		--bias_base_addr_i : in std_logic_vector(bias_base_addr_width - 1 downto 0);
		--done_processing_o : out std_logic
        
     );
end component;

component Cache_Top is
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
        
        start_processing_o : out std_logic
        
    );
end component;

----------------------------------------------------


signal rdata_s : std_logic_vector(BRAM_count * DATA_WIDTH - 1 downto 0);
signal raddr_s : std_logic_vector(ADDR_WIDTH - 1 downto 0);

signal d_valid_s : std_logic;
signal total_s : std_logic_vector(2 * col_width - 1 downto 0);
signal req_s : std_logic;
signal ready_s : std_logic;
signal cache_data_s : std_logic_vector(WIDTH_Data - 1 downto 0);

signal start_processing_s : std_logic;

signal done_mem_s, done_proc_s : std_logic;


begin

--####################################################################################
--                               WEIGHTS MEMORY                                        
---------------------------------------------------------------------------------------
WMEM_module: Weights_Memory_top
    generic map(
        DATA_WIDTH  => DATA_WIDTH,
        WRITE_MEM_ADDR => ADDR_WIDTH,
        READ_MEM_ADDR  => READ_MEM_ADDR,
        MEM_NMB        => BRAM_count,
        BRAM_ADDR_OFFSET => BRAM_ADDR_OFFSET,
        BRAM_count => BRAM_count,
        size       => wmem_size
    )
    port map(
        ------------------- Clock and Reset interface -------------------
        clk_i => clk_i,
        rst_i => rst_i,
        ------------------- PB interface -------------------
        rdata_o => rdata_s,
        raddr_i => raddr_s,
        ------------------- Configuraton Register interface -------------------
        config1 => config1,
        config3 => config3,
        --config6 => config6,
        done_mem_o => done_mem_s,
        ------------------- AXI interface -------------------
		axi_read_init_o  => axi0_read_init_o,
        axi_read_data_i  => axi0_read_data_i,
        axi_read_addr_o  => axi0_read_addr_o,
        axi_read_last_i  => axi0_read_last_i,
        axi_read_valid_i => axi0_read_valid_i,
        axi_read_ready_o => axi0_read_ready_o
    );


--####################################################################################
--                               PROCESSING BLOCK                                        
---------------------------------------------------------------------------------------
PB_module: PB_top    
    generic map(
        --fsm
        WIDTH1 => 2 * col_width,
        WIDTH2 => WIDTH,
        ADDR_WIDTH => ADDR_WIDTH,
        --pb unit
        WIDTH_Data => WIDTH_Data,
        SIGNED_UNSIGNED => SIGNED_UNSIGNED,
        --write controller
        MAC_width  => MAC_width,
        MAC_count  => 4 * BRAM_count,
        bias_base_addr_width => bias_base_addr_width,
        size       => bias_size
    )
    port map(
        clk_i   => clk_i,
        rst_i   => rst_i,
        start_i => start_processing_s,
        -- FSM inputs
        w_valid_i    => '1',
        d_valid_i    => d_valid_s,
        -- FSM outputs
        req_o => req_s,
        ready_o => ready_s,
        weight_addr_o => raddr_s,
        -- PB group inputs
        data_in => cache_data_s,
        weight_in => rdata_s,
        ------------------- config registers -------------------
        config2 => config2,
        config3 => config3,
        config4 => config4,
        --config6 => config6,
        done_o => done_proc_s,
        
        ------------------- AXI Write interface -------------------
        axi_write_address_o => axi_write_address_o,
		axi_write_init_o	=> axi_write_init_o,       									
		axi_write_data_o	=> axi_write_data_o,
		axi_write_next_i    => axi_write_next_i,
		axi_write_done_i    => axi_write_done_i
		------------------ Result Write controller -----------------
		--write_base_addr_i => write_base_addr_i,
		--bias_base_addr_i => bias_base_addr_i, 
		--done_processing_o => done_processing_o  
     );
     
     
--####################################################################################
--                                      CACHE                                        
---------------------------------------------------------------------------------------
Cache_module: Cache_Top
    generic map(
        -- Read
        col_width => col_width,
        i_width => i_width,
        addr_width => cache_addr_width,
        cache_line_count => cache_line_count,
        kernel_size => kernel_size,
        RF_addr_width => RF_addr_width,
        cache_width => DATA_WIDTH,
        Read_data_width => WIDTH_Data,
        size => size
        
    )
    port map(
        clk_i => clk_i,
        rst_i => rst_i,
        ------------ PB --------------
        reg_i => req_s,
        end_i => ready_s,
        d_valid_o => d_valid_s,
        cache_data_o => cache_data_s,
        ------------ Config -----------
        config3 => config3,
        config5 => config5,
        ------------ AXI ------------
        axi_read_address_o => axi1_read_addr_o, 
		axi_read_init_o	=> axi1_read_init_o,
		axi_read_data_i	=> axi1_read_data_i,
		axi_read_valid_i => axi1_read_valid_i,
		axi_read_last_i => axi1_read_last_i,           
		axi_read_rdy_o  => axi1_read_ready_o,
        
        start_processing_o => start_processing_s
    );

config6(0) <= done_mem_s;
config6(1) <= done_proc_s;
config6(31 downto 2) <= (others => '0');



end Behavioral;
