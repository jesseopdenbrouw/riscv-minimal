-- srec2vhdl table generator
-- for input file string.srec

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.processor_common.all;

package processor_common_rom is
    constant rom_contents : rom_type := (
           0 => x"93810100",
           1 => x"17410020",
           2 => x"1301c1ff",
           3 => x"b7070020",
           4 => x"93804706",
           5 => x"b7070020",
           6 => x"93844706",
           7 => x"1309c028",
           8 => x"6f004001",
           9 => x"23a00000",
          10 => x"93870000",
          11 => x"93804700",
          12 => x"83a70700",
          13 => x"e3e890fe",
          14 => x"b7070020",
          15 => x"93800700",
          16 => x"b7070020",
          17 => x"93840706",
          18 => x"6f004001",
          19 => x"83270900",
          20 => x"23a0f000",
          21 => x"93804000",
          22 => x"13094900",
          23 => x"e3e890fe",
          24 => x"ef008010",
          25 => x"ef00c000",
          26 => x"13050000",
          27 => x"ef00000c",
          28 => x"130101f7",
          29 => x"23261108",
          30 => x"23248108",
          31 => x"13040109",
          32 => x"93070027",
          33 => x"03a50700",
          34 => x"83a54700",
          35 => x"03a68700",
          36 => x"83a6c700",
          37 => x"03a70701",
          38 => x"83a74701",
          39 => x"232ca4fc",
          40 => x"232eb4fc",
          41 => x"2320c4fe",
          42 => x"2322d4fe",
          43 => x"2324e4fe",
          44 => x"2326f4fe",
          45 => x"930784fd",
          46 => x"13850700",
          47 => x"ef004015",
          48 => x"93070500",
          49 => x"2328f4f6",
          50 => x"130784fd",
          51 => x"930744f7",
          52 => x"93050700",
          53 => x"13850700",
          54 => x"ef00c011",
          55 => x"930784fd",
          56 => x"93850700",
          57 => x"13058026",
          58 => x"ef004002",
          59 => x"93070500",
          60 => x"2328f4f6",
          61 => x"832704f7",
          62 => x"13850700",
          63 => x"8320c108",
          64 => x"03248108",
          65 => x"13010109",
          66 => x"67800000",
          67 => x"03460500",
          68 => x"83c60500",
          69 => x"13051500",
          70 => x"93851500",
          71 => x"6314d600",
          72 => x"e31606fe",
          73 => x"3305d640",
          74 => x"67800000",
          75 => x"130101ff",
          76 => x"23248100",
          77 => x"23261100",
          78 => x"93070000",
          79 => x"13040500",
          80 => x"63880700",
          81 => x"93050000",
          82 => x"97000000",
          83 => x"e7000000",
          84 => x"03258028",
          85 => x"83278502",
          86 => x"63840700",
          87 => x"e7800700",
          88 => x"13050400",
          89 => x"ef00800c",
          90 => x"130101ff",
          91 => x"23248100",
          92 => x"23229100",
          93 => x"9307c028",
          94 => x"1304c028",
          95 => x"3304f440",
          96 => x"23202101",
          97 => x"23261100",
          98 => x"13542440",
          99 => x"9304c028",
         100 => x"13090000",
         101 => x"631c8902",
         102 => x"9307c028",
         103 => x"1304c028",
         104 => x"3304f440",
         105 => x"13542440",
         106 => x"9304c028",
         107 => x"13090000",
         108 => x"63188902",
         109 => x"8320c100",
         110 => x"03248100",
         111 => x"83244100",
         112 => x"03290100",
         113 => x"13010101",
         114 => x"67800000",
         115 => x"83a70400",
         116 => x"13091900",
         117 => x"93844400",
         118 => x"e7800700",
         119 => x"6ff09ffb",
         120 => x"83a70400",
         121 => x"13091900",
         122 => x"93844400",
         123 => x"e7800700",
         124 => x"6ff01ffc",
         125 => x"93070500",
         126 => x"03c70500",
         127 => x"93871700",
         128 => x"93851500",
         129 => x"a38fe7fe",
         130 => x"e31807fe",
         131 => x"67800000",
         132 => x"93070500",
         133 => x"03c70700",
         134 => x"93871700",
         135 => x"e31c07fe",
         136 => x"3385a740",
         137 => x"1305f5ff",
         138 => x"67800000",
         139 => x"9308d005",
         140 => x"73000000",
         141 => x"63520502",
         142 => x"130101ff",
         143 => x"23248100",
         144 => x"13040500",
         145 => x"23261100",
         146 => x"33048040",
         147 => x"ef000001",
         148 => x"23208500",
         149 => x"6f000000",
         150 => x"6f000000",
         151 => x"b7070020",
         152 => x"03a50706",
         153 => x"67800000",
         154 => x"48656c6c",
         155 => x"6f000000",
         156 => x"48656c6c",
         157 => x"6f206469",
         158 => x"74206973",
         159 => x"2065656e",
         160 => x"20737472",
         161 => x"696e6700",
         162 => x"00000020",
         163 => x"00000000",
         164 => x"00000000",
         165 => x"00000000",
         166 => x"00000000",
         167 => x"00000000",
         168 => x"00000000",
         169 => x"00000000",
         170 => x"00000000",
         171 => x"00000000",
         172 => x"00000000",
         173 => x"00000000",
         174 => x"00000000",
         175 => x"00000000",
         176 => x"00000000",
         177 => x"00000000",
         178 => x"00000000",
         179 => x"00000000",
         180 => x"00000000",
         181 => x"00000000",
         182 => x"00000000",
         183 => x"00000000",
         184 => x"00000000",
         185 => x"00000000",
         186 => x"00000000",
         187 => x"00000020",
        others => (others => '-')
    );
end package processor_common_rom;