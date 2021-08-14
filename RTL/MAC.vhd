----------------------------------------------------------------------------------
-- Student: Robert Mezei EE16/2017
-- Description: This code generates a multiply-accumulate module using a DSP 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MAC is
    generic(
        WIDTH_Stick: natural := 16;
        WIDTH_Weight: natural := 16;
        SIGNED_UNSIGNED: string := "signed"
    );
    Port (
        rst_i: in std_logic;
        en_in: in std_logic;
        clk: in std_logic;
        stick_in: in std_logic_vector(WIDTH_Stick-1 downto 0);
        weight_in: in std_logic_vector(WIDTH_Weight-1 downto 0);
        mul_acc_out: out std_logic_vector(WIDTH_Stick + WIDTH_Weight-1 downto 0)    --multiply accumulate 
    );
end MAC;

architecture Behavioral of MAC is
--attributes needed for Vivado to map code to DPS cells:
    attribute use_dsp: string;
    attribute use_dsp of Behavioral: architecture is "yes";
    
--pipeline registers:
    signal stick_reg, stick_next: std_logic_vector(WIDTH_Stick-1 downto 0);
    signal weight_reg, weight_next: std_logic_vector(WIDTH_Weight-1 downto 0);
    signal multiply_reg, multiply_next: std_logic_vector(WIDTH_Stick+WIDTH_Weight-1 downto 0);
    signal accumulate_reg, accumulate_next: std_logic_vector(WIDTH_Stick+WIDTH_Weight-1 downto 0);

begin

stick_next <= stick_in;         
weight_next <= weight_in;

--combinatorial part:
    process (stick_reg, weight_reg, multiply_reg, accumulate_reg)
    begin
        if (SIGNED_UNSIGNED = "unsigned") then
            multiply_next <= std_logic_vector( unsigned(stick_reg) * unsigned(weight_reg) );
            accumulate_next <= std_logic_vector( unsigned(multiply_reg) + unsigned(accumulate_reg));
        else
            multiply_next <= std_logic_vector( signed(stick_reg) * signed(weight_reg) );
            accumulate_next <= std_logic_vector( signed(multiply_reg) + signed(accumulate_reg) );
        end if;
    end process;
       
--sequential part:
    process (clk) 
    begin
        if (rising_edge(clk)) then
        
            if(rst_i = '1') then
                stick_reg <= (others => '0');
                weight_reg <= (others => '0');
                multiply_reg <= (others => '0');
                accumulate_reg <= (others => '0');
            else
                if(en_in = '1') then
                    stick_reg <= stick_next;
                    weight_reg <= weight_next;
                end if;
            
                multiply_reg <= multiply_next;
                accumulate_reg <= accumulate_next;
            end if;
           
        end if;     
    end process;
--dsp output:
    mul_acc_out <= accumulate_reg;
end Behavioral;
