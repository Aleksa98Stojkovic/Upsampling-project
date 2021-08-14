----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/31/2021 06:03:24 PM
-- Design Name: 
-- Module Name: IP_with_router_top - Behavioral
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

entity IP_with_router_top is
    generic(
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
    
		------------------- Configuration interface -------------------
		config1 : in std_logic_vector(31 downto 0);
		config2 : in std_logic_vector(31 downto 0);
		config3 : in std_logic_vector(31 downto 0);
		config4 : in std_logic_vector(31 downto 0);
		config5 : in std_logic_vector(31 downto 0);
		config6 : out std_logic_vector(31 downto 0);
        
        ------------------- AXI Write interface -------------------
        axi_write_address_o  : out std_logic_vector(READ_MEM_ADDR - 1 downto 0);
		axi_write_init_o	 : out std_logic;       									
		axi_write_data_o	 : out std_logic_vector(DATA_WIDTH - 1 downto 0);								
		axi_write_next_i     : in std_logic;                                
		axi_write_done_i     : in std_logic;
            
        ------------------- AXI Read interface -------------------
        axi_read_init_o        : out std_logic;
        axi_read_data_i        : in std_logic_vector(DATA_WIDTH-1 downto 0);
        axi_read_addr_o        : out std_logic_vector(READ_MEM_ADDR-1 downto 0);
        axi_read_last_i        : in std_logic;  
        axi_read_valid_i       : in std_logic;  
        axi_read_ready_o       : out std_logic
        
        -- DEBUG
       -- debugDiode : out std_logic
        
        );
        
end IP_with_router_top;

architecture Behavioral of IP_with_router_top is

signal axi0_read_init_s, axi1_read_init_s : std_logic;
signal axi0_read_data_s, axi1_read_data_s : std_logic_vector(DATA_WIDTH-1 downto 0);
signal axi0_read_addr_s, axi1_read_addr_s : std_logic_vector(READ_MEM_ADDR-1 downto 0);
signal axi0_read_last_s, axi1_read_last_s : std_logic;  
signal axi0_read_valid_s, axi1_read_valid_s : std_logic;  
signal axi0_read_ready_s, axi1_read_ready_s : std_logic;

signal axi_write_address_s : std_logic_vector(READ_MEM_ADDR - 1 downto 0);
signal axi_write_init_s : std_logic;       									
signal axi_write_data_s : std_logic_vector(DATA_WIDTH - 1 downto 0);								
signal axi_write_next_s : std_logic;                                
signal axi_write_done_s : std_logic;

signal start_s : std_logic;
signal base_addr_s : std_logic_vector(READ_MEM_ADDR - 1 downto 0);
signal done_s : std_logic;
signal height_s : std_logic_vector(col_width - 1 downto 0);
signal total_s : std_logic_vector(2 * col_width - 1 downto 0);
signal write_base_addr_s : std_logic_vector(31 downto 0);
signal bias_base_addr_s : std_logic_vector(bias_base_addr_width - 1 downto 0);
signal output_width_s : std_logic_vector(col_width - 1 downto 0);
signal write_start_s : std_logic;
signal num_of_pix_s : std_logic_vector(2 * col_width - 1 downto 0);
signal sel_axi_module_s : std_logic;

------------DEBUG
--signal dbg_diode_s : std_logic := '0';

begin

axi_write_address_o <= axi_write_address_s;
axi_write_init_o <= axi_write_init_s;     									
axi_write_data_o <= axi_write_data_s;								
axi_write_next_s <= axi_write_next_i;                                
axi_write_done_s <= axi_write_done_i;

IP: entity work.IP_top(Behavioral)
generic map(
        -------------------------- WMEM module -------------------------- 
        DATA_WIDTH => DATA_WIDTH, 
        READ_MEM_ADDR => READ_MEM_ADDR,
        BRAM_ADDR_OFFSET => BRAM_ADDR_OFFSET,
        BRAM_count => BRAM_count,
        wmem_size => wmem_size,
        
        -------------------------- PB module -------------------------- 
        WIDTH => WIDTH,
        ADDR_WIDTH => ADDR_WIDTH,
        WIDTH_Data => WIDTH_Data,
        SIGNED_UNSIGNED => SIGNED_UNSIGNED,
        MAC_width => MAC_width,
        bias_base_addr_width => bias_base_addr_width, 
        bias_size => bias_size,
        
        -------------------------- Cache module --------------------------
        col_width => col_width, 
        i_width => i_width,
        cache_addr_width => cache_addr_width,
        cache_line_count => cache_line_count,
        kernel_size => kernel_size,
        RF_addr_width => RF_addr_width,
        size => size
)
port map(
        ------------------- Clock and Reset interface -------------------
        clk_i => clk_i,
        rst_i => rst_i,
        
        ------------------- AXI WMEM Read interface -------------------
		axi0_read_init_o => axi0_read_init_s,
        axi0_read_data_i => axi0_read_data_s,
        axi0_read_addr_o => axi0_read_addr_s,
        axi0_read_last_i => axi0_read_last_s, 
        axi0_read_valid_i => axi0_read_valid_s, 
        axi0_read_ready_o => axi0_read_ready_s,
        
        ------------------- AXI Cache Read interface -------------------
		axi1_read_init_o => axi1_read_init_s,
        axi1_read_data_i => axi1_read_data_s,
        axi1_read_addr_o => axi1_read_addr_s,
        axi1_read_last_i => axi1_read_last_s, 
        axi1_read_valid_i => axi1_read_valid_s,
        axi1_read_ready_o => axi1_read_ready_s,
        
        ------------------- AXI Write interface -------------------
        axi_write_address_o => axi_write_address_s,
		axi_write_init_o => axi_write_init_s,       									
		axi_write_data_o => axi_write_data_s,								
		axi_write_next_i => axi_write_next_s,                                
		axi_write_done_i => axi_write_done_s,
		
		------------------- Configuration interface -------------------
		config1 => config1,
		config2 => config2,
		config3 => config3,
		config4 => config4,
		config5 => config5,
		config6 => config6
);


Router: entity work.AXI_router(Behavioral)
generic map(
            DATA_WIDTH => DATA_WIDTH,
            READ_MEM_ADDR => READ_MEM_ADDR         
            )
port map(
        ------------------- AXI WMEM Read interface -------------------
		axi0_read_init_i => axi0_read_init_s,
        axi0_read_data_o => axi0_read_data_s,
        axi0_read_addr_i => axi0_read_addr_s,
        axi0_read_last_o => axi0_read_last_s,  
        axi0_read_valid_o => axi0_read_valid_s, 
        axi0_read_ready_i => axi0_read_ready_s,
        
        ------------------- AXI Cache Read interface -------------------
		axi1_read_init_i => axi1_read_init_s,
        axi1_read_data_o => axi1_read_data_s,
        axi1_read_addr_i => axi1_read_addr_s,
        axi1_read_last_o => axi1_read_last_s, 
        axi1_read_valid_o => axi1_read_valid_s,  
        axi1_read_ready_i => axi1_read_ready_s,
        
        ------------------- Config register -------------------
        config3 => config3,
        --sel_axi_module_i => sel_axi_module_i,
        
        ------------------- AXI Read interface -------------------
        axi_read_init_o => axi_read_init_o,
        axi_read_data_i => axi_read_data_i,
        axi_read_addr_o => axi_read_addr_o,
        axi_read_last_i => axi_read_last_i,  
        axi_read_valid_i => axi_read_valid_i,  
        axi_read_ready_o => axi_read_ready_o
);


--------------------------- DEBUG
--debug_process : process(clk_i) is
--begin
--    if(rising_edge(clk_i)) then
--        dbg_diode_s <= '1';
--    end if;

--end process;
--debugDiode <= dbg_diode_s;


end Behavioral;
