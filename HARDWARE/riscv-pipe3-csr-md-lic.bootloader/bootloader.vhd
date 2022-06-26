--
-- This file is part of the THUAS RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- bootloader.vhd - Description of the bootloader ROM unit

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- This file contains the description of the boot ROM. The ROM
-- is placed in immutable onboard RAM blocks. A read takes two
-- clock cycles, for both instruction and data.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;
use work.processor_common_rom.all;

entity bootloader is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_pc : in data_type;
          I_address : in data_type;
          I_csboot : in std_logic;
          I_size : in size_type;
          I_stall : in std_logic;
          O_instr : out data_type;
          O_data_out : out data_type;
          --
          O_instruction_misaligned_error : out std_logic;
          O_load_misaligned_error : out std_logic
         );
end entity bootloader;

architecture rtl of bootloader is

-- The bootloader ROM
signal bootrom : bootloader_type := (
           0 => x"97110010",
           1 => x"93810180",
           2 => x"17810010",
           3 => x"130181ff",
           4 => x"97020000",
           5 => x"9382c23c",
           6 => x"73905230",
           7 => x"b7070020",
           8 => x"37050020",
           9 => x"93870700",
          10 => x"13070500",
          11 => x"13060000",
          12 => x"63e4e700",
          13 => x"3386e740",
          14 => x"93050000",
          15 => x"13050500",
          16 => x"ef00403c",
          17 => x"37050020",
          18 => x"b7070020",
          19 => x"93870700",
          20 => x"13070500",
          21 => x"13060000",
          22 => x"63e4e700",
          23 => x"3386e740",
          24 => x"b7150010",
          25 => x"938505b9",
          26 => x"13050500",
          27 => x"ef004037",
          28 => x"ef00003d",
          29 => x"6f000000",
          30 => x"37170000",
          31 => x"b70700f0",
          32 => x"13077745",
          33 => x"23a2e702",
          34 => x"67800000",
          35 => x"1375f50f",
          36 => x"b70700f0",
          37 => x"23a0a702",
          38 => x"370700f0",
          39 => x"8327c702",
          40 => x"93f70701",
          41 => x"e38c07fe",
          42 => x"67800000",
          43 => x"130101ff",
          44 => x"23248100",
          45 => x"23261100",
          46 => x"13040500",
          47 => x"03450400",
          48 => x"631a0500",
          49 => x"8320c100",
          50 => x"03248100",
          51 => x"13010101",
          52 => x"67800000",
          53 => x"13041400",
          54 => x"eff05ffb",
          55 => x"6ff01ffe",
          56 => x"63040500",
          57 => x"6ff09ffc",
          58 => x"67800000",
          59 => x"b70600f0",
          60 => x"83a7c602",
          61 => x"93f74700",
          62 => x"e38c07fe",
          63 => x"03a50602",
          64 => x"1375f50f",
          65 => x"67800000",
          66 => x"b70700f0",
          67 => x"03a5c702",
          68 => x"13754500",
          69 => x"67800000",
          70 => x"130101fd",
          71 => x"23248102",
          72 => x"23229102",
          73 => x"23202103",
          74 => x"232e3101",
          75 => x"232c4101",
          76 => x"232a5101",
          77 => x"23286101",
          78 => x"23267101",
          79 => x"23248101",
          80 => x"23229101",
          81 => x"23261102",
          82 => x"93040500",
          83 => x"13040000",
          84 => x"9309d000",
          85 => x"1389f5ff",
          86 => x"130ae005",
          87 => x"930a5001",
          88 => x"130b8000",
          89 => x"930ba000",
          90 => x"130c3000",
          91 => x"b71c0010",
          92 => x"eff0dff7",
          93 => x"93070500",
          94 => x"1375f50f",
          95 => x"63043509",
          96 => x"63cca902",
          97 => x"63006505",
          98 => x"630e7507",
          99 => x"63008507",
         100 => x"63562407",
         101 => x"93f7f70f",
         102 => x"138707fe",
         103 => x"1377f70f",
         104 => x"e368eafc",
         105 => x"33878400",
         106 => x"2300f700",
         107 => x"13041400",
         108 => x"eff0dfed",
         109 => x"6ff0dffb",
         110 => x"63065503",
         111 => x"1307f007",
         112 => x"e318e5fc",
         113 => x"630c0402",
         114 => x"1305f007",
         115 => x"eff01fec",
         116 => x"1304f4ff",
         117 => x"6ff0dff9",
         118 => x"1305f007",
         119 => x"eff01feb",
         120 => x"1304f4ff",
         121 => x"e31a04fe",
         122 => x"6ff09ff8",
         123 => x"13850ca8",
         124 => x"eff0dfeb",
         125 => x"13040000",
         126 => x"6ff09ff7",
         127 => x"13057000",
         128 => x"6ff01ffb",
         129 => x"b3848400",
         130 => x"37150010",
         131 => x"23800400",
         132 => x"13058595",
         133 => x"eff09fe9",
         134 => x"8320c102",
         135 => x"13050400",
         136 => x"03248102",
         137 => x"83244102",
         138 => x"03290102",
         139 => x"8329c101",
         140 => x"032a8101",
         141 => x"832a4101",
         142 => x"032b0101",
         143 => x"832bc100",
         144 => x"032c8100",
         145 => x"832c4100",
         146 => x"13010103",
         147 => x"67800000",
         148 => x"37180010",
         149 => x"93070500",
         150 => x"1308d8a8",
         151 => x"03c70700",
         152 => x"33070701",
         153 => x"03470700",
         154 => x"13778700",
         155 => x"63160702",
         156 => x"13050000",
         157 => x"93081000",
         158 => x"83c60700",
         159 => x"3307d800",
         160 => x"03470700",
         161 => x"13764704",
         162 => x"631c0600",
         163 => x"63840500",
         164 => x"23a0f500",
         165 => x"67800000",
         166 => x"93871700",
         167 => x"6ff01ffc",
         168 => x"13734700",
         169 => x"13154500",
         170 => x"13860600",
         171 => x"630a0300",
         172 => x"938606fd",
         173 => x"33e5a600",
         174 => x"93871700",
         175 => x"6ff0dffb",
         176 => x"13773700",
         177 => x"63141701",
         178 => x"13860602",
         179 => x"130696fa",
         180 => x"3365a600",
         181 => x"6ff05ffe",
         182 => x"130101fe",
         183 => x"232e1100",
         184 => x"23220100",
         185 => x"23240100",
         186 => x"23060100",
         187 => x"9386f5ff",
         188 => x"13077000",
         189 => x"93070500",
         190 => x"6374d700",
         191 => x"93058000",
         192 => x"13054100",
         193 => x"b305b500",
         194 => x"13069003",
         195 => x"93f6f700",
         196 => x"13870603",
         197 => x"6374e600",
         198 => x"13877605",
         199 => x"a38fe5fe",
         200 => x"9385f5ff",
         201 => x"93d74700",
         202 => x"e312b5fe",
         203 => x"eff05fdb",
         204 => x"8320c101",
         205 => x"13010102",
         206 => x"67800000",
         207 => x"130101fe",
         208 => x"23263101",
         209 => x"b7190010",
         210 => x"232c8100",
         211 => x"232a9100",
         212 => x"23282101",
         213 => x"23244101",
         214 => x"232e1100",
         215 => x"93040500",
         216 => x"13090000",
         217 => x"13040000",
         218 => x"9389d9a8",
         219 => x"130a1000",
         220 => x"63449902",
         221 => x"8320c101",
         222 => x"13050400",
         223 => x"03248101",
         224 => x"83244101",
         225 => x"03290101",
         226 => x"8329c100",
         227 => x"032a8100",
         228 => x"13010102",
         229 => x"67800000",
         230 => x"eff05fd5",
         231 => x"b3073501",
         232 => x"83c70700",
         233 => x"13144400",
         234 => x"13f74700",
         235 => x"630a0700",
         236 => x"930705fd",
         237 => x"3364f400",
         238 => x"13091900",
         239 => x"6ff05ffb",
         240 => x"13f74704",
         241 => x"e30a07fe",
         242 => x"93f73700",
         243 => x"63944701",
         244 => x"13050502",
         245 => x"930795fa",
         246 => x"6ff0dffd",
         247 => x"6f000000",
         248 => x"13030500",
         249 => x"630e0600",
         250 => x"83830500",
         251 => x"23007300",
         252 => x"1306f6ff",
         253 => x"13031300",
         254 => x"93851500",
         255 => x"e31606fe",
         256 => x"67800000",
         257 => x"13030500",
         258 => x"630a0600",
         259 => x"2300b300",
         260 => x"1306f6ff",
         261 => x"13031300",
         262 => x"e31a06fe",
         263 => x"67800000",
         264 => x"03460500",
         265 => x"83c60500",
         266 => x"13051500",
         267 => x"93851500",
         268 => x"6314d600",
         269 => x"e31606fe",
         270 => x"3305d640",
         271 => x"67800000",
         272 => x"130101f9",
         273 => x"23261106",
         274 => x"23248106",
         275 => x"23229106",
         276 => x"23202107",
         277 => x"232e3105",
         278 => x"232c4105",
         279 => x"232a5105",
         280 => x"23286105",
         281 => x"23267105",
         282 => x"23248105",
         283 => x"23229105",
         284 => x"2320a105",
         285 => x"232eb103",
         286 => x"eff01fc0",
         287 => x"37150010",
         288 => x"13050593",
         289 => x"eff0dfc5",
         290 => x"b70700f0",
         291 => x"1307f03f",
         292 => x"b704a000",
         293 => x"37091000",
         294 => x"23a2e700",
         295 => x"13041000",
         296 => x"93841400",
         297 => x"1309f9ff",
         298 => x"b70900f0",
         299 => x"eff0dfc5",
         300 => x"631c050e",
         301 => x"13041400",
         302 => x"6318940c",
         303 => x"b70700f0",
         304 => x"23a20700",
         305 => x"63160500",
         306 => x"23a20702",
         307 => x"e7000500",
         308 => x"eff0dfc1",
         309 => x"93071002",
         310 => x"93040000",
         311 => x"6310f51e",
         312 => x"b71a0010",
         313 => x"13854a95",
         314 => x"370901ff",
         315 => x"b7090001",
         316 => x"370affff",
         317 => x"eff0dfbe",
         318 => x"1309f9ff",
         319 => x"9389f9ff",
         320 => x"130afa0f",
         321 => x"370400f0",
         322 => x"83274400",
         323 => x"93c71700",
         324 => x"2322f400",
         325 => x"eff09fbd",
         326 => x"1375f50f",
         327 => x"93073005",
         328 => x"631ef516",
         329 => x"eff09fbc",
         330 => x"1374f50f",
         331 => x"9307f4fc",
         332 => x"93f7f70f",
         333 => x"13072000",
         334 => x"6362f710",
         335 => x"93071003",
         336 => x"6318f406",
         337 => x"13052000",
         338 => x"eff05fdf",
         339 => x"130bd5ff",
         340 => x"13054000",
         341 => x"eff09fde",
         342 => x"13040500",
         343 => x"330bab00",
         344 => x"130c3000",
         345 => x"930c1000",
         346 => x"631a6407",
         347 => x"1304a000",
         348 => x"eff0dfb7",
         349 => x"1375f50f",
         350 => x"e31c85fe",
         351 => x"13854a95",
         352 => x"eff01fb6",
         353 => x"6ff01ff8",
         354 => x"b3772401",
         355 => x"e39007f2",
         356 => x"1305a002",
         357 => x"eff09faf",
         358 => x"83a74900",
         359 => x"93d71700",
         360 => x"23a2f900",
         361 => x"6ff09ff0",
         362 => x"13051000",
         363 => x"6ff01ff1",
         364 => x"93072003",
         365 => x"13052000",
         366 => x"631af400",
         367 => x"eff01fd8",
         368 => x"130bc5ff",
         369 => x"13056000",
         370 => x"6ff0dff8",
         371 => x"eff01fd7",
         372 => x"130bb5ff",
         373 => x"13058000",
         374 => x"6ff0dff7",
         375 => x"13052000",
         376 => x"eff0dfd5",
         377 => x"937bc4ff",
         378 => x"93763400",
         379 => x"13062000",
         380 => x"03a70b00",
         381 => x"93070500",
         382 => x"6386c602",
         383 => x"638a8603",
         384 => x"638c9601",
         385 => x"137707f0",
         386 => x"b3e7e700",
         387 => x"23a0fb00",
         388 => x"13041400",
         389 => x"6ff05ff5",
         390 => x"33774701",
         391 => x"93178500",
         392 => x"6ff09ffe",
         393 => x"33772701",
         394 => x"93170501",
         395 => x"6ff0dffd",
         396 => x"33773701",
         397 => x"93178501",
         398 => x"6ff01ffd",
         399 => x"930794fc",
         400 => x"93f7f70f",
         401 => x"130ba000",
         402 => x"6362f704",
         403 => x"13052000",
         404 => x"eff0dfce",
         405 => x"93077003",
         406 => x"13058000",
         407 => x"630af400",
         408 => x"93078003",
         409 => x"13056000",
         410 => x"6304f400",
         411 => x"13054000",
         412 => x"eff0dfcc",
         413 => x"93040500",
         414 => x"1304a000",
         415 => x"eff01fa7",
         416 => x"1375f50f",
         417 => x"e31c85fe",
         418 => x"6ff05fef",
         419 => x"eff01fa6",
         420 => x"1375f50f",
         421 => x"e31c65ff",
         422 => x"6ff05fee",
         423 => x"9307a004",
         424 => x"6310f508",
         425 => x"23220402",
         426 => x"23220400",
         427 => x"e7800400",
         428 => x"b70700f0",
         429 => x"1307a00a",
         430 => x"23a2e700",
         431 => x"37190010",
         432 => x"13058995",
         433 => x"b7190010",
         434 => x"eff09fa1",
         435 => x"13040000",
         436 => x"b71b0010",
         437 => x"9389d9a8",
         438 => x"b7170010",
         439 => x"1385c795",
         440 => x"eff01fa0",
         441 => x"93059002",
         442 => x"13054100",
         443 => x"eff0dfa2",
         444 => x"13054100",
         445 => x"ef00401e",
         446 => x"b7170010",
         447 => x"130a0500",
         448 => x"93850796",
         449 => x"13054100",
         450 => x"eff09fd1",
         451 => x"63100502",
         452 => x"37150010",
         453 => x"13054596",
         454 => x"eff09f9c",
         455 => x"6f004003",
         456 => x"93073002",
         457 => x"e31cf5e4",
         458 => x"6ff09ff8",
         459 => x"b7170010",
         460 => x"9385c7a4",
         461 => x"13054100",
         462 => x"eff09fce",
         463 => x"63100502",
         464 => x"b70700f0",
         465 => x"23a20702",
         466 => x"23a20700",
         467 => x"e7800400",
         468 => x"13058995",
         469 => x"eff0df98",
         470 => x"6ff01ff8",
         471 => x"b7170010",
         472 => x"13063000",
         473 => x"938507a5",
         474 => x"13054100",
         475 => x"ef008018",
         476 => x"63100504",
         477 => x"93050000",
         478 => x"13057100",
         479 => x"eff05fad",
         480 => x"93773500",
         481 => x"13040500",
         482 => x"639a0712",
         483 => x"93058000",
         484 => x"eff09fb4",
         485 => x"37150010",
         486 => x"130545a5",
         487 => x"eff05f94",
         488 => x"03250400",
         489 => x"93058000",
         490 => x"eff01fb3",
         491 => x"6ff05ffa",
         492 => x"b7170010",
         493 => x"13063000",
         494 => x"938507a7",
         495 => x"13054100",
         496 => x"ef004013",
         497 => x"63180502",
         498 => x"93050100",
         499 => x"13057100",
         500 => x"eff01fa8",
         501 => x"93773500",
         502 => x"13040500",
         503 => x"6390070e",
         504 => x"03250100",
         505 => x"93050000",
         506 => x"eff09fa6",
         507 => x"2320a400",
         508 => x"6ff01ff6",
         509 => x"13063000",
         510 => x"93854ba7",
         511 => x"13054100",
         512 => x"ef00400f",
         513 => x"83474100",
         514 => x"1307e006",
         515 => x"63080508",
         516 => x"639ce70a",
         517 => x"93773400",
         518 => x"6392070a",
         519 => x"130c0404",
         520 => x"b71c0010",
         521 => x"371d0010",
         522 => x"930d80ff",
         523 => x"93058000",
         524 => x"13050400",
         525 => x"eff05faa",
         526 => x"13854ca5",
         527 => x"eff05f8a",
         528 => x"032a0400",
         529 => x"93058000",
         530 => x"930a8001",
         531 => x"13050a00",
         532 => x"eff09fa8",
         533 => x"13058da7",
         534 => x"eff09f88",
         535 => x"370b00ff",
         536 => x"33756a01",
         537 => x"33555501",
         538 => x"b3063501",
         539 => x"83c60600",
         540 => x"93f67609",
         541 => x"63800604",
         542 => x"938a8aff",
         543 => x"eff01f81",
         544 => x"135b8b00",
         545 => x"e39ebafd",
         546 => x"13044400",
         547 => x"13058995",
         548 => x"eff01f85",
         549 => x"e31c8cf8",
         550 => x"6ff09feb",
         551 => x"e38ce7f6",
         552 => x"93050000",
         553 => x"13057100",
         554 => x"eff09f9a",
         555 => x"13040500",
         556 => x"6ff05ff6",
         557 => x"1305e002",
         558 => x"6ff01ffc",
         559 => x"37150010",
         560 => x"130585a5",
         561 => x"6ff05fe5",
         562 => x"e3040ae8",
         563 => x"37150010",
         564 => x"1305c5a7",
         565 => x"6ff05fe4",
         566 => x"93070500",
         567 => x"03c70700",
         568 => x"93871700",
         569 => x"e31c07fe",
         570 => x"3385a740",
         571 => x"1305f5ff",
         572 => x"67800000",
         573 => x"630a0602",
         574 => x"1306f6ff",
         575 => x"13070000",
         576 => x"b307e500",
         577 => x"b386e500",
         578 => x"83c70700",
         579 => x"83c60600",
         580 => x"6398d700",
         581 => x"6306c700",
         582 => x"13071700",
         583 => x"e39207fe",
         584 => x"3385d740",
         585 => x"67800000",
         586 => x"13050000",
         587 => x"67800000",
         588 => x"0d0a5448",
         589 => x"55415320",
         590 => x"52495343",
         591 => x"2d562042",
         592 => x"6f6f746c",
         593 => x"6f616465",
         594 => x"72207630",
         595 => x"2e310d0a",
         596 => x"00000000",
         597 => x"3f0a0000",
         598 => x"0d0a0000",
         599 => x"3e200000",
         600 => x"68000000",
         601 => x"48656c70",
         602 => x"3a0d0a20",
         603 => x"68202020",
         604 => x"20202020",
         605 => x"20202020",
         606 => x"20202020",
         607 => x"202d2074",
         608 => x"68697320",
         609 => x"68656c70",
         610 => x"0d0a2072",
         611 => x"20202020",
         612 => x"20202020",
         613 => x"20202020",
         614 => x"20202020",
         615 => x"2d207275",
         616 => x"6e206170",
         617 => x"706c6963",
         618 => x"6174696f",
         619 => x"6e0d0a20",
         620 => x"7277203c",
         621 => x"61646472",
         622 => x"3e202020",
         623 => x"20202020",
         624 => x"202d2072",
         625 => x"65616420",
         626 => x"776f7264",
         627 => x"2066726f",
         628 => x"6d206164",
         629 => x"64720d0a",
         630 => x"20777720",
         631 => x"3c616464",
         632 => x"723e203c",
         633 => x"64617461",
         634 => x"3e202d20",
         635 => x"77726974",
         636 => x"65206461",
         637 => x"74612061",
         638 => x"74206164",
         639 => x"64720d0a",
         640 => x"20647720",
         641 => x"3c616464",
         642 => x"723e2020",
         643 => x"20202020",
         644 => x"20202d20",
         645 => x"64756d70",
         646 => x"20313620",
         647 => x"776f7264",
         648 => x"730d0a20",
         649 => x"6e202020",
         650 => x"20202020",
         651 => x"20202020",
         652 => x"20202020",
         653 => x"202d2064",
         654 => x"756d7020",
         655 => x"6e657874",
         656 => x"20313620",
         657 => x"776f7264",
         658 => x"73000000",
         659 => x"72000000",
         660 => x"72772000",
         661 => x"3a200000",
         662 => x"4e6f7420",
         663 => x"6f6e2034",
         664 => x"2d627974",
         665 => x"6520626f",
         666 => x"756e6461",
         667 => x"72792100",
         668 => x"77772000",
         669 => x"64772000",
         670 => x"20200000",
         671 => x"3f3f0000",
         672 => x"3c627265",
         673 => x"616b3e0d",
         674 => x"0a000000",
         675 => x"00202020",
         676 => x"20202020",
         677 => x"20202828",
         678 => x"28282820",
         679 => x"20202020",
         680 => x"20202020",
         681 => x"20202020",
         682 => x"20202020",
         683 => x"20881010",
         684 => x"10101010",
         685 => x"10101010",
         686 => x"10101010",
         687 => x"10040404",
         688 => x"04040404",
         689 => x"04040410",
         690 => x"10101010",
         691 => x"10104141",
         692 => x"41414141",
         693 => x"01010101",
         694 => x"01010101",
         695 => x"01010101",
         696 => x"01010101",
         697 => x"01010101",
         698 => x"10101010",
         699 => x"10104242",
         700 => x"42424242",
         701 => x"02020202",
         702 => x"02020202",
         703 => x"02020202",
         704 => x"02020202",
         705 => x"02020202",
         706 => x"10101010",
         707 => x"20000000",
         708 => x"00000000",
         709 => x"00000000",
         710 => x"00000000",
         711 => x"00000000",
         712 => x"00000000",
         713 => x"00000000",
         714 => x"00000000",
         715 => x"00000000",
         716 => x"00000000",
         717 => x"00000000",
         718 => x"00000000",
         719 => x"00000000",
         720 => x"00000000",
         721 => x"00000000",
         722 => x"00000000",
         723 => x"00000000",
         724 => x"00000000",
         725 => x"00000000",
         726 => x"00000000",
         727 => x"00000000",
         728 => x"00000000",
         729 => x"00000000",
         730 => x"00000000",
         731 => x"00000000",
         732 => x"00000000",
         733 => x"00000000",
         734 => x"00000000",
         735 => x"00000000",
         736 => x"00000000",
         737 => x"00000000",
         738 => x"00000000",
         739 => x"00000000",
         others => (others => '0')
        );

begin

    gen_bootrom: if HAVE_BOOT_ROM generate
        O_instruction_misaligned_error <= '0' when I_pc(1 downto 0) = "00" else '1';        

        -- ROM, for both instructions and read-only data
        process (I_clk, I_areset, I_pc, I_address, I_csboot, I_size, I_stall) is
        variable address_instr : integer range 0 to bootloader_size-1;
        variable address_data : integer range 0 to bootloader_size-1;
        variable instr_var : data_type;
        variable instr_recode : data_type;
        variable romdata_var : data_type;
        constant x : data_type := (others => 'X');
        begin
            -- Calculate addresses
            address_instr := to_integer(unsigned(I_pc(bootloader_size_bits-1 downto 2)));
            address_data := to_integer(unsigned(I_address(bootloader_size_bits-1 downto 2)));

            -- Quartus will detect ROM table and uses onboard RAM
            -- Do not use reset, otherwise ROM will be created with ALMs
            if rising_edge(I_clk) then
                if I_stall = '0' then
                    instr_var := bootrom(address_instr);
                end if;
                romdata_var := bootrom(address_data);
            end if;
            
            -- Recode instruction
            O_instr <= instr_var(7 downto 0) & instr_var(15 downto 8) & instr_var(23 downto 16) & instr_var(31 downto 24);
            
            O_load_misaligned_error <= '0';
            
            -- By natural size, for data
            if I_csboot = '1' then
                if I_size = size_word and I_address(1 downto 0) = "00" then
                    O_data_out <= romdata_var(7 downto 0) & romdata_var(15 downto 8) & romdata_var(23 downto 16) & romdata_var(31 downto 24);
                elsif I_size = size_halfword and I_address(1 downto 0) = "00" then
                    O_data_out <= x(31 downto 16) & romdata_var(23 downto 16) & romdata_var(31 downto 24);
                elsif I_size = size_halfword and I_address(1 downto 0) = "10" then
                    O_data_out <= x(31 downto 16) & romdata_var(7 downto 0) & romdata_var(15 downto 8);
                elsif I_size = size_byte then
                    case I_address(1 downto 0) is
                        when "00" => O_data_out <= x(31 downto 8) & romdata_var(31 downto 24);
                        when "01" => O_data_out <= x(31 downto 8) & romdata_var(23 downto 16);
                        when "10" => O_data_out <= x(31 downto 8) & romdata_var(15 downto 8);
                        when "11" => O_data_out <= x(31 downto 8) & romdata_var(7 downto 0);
                        when others => O_data_out <= x; O_load_misaligned_error <= '1';
                    end case;
                else
                    -- Chip select, but not aligned
                    O_data_out <= x;
                    O_load_misaligned_error <= '1';
                end if;
            else
                -- No chip select, so no data
                O_data_out <= x;
            end if;
        end process;
    end generate;

    gen_bootrom_not: if not HAVE_BOOT_ROM generate
        O_instruction_misaligned_error <= '0';
        O_load_misaligned_error <= '0';
        O_data_out <= (others => 'X');
        O_instr  <= (others => 'X');
    end generate;
end architecture rtl;
