----------------------------------------------------------------------------------
-- Company: FTN
-- Engineer: Aleksa Stojkovic
-- 
-- Create Date: 07/10/2021 04:42:47 PM
-- Design Name: 
-- Module Name: Cache_line_register - Behavioral
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

entity Cache_line_register is
    Generic(
            DATA_WIDTH : natural := 8;
            N_in_up    : natural := 15;
            N_in_down  : natural := 9
            );
    Port(
         --------------- Clocking and reset interface ---------------
        clk_i : in std_logic;
        rst_i : in std_logic;
        ------------------- Input data interface -------------------
        shift_up_i      : in std_logic;
        shift_down_i    : in std_logic;
        write_en_up_i   : in std_logic;
        write_en_down_i : in std_logic;
        data_i          : in std_logic_vector(N_in_up * DATA_WIDTH - 1 downto 0);
        ------------------- Output data interface -------------------
        data_s_o   : out std_logic_vector(DATA_WIDTH - 1 downto 0) 
         );
end Cache_line_register;

architecture Behavioral of Cache_line_register is

signal feedback : std_logic_vector(data_width - 1 downto 0);
signal data : std_logic_vector(N_in_down * data_width - 1 downto 0);

begin

PISO_up : entity work.PISO_up(Behavioral)
generic map(data_width => data_width, N_in => N_in_up, N_out => N_in_down)
port map(
         clk_i      => clk_i,
         rst_i      => rst_i,
         write_en_i => write_en_up_i,
         shift_i    => shift_up_i,
         data_i     => data_i,
         data_s_i   => feedback,
         data_s_o   => feedback,
         data_o     => data
         ); 

PISO_down : entity work.PISO_down(Behavioral)
generic map(data_width => data_width, N_in => N_in_down)
port map(
         clk_i      => clk_i,
         rst_i      => rst_i,
         write_en_i => write_en_down_i,
         shift_i    => shift_down_i,
         data_i     => data,
         data_s_i   => (others => '0'),
         data_s_o   => data_s_o
         );

end Behavioral;
