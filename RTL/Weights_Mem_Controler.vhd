----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;

entity Weights_Mem_Controler is
  generic 
  (
        DATA_IN_WIDTH  : integer  := 64;      -- Only 48 bits are used, but AXI IF is 64 bit wide
        DATA_OUT_WIDTH : integer  := 64;
        WRITE_MEM_ADDR : integer  := 10;
        READ_MEM_ADDR  : integer  := 32;
        MEM_NMB        : integer  := 16;
        BRAM_ADDR_OFFSET : integer := 512       
  );
  Port 
  (     
        -- Inputs
        clk_i             : in std_logic;
        rst_i             : in std_logic;
        
        -- Config Registers
        config1 : in std_logic_vector(31 downto 0);
        config3 : in std_logic_vector(31 downto 0); 
        --config6 : out std_logic_vector(31 downto 0); 
        done_mem_o : out std_logic;
        
        -- Outputs
        waddr_o       : out std_logic_vector(WRITE_MEM_ADDR-1 downto 0);
        data_o        : out std_logic_vector(DATA_OUT_WIDTH-1 downto 0);
        we_o          : out std_logic_vector(MEM_NMB-1 downto 0); -- 16 bit vector for enabling 1 weights memory at a time.
		
        --AXI ports:
		axi_read_init_o        : out std_logic;
        axi_read_data_i        : in std_logic_vector(DATA_IN_WIDTH-1 downto 0);
        axi_read_addr_o        : out std_logic_vector(READ_MEM_ADDR-1 downto 0);
        axi_read_last_i        : in std_logic;  -- Status signal    -- Indicator that the current data arriving to the controler is the last in the burst of data transfer
        axi_read_valid_i       : in std_logic;  -- Status signal    -- Indicator that valid data is present on the AXI bus
        axi_read_ready_o       : out std_logic  -- Status signal
        
  );
end Weights_Mem_Controler;

architecture Behavioral of Weights_Mem_Controler is
-- States of FSM
type states is (idle, config, read, finish);
signal current_state, next_state : states;

-- Constants
    constant wmem_size : integer := 576;
        
-- Signals
    -- signal stick_counter_next, stick_counter_reg : std_logic_vector(3 downto 0);    -- Register for counting how many "sticks" are written into each memory. 9 sticks are put into each memory. Each MAC is processing 1 packet of data = 9 sticks."
    signal we_next, we_reg                       : std_logic_vector(MEM_NMB-1 downto 0);
    signal raddr_next, raddr_reg                 : std_logic_vector(READ_MEM_ADDR-1 downto 0);  -- Address from which AXI reads the weights
    --signal waddr_next, waddr_reg                 : std_logic_vector(WRITE_MEM_ADDR-1 downto 0); -- Address to which the controler writes the weights into the BRAMs
    signal done_reg, done_next : std_logic;

signal start_ff, start_ff2, start_pulse : std_logic;

signal start_i : std_logic;  -- Status signal
signal base_addr_i : std_logic_vector(READ_MEM_ADDR-1 downto 0);     -- Address where to start reading data in the memory.
signal done_o : std_logic; -- Status signal
--signal config6_temp : std_logic_vector(31 downto 0) := (others => '0');


-- Counters 
signal counter_576 : std_logic_vector(9 downto 0);
signal counter_16 : std_logic_vector(3 downto 0);
signal en_576, en_16, hard_rst_576 : std_logic;
    
begin

--------------------------- Assigments ---------------------------
axi_read_addr_o <= raddr_reg;
waddr_o <= counter_576;
data_o <= axi_read_data_i;
we_o <= we_reg;
axi_read_ready_o <= '1';

base_addr_i <= config1;
start_i <= config3(3);
--config6 <= config6_temp;
done_mem_o <= done_o;
done_o <= done_reg;

start_pulse <= start_ff and (not start_ff2);

--creating start pulse
strat_gen: process(clk_i) is
begin
    if(rising_edge(clk_i)) then
        start_ff <= start_i;
        start_ff2 <= start_ff;
    end if;

end process;


-- State and data registers:
registers: process (clk_i) is
        begin                   
        if (rising_edge(clk_i)) then
            if(rst_i = '1') then
                we_reg       <= (others => '0');    
                --waddr_reg    <= (others => '0');
                raddr_reg    <= (others => '0');
                -- stick_counter_reg <= (others => '0');
                done_reg <= '0';
            else
                we_reg       <= we_next;    
                --waddr_reg    <= waddr_next;
                raddr_reg    <= raddr_next;
                --stick_counter_reg <= stick_counter_next;
                done_reg <= done_next;
            end if;
        end if;
    end process;


--------------------------- Counters ---------------------------
counter576: process(clk_i) is
begin
    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
            counter_576 <= (others => '0');
        else
            counter_576 <= counter_576;
            
            if(hard_rst_576 = '1') then
                counter_576 <= (others => '0');
            else    
                if(en_576 = '1') then
                    counter_576 <= std_logic_vector(unsigned(counter_576) + to_unsigned(1, 10));
                end if;
            end if;
                         
        end if;
    end if;
end process;    
    
    
counter16: process(clk_i) is
begin
    if(rising_edge(clk_i)) then
        if(rst_i = '1') then
            counter_16 <= (others => '0');
        else
            counter_16 <= counter_16;
            if(en_16 = '1') then
                counter_16 <= std_logic_vector(unsigned(counter_16) + to_unsigned(1, 4));
            end if;             
        end if;
    end if;
end process;      

--------------------------- FSM ---------------------------
FSM_memory: process(clk_i) is
begin
    if(rising_edge(clk_i)) then
    
        if(rst_i = '1') then
            current_state <= idle;
        else
            current_state <= next_state;
        end if;
        
    end if;
end process;


FSM_combinatorial: process(current_state, base_addr_i, start_pulse, axi_read_valid_i, raddr_reg, done_reg,
                           we_reg, axi_read_valid_i, counter_576, counter_16, axi_read_last_i) is
begin

en_16 <= '0';
en_576 <= '0';
hard_rst_576 <= '0';

-- AXI --
axi_read_init_o <= '0';

done_next <= done_reg;
--done_o <= '0';

-- Default next values
we_next <= we_reg;    
raddr_next <= raddr_reg;

case current_state is

    when idle => 
        
        raddr_next <= base_addr_i;
        we_next <= std_logic_vector(to_unsigned(0, we_reg'length)); 
                
        if(start_pulse = '1') then
            we_next <= std_logic_vector(shift_left(to_unsigned(1, we_next'length), we_next'length - 1));
            next_state <= config;
            done_next <= '0';
        else
            next_state <= idle;
        end if;
     
     when config =>
     
        axi_read_init_o <= '1';
        next_state <= read;
     
     when read => 
        
        next_state <= read;
        
        if(axi_read_valid_i = '1') then
            
            en_576 <= '1';
            
            if(axi_read_last_i = '1') then
                
               next_state <= config;
               raddr_next <= std_logic_vector(unsigned(raddr_reg) + to_unsigned(BRAM_ADDR_OFFSET, raddr_reg'length));
                    
               if(counter_576(9 downto 6) = "1000") then -- Ovo je 9. burst i gotov je upis memorije
                
                    hard_rst_576 <= '1';
                    en_16 <= '1'; -- Predji na sledecu memoriju
                    we_next <= std_logic_vector(shift_right(unsigned(we_reg), 1)); -- 1000 -> 0100
                    
                    
                    if(counter_16 = "1111") then
                        next_state <= finish;
                    end if;

                end if;

                
            end if;
            
        end if;
        
        
     when finish => 
        
           -- done_o <= '1';
           done_next <= '1';
           next_state <= idle;
        

end case;

end process;
    
end Behavioral;
