LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.common.ALL;

-- utilization: 
-- Slice LUTs: 607 (1.14 %)
-- Slice Registers: 992 (0.93 %)
-- F7 Muxes: 256 (0.96 %)
-- Slice: 382 (2.87 %)
-- LUT as Logic: 607 (1.14 %)

-- hinweis: 
-- hab das hardwired zero register von mips schonmal 
-- fuer spaetere aufgaben hinzugefuegt 
-- auch wenn das nicht in der aufgabenstellung stand

entity regfile is
  port(in_clk, in_rst       : in std_logic; -- clock and reset
       in_rs0adr, in_rs1adr : in regadr_t; -- register source adress 1 and 2
       in_we                : in std_logic; -- write enable (active high)
       in_rd                : in regadr_t; -- register destination (for write)
       in_data              : in reglen_t; -- write data input
       out_rs0, out_rs1     : out reglen_t); -- register source read port 1 and 2
end regfile;


architecture RTL of regfile is
  type reg_t is array(0 to 2**(regadr_t'length)) of reglen_t;
  signal r_regfile : reg_t := (others => (others => '0'));
begin
  p_REG_FILE : process (in_clk) is
  begin
    if rising_edge(in_clk) then
      r_regfile <= r_regfile;
      if(in_rst = '1') then --synchronous reset
        r_regfile <= (others => (others => '0'));
      elsif((in_we = '1') and (in_rd /= b"00000")) then -- mips $zero hardwired to zero 
        r_regfile(to_integer(unsigned(in_rd))) <= in_data;
      end if; 
    end if;
  end process p_REG_FILE;

  -- async read ports
  out_rs0 <= r_regfile(to_integer(unsigned(in_rs0adr)));
  out_rs1 <= r_regfile(to_integer(unsigned(in_rs1adr)));
end RTL;