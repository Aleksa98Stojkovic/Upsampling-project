----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/30/2021 11:20:54 PM
-- Design Name: 
-- Module Name: AXI_router - Behavioral
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

entity AXI_router is
    generic(
            DATA_WIDTH       : integer := 64;
            READ_MEM_ADDR    : integer := 32 
            );
    Port(
        ------------------- AXI WMEM Read interface -------------------
		axi0_read_init_i        : in std_logic;
        axi0_read_data_o        : out std_logic_vector(DATA_WIDTH-1 downto 0);
        axi0_read_addr_i        : in std_logic_vector(READ_MEM_ADDR-1 downto 0);
        axi0_read_last_o        : out std_logic;  
        axi0_read_valid_o       : out std_logic;  
        axi0_read_ready_i       : in std_logic;
        
        ------------------- AXI Cache Read interface -------------------
		axi1_read_init_i        : in std_logic;
        axi1_read_data_o        : out std_logic_vector(DATA_WIDTH-1 downto 0);
        axi1_read_addr_i        : in std_logic_vector(READ_MEM_ADDR-1 downto 0);
        axi1_read_last_o        : out std_logic;  
        axi1_read_valid_o       : out std_logic;  
        axi1_read_ready_i       : in std_logic;
        
        ------------------- Config register -------------------
        config3 : in std_logic_vector(31 downto 0);
        --sel_axi_module_i : in std_logic; -- 0 = axi0, 1 = axi1
        
        ------------------- AXI Read interface -------------------
        axi_read_init_o        : out std_logic;
        axi_read_data_i        : in std_logic_vector(DATA_WIDTH-1 downto 0);
        axi_read_addr_o        : out std_logic_vector(READ_MEM_ADDR-1 downto 0);
        axi_read_last_i        : in std_logic;  
        axi_read_valid_i       : in std_logic;  
        axi_read_ready_o       : out std_logic
        );
        
end AXI_router;

architecture Behavioral of AXI_router is

signal sel_axi_module_i : std_logic; -- 0 = axi0, 1 = axi1

begin

sel_axi_module_i <= config3(0);

Router: process(sel_axi_module_i, axi1_read_init_i, axi1_read_addr_i, axi1_read_ready_i,
                axi0_read_init_i, axi0_read_addr_i, axi0_read_ready_i, axi_read_data_i, axi_read_last_i, axi_read_valid_i) is 
begin

    if(sel_axi_module_i = '1') then
    
        axi_read_init_o <= axi1_read_init_i;
        axi_read_addr_o <= axi1_read_addr_i;
        axi_read_ready_o <= axi1_read_ready_i;
        
        axi0_read_data_o <= (others => '0');
        axi0_read_last_o <= '0';
        axi0_read_valid_o <= '0';
        
        axi1_read_data_o <= axi_read_data_i;
        axi1_read_last_o <= axi_read_last_i;
        axi1_read_valid_o <= axi_read_valid_i;
        
    else
    
        axi_read_init_o <= axi0_read_init_i;
        axi_read_addr_o <= axi0_read_addr_i;
        axi_read_ready_o <= axi0_read_ready_i;
        
        axi1_read_data_o <= (others => '0');
        axi1_read_last_o <= '0';
        axi1_read_valid_o <= '0';
        
        axi0_read_data_o <= axi_read_data_i;
        axi0_read_last_o <= axi_read_last_i;
        axi0_read_valid_o <= axi_read_valid_i;
    
    end if;

end process;

end Behavioral;
