--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- riscv.vhd - Top level structural file

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity riscv is
    port ( clk : in std_logic;
           areset : in std_logic;
           datain : in data_type;
           dataout : out data_type
         );
end entity riscv;

architecture struct of riscv is

component regs is
    port (
        clk : in std_logic;
        areset : in std_logic;
        datain : in data_type;
        selrd  : in reg_type;
        enable : in std_logic;
        sel1out : in reg_type;
        sel2out : in reg_type;
        sel3out : in reg_type;
        sel4out : in reg_type;
        rs1out : out data_type;
        rs2out : out data_type;
        rs3out : out data_type;
        rs4out : out data_type
       );
end component regs;
component alu is
    port (
        alu_op : in alu_op_type;
        dataa : in data_type;
        datab : in data_type;
        immediate : in data_type;
        shift: in shift_type;
        pc : in data_type;
        memory : in data_type;
        result : out data_type
       );
end component alu;
component instruction_decoder is
    port (clk : in std_logic;
          areset : in std_logic;
          waitfordata : in std_logic;
          instr : in data_type;
          alu_op : out alu_op_type;
          rd : out reg_type;
          rd_enable : out std_logic;
          rs1 : out reg_type;
          rs2 : out reg_type;
          shift : out shift_type;
          immediate : out data_type;
          size : out size_type;
          offset : out data_type; 
          pc_op : out pc_op_type;
          memaccess : out memaccess_type;
          error : out std_logic
         );
end component instruction_decoder;
component rom is
    port (
        address1 : in data_type;
        address2 : in data_type;
        size2 : size_type;
        data1 : out data_type;
        data2: out data_type;
        error : out std_logic
    );
end component rom;
component pc is
    port (
        clk : in std_logic;
        areset : in std_logic;
        pc_op : in pc_op_type;
        rs : in data_type;
        offset : in data_type;
        branch : in std_logic;
        address : out data_type
       );
end component pc;
component address_decoder_and_data_router is
    port (rs : in data_type;
          offset : in data_type;
          romdatain : in data_type;
          ramdatain : in data_type;
          iodatain : in data_type;
          memaccess : memaccess_type;
          dataout : out data_type;
          wrram : out std_logic;
          wrio : out std_logic;
          addressout : out data_type;
          waitfordata : out std_logic;
          addresserror : out std_logic
   );
end component address_decoder_and_data_router;
component ram is
    port (
          clk : in std_logic;
          address : in data_type;
          datain : in data_type;
          size : in size_type;
          wren : in std_logic;
          dataout : out data_type;
          error : out std_logic
         );
end component ram;
component io is
    port (clk : in std_logic;
          areset : in std_logic;
          address : in data_type;
          size : size_type;
          wren : in std_logic;
          datain : in data_type;
          dataout : out data_type;
          -- connection with outside world
          datainfromoutside : in data_type;
          dataouttooutside : out data_type
         );
end component io;


signal areset_int : std_logic;
signal alu_op_int : alu_op_type;
signal shift_int : shift_type;
signal rd_int : reg_type;
signal rd_enable_int : std_logic;
signal rs1_int : reg_type;
signal rs2_int : reg_type;
signal rs3_int : reg_type;
signal rs4_int : reg_type;
signal immediate_int : data_type;
signal size_int : size_type;
signal offset_int: data_type;
signal pc_op_int : pc_op_type;
signal pc_int : data_type;
signal memaccess_int : memaccess_type;
signal result_int : data_type;
signal rs1data_int : data_type;
signal rs2data_int : data_type;
signal rs3data_int : data_type;
signal rs4data_int : data_type;
signal memory_int : data_type;
signal instr_int : data_type;
signal romdata_int : data_type;
signal ramdata_int : data_type;
signal iodata_int : data_type;
signal wrram_int : std_logic;
signal wrio_int : std_logic;
signal address_int : data_type;
signal waitfordata_int : std_logic;
begin

    -- Input push button is active low
    areset_int <= not areset;
    
    regs0 : regs
    port map (clk => clk,
              areset => areset_int,
              datain => result_int,
              selrd => rd_int,
              enable => rd_enable_int,
              sel1out => rs1_int,
              sel2out => rs2_int,
              sel3out => (others => '-'),
              sel4out => (others => '-'),
              rs1out => rs1data_int,
              rs2out => rs2data_int,
              rs3out => open,
              rs4out => open
    );

    alu0 : alu
    port map (alu_op => alu_op_int,
              dataa => rs1data_int,
              datab => rs2data_int,
              immediate => immediate_int,
              shift => shift_int,
              pc => pc_int,
              memory => memory_int,
              result => result_int
             );
             
    pc0 : pc
    port map (clk => clk,
              areset => areset_int,
              pc_op => pc_op_int,
              rs => rs1data_int,
              offset => offset_int,
              branch => result_int(0),
              address => pc_int
    );

    instruction_decoder0 : instruction_decoder
    port map (clk => clk,
              areset => areset_int,
              waitfordata => waitfordata_int,
              instr => instr_int,
              alu_op => alu_op_int,
              rd => rd_int,
              rd_enable => rd_enable_int,
              rs1 => rs1_int,
              rs2 => rs2_int,
              shift => shift_int,
              immediate => immediate_int,
              size => size_int,
              offset => offset_int, 
              pc_op => pc_op_int,
              memaccess => memaccess_int,
              error => open
             );
             
    rom0 : rom
    port map (address1 => pc_int,
              address2 => address_int,
              size2 => size_int,
              data1 => instr_int,
              data2 => romdata_int,
              error => open
    );
    
    addecroute0 : address_decoder_and_data_router
    port map (rs => rs1data_int,
              offset => offset_int,
              romdatain => romdata_int,
              ramdatain => ramdata_int,
              iodatain => iodata_int,
              memaccess => memaccess_int,
              dataout => memory_int,
              wrram => wrram_int,
              wrio => wrio_int,
              addressout => address_int,
              waitfordata => waitfordata_int,
              addresserror => open
    );

    ram0 : ram
    port map (
              clk => clk,
              address => address_int,
              datain => rs2data_int,
              size => size_int,
              wren => wrram_int,
              dataout => ramdata_int,
              error => open
    );
   
    io0 : io
    port map (
              clk => clk,
              areset => areset_int,
              address => address_int,
              size => size_int,
              wren => wrio_int,
              datain => rs2data_int,
              dataout => iodata_int,
              -- connection with outside world
              datainfromoutside => datain,
              dataouttooutside => dataout
             );              
    
end architecture struct;