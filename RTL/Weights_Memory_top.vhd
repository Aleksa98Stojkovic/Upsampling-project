----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/29/2021 01:03:23 AM
-- Design Name: 
-- Module Name: Weights_Memory_top - Behavioral
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

entity Weights_Memory_top is
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
        
end Weights_Memory_top;

architecture Behavioral of Weights_Memory_top is

signal waddr_s : std_logic_vector(WRITE_MEM_ADDR - 1 downto 0);
signal data_s : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal we_s : std_logic_vector(BRAM_count - 1 downto 0);

begin

Mem_Ctrl: entity work.Weights_Mem_Controler(Behavioral)
generic map(
        DATA_IN_WIDTH  => DATA_WIDTH,
        DATA_OUT_WIDTH => DATA_WIDTH,
        WRITE_MEM_ADDR => WRITE_MEM_ADDR,
        READ_MEM_ADDR  => READ_MEM_ADDR,
        MEM_NMB        => MEM_NMB,
        BRAM_ADDR_OFFSET => BRAM_ADDR_OFFSET   
)
port map(
        clk_i => clk_i,
        rst_i => rst_i,
        config1 => config1,
        config3 => config3, 
        --config6 => config6,
        done_mem_o => done_mem_o,    
        waddr_o => waddr_s, 
        data_o => data_s, 
        we_o => we_s, 
		axi_read_init_o => axi_read_init_o,
        axi_read_data_i => axi_read_data_i,
        axi_read_addr_o => axi_read_addr_o,
        axi_read_last_i => axi_read_last_i,
        axi_read_valid_i => axi_read_valid_i,
        axi_read_ready_o => axi_read_ready_o
);


Mem: entity work.Weights_Memory(Behavioral)
generic map(
        BRAM_count => BRAM_count,  
        width => DATA_WIDTH,
        addr_width => WRITE_MEM_ADDR,
        size => size
)
port map(
        clk_i => clk_i,
        wdata_i => data_s,
        write_en_i => we_s,
        waddr_i => waddr_s,
        rdata_o => rdata_o,
        raddr_i => raddr_i
);

end Behavioral;
