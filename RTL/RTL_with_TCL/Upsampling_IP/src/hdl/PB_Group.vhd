----------------------------------------------------------------------------------
-- Student: Robert Mezei

-- Description: This file is intended for creating a group of 4 MAC units. 16 of these groups with additional memory components will form 
--              the datapath of the Processing BLock.
-- 
-- Dependencies: MAC.vhd
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PB_Group is
    generic (
            WIDTH_Weight: natural := 16;
            WIDTH_Stick:  natural := 16;
            WIDTH_Data:   natural := 16;
            
            SIGNED_UNSIGNED: string := "signed"
    );
    Port ( 
            en_in:        in std_logic;
            clk:          in std_logic;
            rst_i:       in std_logic;
            weight_in:    in std_logic_vector(4*WIDTH_Weight-1 downto 0); --One group consists of 4 MAC units, therefore we need 4 weights as an input
            data_in:      in std_logic_vector(WIDTH_Data-1 downto 0);
            
            data_out:     out std_logic_vector(4*(WIDTH_Weight+WIDTH_Data) -1 downto 0)
    );
end PB_Group;

architecture Behavioral of PB_Group is

-- signals:
    signal s_clk:       std_logic;
    signal s_en:        std_logic;
    signal s_rst:       std_logic;
    signal s_weight_in: std_logic_vector(4*WIDTH_Weight-1 downto 0);
    signal s_data_in:   std_logic_vector(WIDTH_data-1 downto 0);
    signal s_data_out:  std_logic_vector(4*(WIDTH_Weight+WIDTH_Data) -1 downto 0);
    
-- add component MAC:
    component MAC 
    generic(
        WIDTH_Stick: natural := 16;
        WIDTH_Weight: natural := 16;
        SIGNED_UNSIGNED: string := "signed"
    );
    port(
            en_in:       in std_logic;
            clk:         in std_logic;
            rst_i:       in std_logic;
            stick_in:    in std_logic_vector(WIDTH_Stick-1 downto 0);
            weight_in:   in std_logic_vector(WIDTH_Weight-1 downto 0);
            mul_acc_out: out std_logic_vector(WIDTH_Stick + WIDTH_Weight-1 downto 0)
    );
    end component;

begin

-- instantiate 4 MAC units:
    
    MAC1: MAC 
    generic map(
        WIDTH_Stick => WIDTH_Stick,
        WIDTH_Weight => WIDTH_Weight,
        SIGNED_UNSIGNED => SIGNED_UNSIGNED
    )
    port map
    (
        en_in       => s_en,
        clk         => s_clk,
        rst_i      => s_rst,
        stick_in    => s_data_in,
        weight_in   => s_weight_in(4*WIDTH_Weight-1 downto 3*WIDTH_Weight),
        mul_acc_out => s_data_out(1*(WIDTH_Weight+WIDTH_Data) -1 downto 0)
    );
    
    MAC2: MAC 
    generic map(
        WIDTH_Stick => WIDTH_Stick,
        WIDTH_Weight => WIDTH_Weight,
        SIGNED_UNSIGNED => SIGNED_UNSIGNED
    )
    port map
    (
        en_in       => s_en,
        clk         => s_clk,
        rst_i      => s_rst,
        stick_in    => s_data_in,
        weight_in   => s_weight_in(3*WIDTH_Weight-1 downto 2*WIDTH_Weight),
        mul_acc_out => s_data_out(2*(WIDTH_Weight+WIDTH_Data) -1 downto 1*(WIDTH_Weight+WIDTH_Data))
    );
    
    MAC3: MAC 
    generic map(
        WIDTH_Stick => WIDTH_Stick,
        WIDTH_Weight => WIDTH_Weight,
        SIGNED_UNSIGNED => SIGNED_UNSIGNED
    )
    port map
    (
        en_in       => s_en,
        clk         => s_clk,
        rst_i      => s_rst,
        stick_in    => s_data_in,
        weight_in   => s_weight_in(2*WIDTH_Weight-1 downto 1*WIDTH_Weight),
        mul_acc_out => s_data_out(3*(WIDTH_Weight+WIDTH_Data) -1 downto 2*(WIDTH_Weight+WIDTH_Data))
    );

    MAC4: MAC
    generic map(
        WIDTH_Stick => WIDTH_Stick,
        WIDTH_Weight => WIDTH_Weight,
        SIGNED_UNSIGNED => SIGNED_UNSIGNED
    )
    port map
    (
        en_in       => s_en,
        clk         => s_clk,
        rst_i      => s_rst,
        stick_in    => s_data_in,
        weight_in   => s_weight_in(1*WIDTH_Weight-1 downto 0),
        mul_acc_out => s_data_out(4*(WIDTH_Weight+WIDTH_Data) -1 downto 3*(WIDTH_Weight+WIDTH_Data))
    );
    
-- connecting signals to top-level ports

s_en <= en_in;
s_clk <= clk;
s_rst <= rst_i;
s_weight_in <= weight_in;
s_data_in <= data_in;

data_out <= s_data_out;

end Behavioral;
