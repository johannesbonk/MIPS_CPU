LIBRARY ieee; 
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.common.ALL; 

entity execute is 
    port(in_clk, in_rst : in std_logic; 
         in_rs0, in_rs1 : in reglen_t;
         in_imm         : in reglen_t; 
         in_imm_sel     : in std_logic; 
         in_reg_rd      : in regadr_t; 
         -- in_pc_load
         in_mem2reg_sel : in std_logic; 
         in_alu_cntrl   : in alucntrl_t;
         in_dmem_we      : in std_logic;
         in_reg_we      : in std_logic; 
         in_branch      : in std_logic; 
         in_load        : in std_logic; 
         in_dcache_ready : in std_logic; 
         out_equal  : out std_logic; 
         out_alu_res    : out reglen_t;
         out_rs1        : out reglen_t; 
         out_mem2reg_sel : out std_logic; 
         out_dmem_we  : out std_logic;
         out_reg_we  : out std_logic; 
         out_reg_rd  : out regadr_t; 
         out_branch  : out std_logic; 
         out_load    : out std_logic
         );
end entity execute; 

architecture RTL of execute is 
    signal r_rs0 : reglen_t; 
    signal r_rs1 : reglen_t; 
    signal r_imm : reglen_t; 
    signal r_imm_sel : std_logic; 
    signal r_mem2reg_sel : std_logic; 
    signal r_alu_cntrl : alucntrl_t; 
    signal r_dmem_we : std_logic := '0'; 
    signal r_reg_we : std_logic; 
    signal r_reg_rd : regadr_t; 
    signal r_branch : std_logic; 
    signal r_load : std_logic := '0'; 

    signal w_op_a : reglen_t; 
    signal w_op_b : reglen_t; 
    signal w_alu_res : reglen_t; 

    function and_reduce(vector : std_logic_vector) return std_logic is
        variable res : std_logic := '1';
        begin
        for i in vector'range loop
          res := res and vector(i);
        end loop;
        return res;
      end function;
begin 

    p_PIPELINE_REGISTER : process(in_clk)
    begin
        if(rising_edge(in_clk)) then 
            if(in_dcache_ready = '1') then 
                r_rs0 <= in_rs0; 
                r_rs1 <= in_rs1; 
                r_imm <= in_imm; 
                r_imm_sel <= in_imm_sel; 
                r_mem2reg_sel <= in_mem2reg_sel; 
                r_alu_cntrl <= in_alu_cntrl; 
                r_dmem_we <= in_dmem_we; 
                r_reg_we <= in_reg_we; 
                r_reg_rd <= in_reg_rd; 
                r_branch <= in_branch; 
                r_load <= in_load; 
            else 
                r_rs0 <= r_rs0; 
                r_rs1 <= r_rs1; 
                r_imm <= r_imm; 
                r_imm_sel <= r_imm_sel; 
                r_mem2reg_sel <= r_mem2reg_sel; 
                r_alu_cntrl <= r_alu_cntrl; 
                r_dmem_we <= r_dmem_we; 
                r_reg_we <= r_reg_we; 
                r_reg_rd <= r_reg_rd; 
                r_branch <= r_branch; 
                r_load <= r_load; 
            end if; 
        end if;
    end process; 

    w_op_a <= r_rs0; 

    w_op_b <= r_rs1 when r_imm_sel = '0' else 
              r_imm; 
    
    ALU : entity work.ALU(logic)
        port map(in_op_a  => w_op_a,
                 in_op_b  => w_op_b,
                 in_cntrl => r_alu_cntrl,
                 out_res  => w_alu_res); 
    out_alu_res <= w_alu_res; 

    -- flag generation 
    out_equal <= and_reduce(r_rs0 xnor r_rs1); -- returns 1 if all bits are zero

    -- signal passthrough 
    out_rs1	<= r_rs1; 
    out_mem2reg_sel <= r_mem2reg_sel; 
    out_dmem_we <= r_dmem_we; 
    out_reg_we <= r_reg_we; 
    out_reg_rd <= r_reg_rd; 
    out_branch <= r_branch;
    out_load <= r_load; 

end architecture RTL; 
