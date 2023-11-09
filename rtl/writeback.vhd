LIBRARY ieee; 
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.common.ALL; 

entity writeback is 
    port(in_clk, in_rst : in std_logic;
         in_reg_we      : in std_logic; 
         in_reg_rd      : in regadr_t; 
         in_mem2reg_sel : in std_logic; 
         in_mem_res     : in reglen_t; 
         in_alu_res     : in reglen_t; 
         out_reg_data   : out reglen_t;
         out_reg_we     : out std_logic;
         out_reg_rd     : out regadr_t);
end entity writeback; 

architecture RTL of writeback is 
    signal r_reg_we : std_logic; 
    signal r_reg_rd : regadr_t; 
    signal r_mem2reg_sel : std_logic; 
    signal r_mem_res : reglen_t; 
    signal r_alu_res : reglen_t; 
begin 

    p_PIPELINE_REGISTER : process(in_clk) 
    begin 
        if(rising_edge(in_clk)) then 
            r_reg_we <= in_reg_we;
            r_reg_rd <= in_reg_rd;  
            r_mem2reg_sel <= in_mem2reg_sel; 
            r_mem_res <= in_mem_res; 
            r_alu_res <= in_alu_res; 
        end if; 
    end process; 

    out_reg_data <= r_mem_res when r_mem2reg_sel = '1' else
                    r_alu_res; 
    
    -- signal passthough 
    out_reg_we <= r_reg_we; 
    out_reg_rd <= r_reg_rd; 
end architecture RTL; 
