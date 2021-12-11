-- srec2vhdl table generator
-- for input file assembler.srec

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.processor_common.all;

package processor_common_rom is
    constant rom_contents : rom_type := (
           0 => x"97110020",
           1 => x"93810180",
           2 => x"17810020",
           3 => x"130181ff",
           4 => x"97000000",
           5 => x"938000ff",
           6 => x"17010020",
           7 => x"130181fe",
           8 => x"03a24000",
           9 => x"23204100",
          10 => x"83220100",
          11 => x"6f000000",
        others => (others => '-')
    );
end package processor_common_rom;
