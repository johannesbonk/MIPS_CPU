LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.common.ALL;

package icache_pkg is
  type core_to_icache_t is record
    f_adr    : reglen_t; -- fetch address
    req      : std_logic;  
  end record core_to_icache_t; 

  type icache_to_core_t is record
    instr   : reglen_t; 
    ready   : std_logic; 
  end record icache_to_core_t; 

  type icache_to_mem_t is record
    adr    : reglen_t;
    req    : std_logic; 
  end record icache_to_mem_t; 

  type mem_to_icache_t is record
    ready  : std_logic; 
    data   : reglen_t; 
  end record mem_to_icache_t; 

  type icache_state_t is (
    IDLE,
    READ,
    MEM_READ,
    MEM_READ_INC);


end package icache_pkg;