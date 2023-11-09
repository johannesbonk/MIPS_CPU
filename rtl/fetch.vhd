LIBRARY ieee; 
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.common.ALL; 

entity fetch is 
    port(in_clk, in_rst : in std_logic; 
         in_pc_sel : in pcsel_t;
         in_pc_load : in std_logic; 
         in_branchadr : in reglen_t; 
         in_missadr    : in reglen_t; 
         out_pc : out reglen_t; 
         out_pc4   : out reglen_t);
end entity fetch; 

architecture RTL of fetch is     
    signal r_pc : std_logic_vector(reglen_t'HIGH downto 0) := (others => '0'); -- program counter register (incremented by 4, so lower 2 bits are ignored)

    signal w_pc_next : reglen_t;
    signal w_pc4 : reglen_t; 
begin 
    out_pc <= r_pc;
    w_pc4 <= std_logic_vector(unsigned(r_pc(reglen_t'HIGH downto 2)) + 1) & r_pc(1 downto 0); 
    out_pc4 <= w_pc4; 
    w_pc_next <= w_pc4 when in_pc_sel = c_PC_PC4 else
               in_branchadr; 

    -- PC REGISTER
    UPDATE_PC : process(in_clk)
    begin 
        if(rising_edge(in_clk)) then
            if(in_rst = '1') then
                r_pc <= (others => '0');  
            elsif(in_pc_load = '1') then
                r_pc <= w_pc_next; 
            end if; 
        end if; 
    end process; 
end architecture RTL; 
