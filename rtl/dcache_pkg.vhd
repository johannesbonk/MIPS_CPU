LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.common.ALL;

package dcache_pkg is
  type core_to_dcache_t is record
    adr      : std_logic_vector(31 downto 0); 
    req      : std_logic;  
    write    : std_logic;
    data     : std_logic_vector(31 downto 0);  
  end record core_to_dcache_t; 

  type dcache_to_core_t is record
    data    : std_logic_vector(31 downto 0); 
    ready   : std_logic; 
  end record dcache_to_core_t; 

  type dcache_to_mem_t is record
    adr    : std_logic_vector(31 downto 0);
    req    : std_logic; 
    write  : std_logic; 
    data   : std_logic_vector(31 downto 0); 
  end record dcache_to_mem_t; 

  type mem_to_dcache_t is record
    ready  : std_logic; 
    data   : std_logic_vector(31 downto 0); 
  end record mem_to_dcache_t; 

  type dcache_state_t is (
    IDLE,
    READ,
    WRITE,
    MEM_READ,
    MEM_READ_INC,
    MEM_WB);


end package dcache_pkg;