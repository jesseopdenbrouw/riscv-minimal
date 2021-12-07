-- srec2vhdl table generator
-- for input file usart.srec

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
           4 => x"93864186",
           5 => x"13874186",
           6 => x"63f8e602",
           7 => x"1307f7ff",
           8 => x"3307d740",
           9 => x"1377c7ff",
          10 => x"13074700",
          11 => x"b386e600",
          12 => x"93874186",
          13 => x"23a00700",
          14 => x"13870700",
          15 => x"03270700",
          16 => x"93874700",
          17 => x"e398d7fe",
          18 => x"b7070020",
          19 => x"13860700",
          20 => x"13874186",
          21 => x"637ae602",
          22 => x"1307f7ff",
          23 => x"3307c740",
          24 => x"1377c7ff",
          25 => x"13074700",
          26 => x"3306e600",
          27 => x"1307001e",
          28 => x"93870700",
          29 => x"83260700",
          30 => x"93874700",
          31 => x"13074700",
          32 => x"23aed7fe",
          33 => x"e398c7fe",
          34 => x"ef000009",
          35 => x"ef00c000",
          36 => x"13050000",
          37 => x"ef008004",
          38 => x"b7170000",
          39 => x"370700f0",
          40 => x"93877745",
          41 => x"2322f702",
          42 => x"93072006",
          43 => x"2320f702",
          44 => x"8327c702",
          45 => x"93f70701",
          46 => x"e38c07fe",
          47 => x"370700f0",
          48 => x"8327c702",
          49 => x"93f74700",
          50 => x"e38c07fe",
          51 => x"83270702",
          52 => x"13050000",
          53 => x"2322f700",
          54 => x"67800000",
          55 => x"130101ff",
          56 => x"23248100",
          57 => x"23261100",
          58 => x"93070000",
          59 => x"13040500",
          60 => x"63880700",
          61 => x"93050000",
          62 => x"97000000",
          63 => x"e7000000",
          64 => x"0325c01d",
          65 => x"83278502",
          66 => x"63840700",
          67 => x"e7800700",
          68 => x"13050400",
          69 => x"ef000009",
          70 => x"130101ff",
          71 => x"23248100",
          72 => x"23229100",
          73 => x"9307001e",
          74 => x"1304001e",
          75 => x"3304f440",
          76 => x"23202101",
          77 => x"23261100",
          78 => x"13542440",
          79 => x"9304001e",
          80 => x"13090000",
          81 => x"631c8902",
          82 => x"9307001e",
          83 => x"1304001e",
          84 => x"3304f440",
          85 => x"13542440",
          86 => x"9304001e",
          87 => x"13090000",
          88 => x"63188902",
          89 => x"8320c100",
          90 => x"03248100",
          91 => x"83244100",
          92 => x"03290100",
          93 => x"13010101",
          94 => x"67800000",
          95 => x"83a70400",
          96 => x"13091900",
          97 => x"93844400",
          98 => x"e7800700",
          99 => x"6ff09ffb",
         100 => x"83a70400",
         101 => x"13091900",
         102 => x"93844400",
         103 => x"e7800700",
         104 => x"6ff01ffc",
         105 => x"9308d005",
         106 => x"73000000",
         107 => x"63520502",
         108 => x"130101ff",
         109 => x"23248100",
         110 => x"13040500",
         111 => x"23261100",
         112 => x"33048040",
         113 => x"ef000001",
         114 => x"23208500",
         115 => x"6f000000",
         116 => x"6f000000",
         117 => x"03a50186",
         118 => x"67800000",
         119 => x"00000020",
         120 => x"00000000",
         121 => x"00000000",
         122 => x"00000000",
         123 => x"00000000",
         124 => x"00000000",
         125 => x"00000000",
         126 => x"00000000",
         127 => x"00000000",
         128 => x"00000000",
         129 => x"00000000",
         130 => x"00000000",
         131 => x"00000000",
         132 => x"00000000",
         133 => x"00000000",
         134 => x"00000000",
         135 => x"00000000",
         136 => x"00000000",
         137 => x"00000000",
         138 => x"00000000",
         139 => x"00000000",
         140 => x"00000000",
         141 => x"00000000",
         142 => x"00000000",
         143 => x"00000000",
         144 => x"00000020",
        others => (others => '-')
    );
end package processor_common_rom;
