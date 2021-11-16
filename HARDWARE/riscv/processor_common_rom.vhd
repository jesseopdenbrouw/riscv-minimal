-- srec2vhdl table generator
-- for input file flash.srec

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.processor_common.all;

package processor_common_rom is
    constant rom_contents : rom_type := (
           0 => x"97",    1 => x"11",    2 => x"00",    3 => x"20", 
           4 => x"93",    5 => x"81",    6 => x"01",    7 => x"80", 
           8 => x"17",    9 => x"41",   10 => x"00",   11 => x"20", 
          12 => x"13",   13 => x"01",   14 => x"81",   15 => x"ff", 
          16 => x"97",   17 => x"00",   18 => x"00",   19 => x"00", 
          20 => x"e7",   21 => x"80",   22 => x"c0",   23 => x"00", 
          24 => x"6f",   25 => x"00",   26 => x"00",   27 => x"00", 
          28 => x"37",   29 => x"57",   30 => x"4c",   31 => x"00", 
          32 => x"13",   33 => x"01",   34 => x"01",   35 => x"ff", 
          36 => x"13",   37 => x"07",   38 => x"f7",   39 => x"b3", 
          40 => x"b7",   41 => x"06",   42 => x"00",   43 => x"f0", 
          44 => x"13",   45 => x"06",   46 => x"f0",   47 => x"ff", 
          48 => x"23",   49 => x"26",   50 => x"01",   51 => x"00", 
          52 => x"83",   53 => x"27",   54 => x"c1",   55 => x"00", 
          56 => x"63",   57 => x"6c",   58 => x"f7",   59 => x"00", 
          60 => x"83",   61 => x"27",   62 => x"c1",   63 => x"00", 
          64 => x"93",   65 => x"87",   66 => x"17",   67 => x"00", 
          68 => x"23",   69 => x"26",   70 => x"f1",   71 => x"00", 
          72 => x"83",   73 => x"27",   74 => x"c1",   75 => x"00", 
          76 => x"e3",   77 => x"78",   78 => x"f7",   79 => x"fe", 
          80 => x"23",   81 => x"a2",   82 => x"c6",   83 => x"00", 
          84 => x"23",   85 => x"26",   86 => x"01",   87 => x"00", 
          88 => x"83",   89 => x"27",   90 => x"c1",   91 => x"00", 
          92 => x"63",   93 => x"6c",   94 => x"f7",   95 => x"00", 
          96 => x"83",   97 => x"27",   98 => x"c1",   99 => x"00", 
         100 => x"93",  101 => x"87",  102 => x"17",  103 => x"00", 
         104 => x"23",  105 => x"26",  106 => x"f1",  107 => x"00", 
         108 => x"83",  109 => x"27",  110 => x"c1",  111 => x"00", 
         112 => x"e3",  113 => x"78",  114 => x"f7",  115 => x"fe", 
         116 => x"23",  117 => x"a2",  118 => x"06",  119 => x"00", 
         120 => x"6f",  121 => x"f0",  122 => x"9f",  123 => x"fb", 
        others => (others => '-')
    );
end package processor_common_rom;
