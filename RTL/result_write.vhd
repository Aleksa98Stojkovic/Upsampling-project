----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.07.2021 18:01:45
-- Design Name: 
-- Module Name: result_write - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity result_write is
    Generic(
        MAC_width  : natural := 32;
        MAC_count  : natural := 64;
        -- width      : natural := 24;
        addr_width : natural := 12; 
        size       : natural := 37*64
    );
    Port (
         --------------- Clocking and reset interface ---------------
         clk_i : in std_logic;
         rst_i : in std_logic;
         start_i : in std_logic;
         
         ------------------- PB interface -------------------
         PB_data_i : in std_logic_vector(MAC_count * MAC_width - 1 downto 0);
         PB_done_i : in std_logic;
         PB_ready_i : in std_logic; -- kad PB zavrsi
         
         ------------------- AXI Write interface -------------------
         axi_write_address_o : out std_logic_vector(31 downto 0);
		 axi_write_init_o	 : out std_logic;       									
		 axi_write_data_o	 : out std_logic_vector(63 downto 0);								
		 axi_write_next_i    : in std_logic;                                
		 axi_write_done_i    : in std_logic;
		                       
		 ------------------- Configuration Registers Interface -------------------
		 config2 : in std_logic_vector(31 downto 0); 
		 config3 : in std_logic_vector(31 downto 0);
		 config4 : in std_logic_vector(31 downto 0);
		 --config6 : out std_logic_vector(31 downto 0)
		 done_o : out std_logic
--		 write_base_addr_i : in std_logic_vector(31 downto 0);           -- bazna adresa za upis rezultata
--		 bias_base_addr_i : in std_logic_vector(addr_width - 1 downto 0); -- bazna adresa za bias u ovom sloju
--		 done_processing_o : out std_logic
		 
     );
end result_write;

architecture Behavioral of result_write is

type reg_group is array(0 to MAC_count - 1) of std_logic_vector(MAC_width - 1 downto 0);
signal group_reg, group_next : reg_group;

type states is (idle, wait_done, write_group, bias, relu, axi_write);
signal current_state, next_state : states;

signal addr_reg, addr_next : std_logic_vector(addr_width - 1 downto 0);
signal rdata_s : std_logic_vector(MAC_width - 1 downto 0);
-- AXI signals
signal axi_write_address_reg, axi_write_address_next : std_logic_vector(31 downto 0);
signal axi_write_data_reg, axi_write_data_next: std_logic_vector(63 downto 0);

-- Adder --
signal add_bias, add_in1, add_in2 : std_logic_vector(MAC_width - 1 downto 0);

-- Counter --
signal counter_64 : std_logic_vector(5 downto 0) := (others => '0');
signal en_64: std_logic;

-- Constants
constant zeros : std_logic_vector(63 - MAC_width downto 0) := (others => '0');

-- Config signals
signal write_base_addr_i : std_logic_vector(31 downto 0);           -- bazna adresa za upis rezultata
signal bias_base_addr_i : std_logic_vector(addr_width - 1 downto 0); -- bazna adresa za bias u ovom sloju
signal done_processing_o : std_logic;

signal done_next, done_reg : std_logic;
signal done_rst_ff, done_rst_ff2, done_rst_pulse : std_logic;


begin

------------------------------ Assigments ------------------------------ 

axi_write_address_o <= axi_write_address_reg;
axi_write_data_o <= axi_write_data_reg;
add_in1 <= rdata_s;

write_base_addr_i <= config2;
bias_base_addr_i <= config4(11 downto 0);
--config6(1) <= done_processing_o;
done_o <= done_processing_o;
done_processing_o <= done_reg;

------------------------------ ROM ------------------------------ 

ROM : entity work.bias_ROM(Behavioral)                     
        generic map(
            width      => MAC_width,
            addr_width => addr_width,
            size       => size
        )
        port map(
            --------------- Clocking and reset interface ---------------
            clk_i => clk_i,
            ------------------- Input data interface -------------------
            addr_i => addr_reg,
            ------------------- Output data interface -------------------
            rdata_o => rdata_s
        );

------------------------------ Creating done_rst_pulse ------------------------------ 
pulse_gen: process(clk_i) is
begin

    if(rising_edge(clk_i)) then
    
        done_rst_ff <= config3(4);
        done_rst_ff2 <= done_rst_ff;
    
    end if;

end process;

done_rst_pulse <= done_rst_ff and (not done_rst_ff2);



------------------------------ Registers ------------------------------ 

registers: process(clk_i) is
begin
    if(rising_edge(clk_i)) then
        
        if(rst_i = '1') then
            group_reg <= (others => (others => '0'));
            axi_write_address_reg <= (others => '0');
            axi_write_data_reg <= (others => '0');
            addr_reg <= (others => '0');
            done_reg <= '0';
        else
            group_reg <= group_next;
            axi_write_address_reg <= axi_write_address_next; 
            axi_write_data_reg <= axi_write_data_next;  
            addr_reg <= addr_next;
            done_reg <= done_next;
        end if;
    end if;

end process;

------------------------------ Counter ------------------------------ 

counter: process(clk_i) is 
begin
    
    if(rising_edge(clk_i)) then
        
        if(rst_i = '1') then
            counter_64 <= (others => '0');
        else
            counter_64 <= counter_64;
            
            if(en_64 = '1') then
                counter_64 <= std_logic_vector(unsigned(counter_64) + to_unsigned(1, 6));
            end if;
        
        end if;
        
    end if;

end process;


------------------------------ Adder for bias ------------------------------ 
add_bias <= std_logic_vector(signed(add_in1) + signed(add_in2));

------------------------------ FSM ------------------------------ 
FSM_mem : process(clk_i) is
begin

    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
            current_state <= idle;
        else
            current_state <= next_state;
        end if;
    end if;

end process;

FSM_comb : process(current_state, group_reg, start_i, write_base_addr_i, axi_write_data_reg, axi_write_address_reg, done_reg, done_rst_pulse, config3,
                    PB_done_i, PB_data_i, PB_ready_i, addr_reg, bias_base_addr_i, counter_64, add_bias, axi_write_done_i, axi_write_next_i) is
begin

    group_next <= group_reg;
    axi_write_init_o <= '0';
    addr_next <= addr_reg;
    add_in2 <= (others => '0');
    en_64 <= '0';
    done_next <= done_reg;
    --done_processing_o <= '0';
	
    case current_state is
        
        when idle =>
            
            -- Priprema za prvu AXI transakciju
            axi_write_address_next <= write_base_addr_i;
            axi_write_data_next    <= axi_write_data_reg;
        
            if(done_rst_pulse = '1') then
                done_next <= '0';
            end if;
        
            if(start_i = '1') then
                next_state <= wait_done;
            else
                next_state <= idle;
            end if;
        
        when wait_done =>
        
            axi_write_address_next <= axi_write_address_reg;   
            axi_write_data_next    <= axi_write_data_reg;
        
            -- Priprema za prvo citanje iz ROM-a
            addr_next <= bias_base_addr_i;
        
            if(PB_done_i = '1') then
                next_state <= write_group;
            else
                next_state <= wait_done;
                
                if(PB_ready_i = '1') then
                    done_next <= '1';
                    --done_processing_o <= '1';
                    next_state <= idle;
                end if;
            
            end if;
        
        when write_group =>
            
            axi_write_address_next <= axi_write_address_reg;    
            axi_write_data_next    <= axi_write_data_reg;
            
            next_state <= bias;
            
            -- odrediti dobre podatke za bias
            addr_next <= std_logic_vector(unsigned(addr_reg) + to_unsigned(1, addr_reg'length));
            
            for i in 0 to MAC_count - 1 loop
            
                group_next(i) <= PB_data_i((i + 1) * MAC_width - 1 downto i * MAC_width);
            
            end loop;
            
        
        when bias =>                                
        
            axi_write_address_next <= axi_write_address_reg; 
            axi_write_data_next    <= axi_write_data_reg;
            
            -- odrediti dobre podatke za bias
            addr_next <= std_logic_vector(unsigned(addr_reg) + to_unsigned(1, addr_reg'length));
            
            group_next(to_integer(unsigned(counter_64))) <= add_bias;
            
            add_in2 <= group_reg(to_integer(unsigned(counter_64))); 
            en_64 <= '1';
            
            if(counter_64 = "111111") then
                next_state <= relu;
            else
                next_state <= bias;
            end if;
        
        when relu =>
        
            axi_write_address_next <= axi_write_address_reg; 
            axi_write_init_o <= '1';
            
            axi_write_data_next <= zeros & group_reg(63);
            
            if(config3(1) = '1') then
                if(group_reg(63)(MAC_WIDTH - 1) = '1' ) then
                    axi_write_data_next <= std_logic_vector(to_unsigned(0, 64));
                end if;                
            end if;
            
            
            en_64 <= '1';
            
            next_state <= axi_write;
        
            for i in 0 to MAC_count - 1 loop
                
                if(config3(1) = '1') then
                
                    if(group_reg(i)(MAC_width - 1) = '1') then
                        
                        group_next(i) <= std_logic_vector(to_signed(0, MAC_width));
                        
                    else
                        
                        group_next(i) <= group_reg(i);
                    
                    end if;
                
                end if;
            
            end loop;
        
        ----------------------------------------------------------------------
        when axi_write =>
        
            axi_write_address_next <= axi_write_address_reg;
            axi_write_data_next    <= axi_write_data_reg;  
        
            if(axi_write_done_i = '1') then
            
                axi_write_address_next <= std_logic_vector(unsigned(axi_write_address_reg) + to_unsigned(64 * 8, 32));
                next_state <= wait_done;
                
            else
                next_state <= axi_write;
                
                if(axi_write_next_i = '1') then
            
                    en_64 <= '1';
                    axi_write_data_next <= zeros & group_reg(to_integer(unsigned(not counter_64)));       
            
                end if;
            
            end if;
            
        
    
    end case;

end process;




end Behavioral;







