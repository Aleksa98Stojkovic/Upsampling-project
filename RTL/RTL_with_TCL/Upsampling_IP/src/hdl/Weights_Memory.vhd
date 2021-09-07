----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.07.2021 22:56:34
-- Design Name: 
-- Module Name: Weights_Memory - Behavioral
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

entity Weights_Memory is
    Generic(
        BRAM_count : natural := 16;  
        width      : natural := 64;
        addr_width : natural := 10; 
        size       : natural := 9*64
    );
    Port (
        --------------- Clocking and reset interface ---------------
        clk_i : in std_logic;
        
        ------------------- Write interface -------------------
        wdata_i : in std_logic_vector(width - 1 downto 0);
        write_en_i : in std_logic_vector(BRAM_count - 1 downto 0);
        waddr_i : in std_logic_vector(addr_width - 1 downto 0);
        
        ------------------- Read interface -------------------
        rdata_o : out std_logic_vector(BRAM_count * width - 1 downto 0);
        raddr_i : in std_logic_vector(addr_width - 1 downto 0)
    
     );
end Weights_Memory;

architecture Behavioral of Weights_Memory is

component Dual_Port_BRAM is
    generic(
         width      : natural := 64;
         addr_width : natural := 10; 
         size       : natural := 576);
    Port(
         --------------- Clocking and reset interface ---------------
         clk_i : in std_logic;
         
         ------------------- Input data interface -------------------
         addr0_i  : in std_logic_vector(addr_width - 1 downto 0);
         
         write1_i : in std_logic;
         wdata1_i : in std_logic_vector(width - 1 downto 0);
         addr1_i  : in std_logic_vector(addr_width - 1 downto 0);
         
         ------------------- Output data interface -------------------
         rdata0_o : out std_logic_vector(width - 1 downto 0);
         rdata1_o : out std_logic_vector(width - 1 downto 0)
      
         
         );
end component;


begin

Gen_Mem: for i in 1 to BRAM_count generate
    MemX : Dual_Port_BRAM 
    generic map(
        width      => width,
        addr_width => addr_width,
        size       => size
    )
    port map
        (
            clk_i    => clk_i,
            addr0_i  => raddr_i,
         
            write1_i => write_en_i(i - 1),
            wdata1_i => wdata_i,
            addr1_i  => waddr_i,
             
            rdata0_o => rdata_o(i * width - 1 downto (i - 1) * width),
            rdata1_o => open
        );
    end generate Gen_Mem;



end Behavioral;
