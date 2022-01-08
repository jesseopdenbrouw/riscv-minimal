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
           2 => x"17810020",
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
          27 => x"1307c01e",
          28 => x"93870700",
          29 => x"83260700",
          30 => x"93874700",
          31 => x"13074700",
          32 => x"23aed7fe",
          33 => x"e398c7fe",
          34 => x"ef00c009",
          35 => x"ef00c000",
          36 => x"13050000",
          37 => x"ef004005",
          38 => x"37170000",
          39 => x"b70700f0",
          40 => x"13077745",
          41 => x"23a2e702",
          42 => x"23a40702",
          43 => x"83a60700",
          44 => x"370700f0",
          45 => x"93f6f60f",
          46 => x"23a0d702",
          47 => x"8327c702",
          48 => x"93f70701",
          49 => x"e38c07fe",
          50 => x"370700f0",
          51 => x"8327c702",
          52 => x"93f74700",
          53 => x"e38c07fe",
          54 => x"83270702",
          55 => x"13050000",
          56 => x"2322f700",
          57 => x"67800000",
          58 => x"130101ff",
          59 => x"23248100",
          60 => x"23261100",
          61 => x"93070000",
          62 => x"13040500",
          63 => x"63880700",
          64 => x"93050000",
          65 => x"97000000",
          66 => x"e7000000",
          67 => x"0325801e",
          68 => x"83278502",
          69 => x"63840700",
          70 => x"e7800700",
          71 => x"13050400",
          72 => x"ef000009",
          73 => x"130101ff",
          74 => x"23248100",
          75 => x"23229100",
          76 => x"9307c01e",
          77 => x"1304c01e",
          78 => x"3304f440",
          79 => x"23202101",
          80 => x"23261100",
          81 => x"13542440",
          82 => x"9304c01e",
          83 => x"13090000",
          84 => x"631c8902",
          85 => x"9307c01e",
          86 => x"1304c01e",
          87 => x"3304f440",
          88 => x"13542440",
          89 => x"9304c01e",
          90 => x"13090000",
          91 => x"63188902",
          92 => x"8320c100",
          93 => x"03248100",
          94 => x"83244100",
          95 => x"03290100",
          96 => x"13010101",
          97 => x"67800000",
          98 => x"83a70400",
          99 => x"13091900",
         100 => x"93844400",
         101 => x"e7800700",
         102 => x"6ff09ffb",
         103 => x"83a70400",
         104 => x"13091900",
         105 => x"93844400",
         106 => x"e7800700",
         107 => x"6ff01ffc",
         108 => x"9308d005",
         109 => x"73000000",
         110 => x"63520502",
         111 => x"130101ff",
         112 => x"23248100",
         113 => x"13040500",
         114 => x"23261100",
         115 => x"33048040",
         116 => x"ef000001",
         117 => x"23208500",
         118 => x"6f000000",
         119 => x"6f000000",
         120 => x"03a50186",
         121 => x"67800000",
         122 => x"00000020",
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
         144 => x"00000000",
         145 => x"00000000",
         146 => x"00000000",
         147 => x"00000020",
        others => (others => '-')
    );
end package processor_common_rom;
