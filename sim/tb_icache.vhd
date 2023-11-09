LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.common.ALL;

entity tb_icache is
end tb_icache;

architecture tb of tb_icache is
    constant c_DELTA_TIME : time := 1 ns;
    
    signal w_clk : std_logic; 
    signal w_rst : std_logic; 
    
    signal w_icache_ready : std_logic; 
    signal w_icache_instr : reglen_t; 
    signal w_icache_req : std_logic; 
    signal w_icache_adr : reglen_t; 
    signal w_core_f_adr : reglen_t; 
    signal w_core_req : std_logic; 
    signal w_mem_data : reglen_t; 
    signal w_mem_ready : std_logic; 

    begin
    DUT : entity work.icache(RTL)
        port map(in_clk => w_clk, 
                 in_rst => w_rst, 
                 core_to_icache.f_adr => w_core_f_adr, 
                 core_to_icache.req => w_core_req,
                 icache_to_core.instr  => w_icache_instr,
                 icache_to_core.ready => w_icache_ready, 
                 icache_to_mem.adr => w_icache_adr, 
                 icache_to_mem.req => w_icache_req, 
                 mem_to_icache.ready => w_mem_ready,
                 mem_to_icache.data => w_mem_data); 

    p_SIMULATION : process
    begin
        w_clk <= '0';
        w_rst <= '1'; 
        w_core_f_adr <= (others => '0'); 
        w_core_req <= '0'; 
        w_mem_ready <= '0'; 
        w_mem_data <= (others => '0');
        
        
        -- cache first address

        wait for c_DELTA_TIME; 
        w_clk <= '1'; 
        w_rst <= '0'; 

        wait for c_DELTA_TIME; 
        w_clk <= '0'; 
        w_core_f_adr <= x"ff_00_00_03"; 
        w_core_req <= '1'; 

        wait for c_DELTA_TIME; 
        w_clk <= '1'; 


        for i in 0 to 9 loop
            wait for c_DELTA_TIME; 
            w_clk <= '0'; 

            w_mem_ready <= '0'; 
            w_mem_data <= (others => '-'); 

            wait for c_DELTA_TIME; 
            w_clk <= '1'; 

            wait for c_DELTA_TIME; 
            w_clk <= '0'; 
            w_mem_ready <= '1'; 
            w_mem_data <= std_logic_vector(to_unsigned(i, w_mem_data'length)); 

            wait for c_DELTA_TIME; 
            w_clk <= '1'; 
        end loop; 


        -- cache second address
        

        wait for c_DELTA_TIME; 
        w_clk <= '0'; 
        w_core_f_adr <= x"aa_00_00_00"; 
        w_core_req <= '1'; 
    
        wait for c_DELTA_TIME; 
        w_clk <= '1'; 

        for i in 0 to 9 loop
            wait for c_DELTA_TIME; 
            w_clk <= '0'; 

            w_mem_ready <= '0'; 
            w_mem_data <= (others => '-'); 

            wait for c_DELTA_TIME; 
            w_clk <= '1'; 

            wait for c_DELTA_TIME; 
            w_clk <= '0'; 
            w_mem_ready <= '1'; 
            w_mem_data <= std_logic_vector(to_unsigned(2, w_mem_data'length)); 

            wait for c_DELTA_TIME; 
            w_clk <= '1'; 
        end loop;

        
        -- cache third address

        wait for c_DELTA_TIME; 
        w_clk <= '0'; 
        w_core_f_adr <= x"bb_00_00_00"; 
        w_core_req <= '1'; 
        
        wait for c_DELTA_TIME; 
        w_clk <= '1'; 
    
        for i in 0 to 9 loop
            wait for c_DELTA_TIME; 
            w_clk <= '0'; 
    
            w_mem_ready <= '0'; 
            w_mem_data <= (others => '-'); 
    
            wait for c_DELTA_TIME; 
            w_clk <= '1'; 
    
            wait for c_DELTA_TIME; 
            w_clk <= '0'; 
            w_mem_ready <= '1'; 
            w_mem_data <= std_logic_vector(to_unsigned(2, w_mem_data'length)); 
    
            wait for c_DELTA_TIME; 
            w_clk <= '1'; 
        end loop;

        -- read second address again
        wait for c_DELTA_TIME; 
        w_clk <= '0'; 
        w_core_f_adr <= x"aa_00_00_00"; 
        w_core_req <= '1'; 
    
        wait for c_DELTA_TIME; 
        w_clk <= '1'; 
        wait; --make process wait for an infinite timespan
    end process;
end architecture tb;