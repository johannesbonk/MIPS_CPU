LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.common.ALL;

entity tb_cpu is
end;

architecture tb of tb_cpu is
    constant c_DELTA_TIME : time := 1 ns;

    signal w_clk : std_logic := '0'; 
    signal w_rst : std_logic := '0'; 
    signal w_led_reg : reglen_t; 

    begin
    DUT : entity work.cpu(top)
        port map(in_clk  => w_clk,
                 in_rst  => w_rst,
                 LD7 => open,
                 LD6 => open, 
                 LD5 => open, 
                 LD4 => open, 
                 LD3 => open, 
                 LD2 => open, 
                 LD1 => open, 
                 LD0 => open); 

    p_SIMULATION : process
    begin
        
        for i in 1 to 200 loop
            w_clk <= '0'; 
            wait for c_DELTA_TIME;
            w_clk <= '1';
            wait for c_DELTA_TIME; 
        end loop; 
        wait; --make process wait for an infinite timespan
    end process;
end architecture tb;