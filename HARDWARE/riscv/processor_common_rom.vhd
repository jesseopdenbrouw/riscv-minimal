-- srec2vhdl table generator
-- for input file global.srec

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
           4 => x"9380018c",
           5 => x"9384818c",
           6 => x"1309801e",
           7 => x"6f004001",
           8 => x"23a00000",
           9 => x"93870000",
          10 => x"93804700",
          11 => x"83a70700",
          12 => x"e3e890fe",
          13 => x"b7070020",
          14 => x"93800700",
          15 => x"9384018c",
          16 => x"6f004001",
          17 => x"83270900",
          18 => x"23a0f000",
          19 => x"93804000",
          20 => x"13094900",
          21 => x"e3e890fe",
          22 => x"ef00000d",
          23 => x"ef00c000",
          24 => x"13050000",
          25 => x"ef008008",
          26 => x"130101fd",
          27 => x"23261102",
          28 => x"23248102",
          29 => x"13040103",
          30 => x"ef00c006",
          31 => x"13070500",
          32 => x"9307f0ff",
          33 => x"2320f700",
          34 => x"83a7018b",
          35 => x"13871700",
          36 => x"23a8e18a",
          37 => x"37573412",
          38 => x"13078767",
          39 => x"23a0e18c",
          40 => x"37d7ab90",
          41 => x"1307f7de",
          42 => x"23a2e18c",
          43 => x"03a7418b",
          44 => x"23a8e18a",
          45 => x"ef000003",
          46 => x"93070500",
          47 => x"23a00700",
          48 => x"83a7818b",
          49 => x"13871700",
          50 => x"23ace18a",
          51 => x"93070000",
          52 => x"13850700",
          53 => x"8320c102",
          54 => x"03248102",
          55 => x"13010103",
          56 => x"67800000",
          57 => x"03a5c18b",
          58 => x"67800000",
          59 => x"130101ff",
          60 => x"23248100",
          61 => x"23261100",
          62 => x"93070000",
          63 => x"13040500",
          64 => x"63880700",
          65 => x"93050000",
          66 => x"97000000",
          67 => x"e7000000",
          68 => x"0325401e",
          69 => x"83278502",
          70 => x"63840700",
          71 => x"e7800700",
          72 => x"13050400",
          73 => x"ef000009",
          74 => x"130101ff",
          75 => x"23248100",
          76 => x"23229100",
          77 => x"9307801e",
          78 => x"1304801e",
          79 => x"3304f440",
          80 => x"23202101",
          81 => x"23261100",
          82 => x"13542440",
          83 => x"9304801e",
          84 => x"13090000",
          85 => x"631c8902",
          86 => x"9307801e",
          87 => x"1304801e",
          88 => x"3304f440",
          89 => x"13542440",
          90 => x"9304801e",
          91 => x"13090000",
          92 => x"63188902",
          93 => x"8320c100",
          94 => x"03248100",
          95 => x"83244100",
          96 => x"03290100",
          97 => x"13010101",
          98 => x"67800000",
          99 => x"83a70400",
         100 => x"13091900",
         101 => x"93844400",
         102 => x"e7800700",
         103 => x"6ff09ffb",
         104 => x"83a70400",
         105 => x"13091900",
         106 => x"93844400",
         107 => x"e7800700",
         108 => x"6ff01ffc",
         109 => x"9308d005",
         110 => x"73000000",
         111 => x"63520502",
         112 => x"130101ff",
         113 => x"23248100",
         114 => x"13040500",
         115 => x"23261100",
         116 => x"33048040",
         117 => x"eff01ff1",
         118 => x"23208500",
         119 => x"6f000000",
         120 => x"6f000000",
         121 => x"50000020",
         122 => x"02000000",
         123 => x"04000000",
         124 => x"05000000",
         125 => x"06000000",
         126 => x"09000000",
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
         147 => x"00000000",
         148 => x"00000000",
         149 => x"00000000",
         150 => x"00000000",
         151 => x"00000000",
         152 => x"00000000",
         153 => x"00000000",
         154 => x"00000000",
         155 => x"00000000",
         156 => x"00000000",
         157 => x"00000000",
         158 => x"00000000",
         159 => x"00000000",
         160 => x"00000000",
         161 => x"00000000",
         162 => x"00000000",
         163 => x"00000000",
         164 => x"00000000",
         165 => x"00000000",
         166 => x"ffff0000",
         167 => x"0a000000",
         168 => x"feffffff",
         169 => x"50000020",
        others => (others => '-')
    );
end package processor_common_rom;
