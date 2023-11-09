LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

package common is
  subtype reglen_t is std_logic_vector(31 downto 0); --defines cpu bus width
  subtype regadr_t is std_logic_vector(4 downto 0); --defines address with of register file


  subtype alucntrl_t is std_logic_vector(3 downto 0); --determines alu operation
    constant c_ALU_AND  : alucntrl_t := "0000";
    constant c_ALU_OR   : alucntrl_t := "0001";
    constant c_ALU_ADD  : alucntrl_t := "0010";
    constant c_ALU_LUI  : alucntrl_t := "0100";
    constant c_ALU_XOR  : alucntrl_t := "0101";
    constant c_ALU_SUB  : alucntrl_t := "0110";
    constant c_ALU_SLT  : alucntrl_t := "0111";
    constant c_ALU_NOR  : alucntrl_t := "1100";

  subtype pcsel_t is std_logic_vector(2 downto 0); -- determines selected pc 
    constant c_PC_PC4 : pcsel_t := "000"; 
    constant c_PC_BRANCH : pcsel_t := "001"; 
    constant c_PC_MISS : pcsel_t := "010"; 
end package common;