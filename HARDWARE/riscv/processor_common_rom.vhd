-- srec2vhdl table generator
-- for input file flash.srec

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.processor_common.all;

package processor_common_rom is
    constant rom_contents : rom_type := (
           0 => x"97110020",
           1 => x"93810180",
           2 => x"17410020",
           3 => x"130181ff",
           4 => x"97000000",
           5 => x"e780c000",
           6 => x"6f000000",
           7 => x"b70600f0",
           8 => x"37574c00",
           9 => x"130101ff",
          10 => x"93864600",
          11 => x"1306f0ff",
          12 => x"1307f7b3",
          13 => x"23a0c600",
          14 => x"23260100",
          15 => x"8327c100",
          16 => x"636cf700",
          17 => x"8327c100",
          18 => x"93871700",
          19 => x"2326f100",
          20 => x"8327c100",
          21 => x"e378f7fe",
          22 => x"83a70600",
          23 => x"93c7f7ff",
          24 => x"23a0f600",
          25 => x"23260100",
          26 => x"8327c100",
          27 => x"e364f7fc",
          28 => x"8327c100",
          29 => x"93871700",
          30 => x"2326f100",
          31 => x"8327c100",
          32 => x"e378f7fe",
          33 => x"6ff01ffb",
        others => (others => '-')
    );
end package processor_common_rom;
