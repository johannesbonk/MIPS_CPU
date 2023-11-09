LIBRARY ieee; 
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.common.ALL; 

entity ALU is 
    port(in_op_a  : in reglen_t; -- first ALU operand
         in_op_b  : in reglen_t; -- second ALU operand
         in_cntrl : in alucntrl_t; -- ALU control signal
         out_res  : out reglen_t); -- ALU result
end entity ALU; 

architecture logic of ALU is 
    signal w_slt : reglen_t; 
begin 

    SLT : process(in_op_a, in_op_b) is
    begin
        if(signed(in_op_a) < signed(in_op_b)) then
            w_slt <= std_logic_vector(to_unsigned(1, w_slt'length));
        else
            w_slt <= std_logic_vector(to_unsigned(0, w_slt'length));
        end if;
    end process;
    


    --multiplex required operation result
    with in_cntrl select 
    out_res <=  in_op_a and in_op_b when c_ALU_AND, --ANDing
                in_op_a or in_op_b when c_ALU_OR, --ORing
                std_logic_vector(signed(in_op_a) + signed(in_op_b)) when c_ALU_ADD, --addition
                in_op_b(15 downto 0) & x"00_00" when c_ALU_LUI, --LUI
                in_op_a xor in_op_b when c_ALU_XOR, --XORing
                std_logic_vector(signed(in_op_a) - signed(in_op_b)) when c_ALU_SUB, --subtraction
                w_slt when c_ALU_SLT, --set less than
                in_op_a nor in_op_b when c_ALU_NOR, --NORing
                (others => '-') when others; -- invalid opcode -- undefined
   
end architecture logic; 