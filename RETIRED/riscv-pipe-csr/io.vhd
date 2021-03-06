--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2021, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- io.vhd - Simple I/O register file (input/output, UART)

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

entity io is
    port (clk : in std_logic;
          areset : in std_logic;
          csio : in std_logic;
          address : in data_type;
          size : size_type;
          wren : in std_logic;
          datain : in data_type;
          dataout : out data_type;
          -- connection with outside world
          pina : in data_type;
          pouta : out data_type;
          TxD : out std_logic;
          RxD : in std_logic
         );
end entity io;
    
architecture rtl of io is
-- Some local internal signals
signal io : io_type;
signal reg_int : integer range 0 to io_size-1;
signal isword : boolean;

-- Port input and output
constant pina_addr : integer := 0;
constant pouta_addr : integer := 1;
alias pina_int : data_type is io(pina_addr);
alias pouta_int : data_type is io(pouta_addr);

-- USART
constant usartdata_addr : integer := 8;
constant usartbaud_addr : integer := 9;
constant usartctrl_addr : integer := 10;
constant usartstat_addr : integer := 11;
alias usartdata_int : data_type is io(usartdata_addr);
alias usartbaud_int : data_type is io(usartbaud_addr);
alias usartctrl_int : data_type is io(usartctrl_addr);
alias usartstat_int : data_type is io(usartstat_addr);
-- Transmit signals
signal txbuffer : data_type;
signal txstart : std_logic;
type txstate_type is (tx_idle, tx_iter, tx_ready);
signal txstate : txstate_type;
signal txbittimer : integer range 0 to 65535;
signal txshiftcounter : integer range 0 to 15;
--Receive signals
signal rxbuffer : data_type;
type rxstate_type is (rx_idle, rx_wait, rx_iter, rx_ready, rx_fail);
signal rxstate : rxstate_type;
signal rxbittimer : integer range 0 to 65535;
signal rxshiftcounter : integer range 0 to 15;
signal RxD_sync : std_logic;
begin

    -- Fetch internal register of io_size_bits bits minus 2
    -- because we will use word size only
    reg_int <= to_integer(unsigned(address(io_size_bits-1 downto 2)));
    
    -- Check if an access is on a 4-byte boundary AND is word size
    isword <= TRUE when size = size_word and address(1 downto 0) = "00" else FALSE;
    
    -- Data out to ALU
    process (io, isword, reg_int, csio) is
    begin
        -- Only at word boundaries AND chip select
        if isword and csio = '1' then
            dataout <= io(reg_int);
        else
            dataout <= (others => 'X');
        end if;
    end process;

    -- GPIO A pin en pout    
    process (clk, areset) is
    begin
        if areset = '1' then
            pina_int <= (others => '0');
            pouta_int <= (others => '0');
        elsif rising_edge(clk) then
            -- Read data in from outside world
            pina_int <= pina;
            -- Only write to I/O when write is enabled AND size is word
            -- Only write to the outputs, not the inputs
            -- Only write if on 4-byte boundary
            -- Only write when Chip Select (cs)
            if wren = '1' and isword and csio = '1' then
                if reg_int = pouta_addr then
                    pouta_int <= datain;
                end if;
            end if;
        end if;
    end process;
     -- Data to outside world
    pouta <= pouta_int;
    
    -- USART (well, really an UART)
    process (clk, areset) is
    begin
        -- Common resets et al.
        if areset = '1' then
            usartdata_int <= (others => '0');
            usartbaud_int <= (others => '0');
            usartctrl_int <= (others => '0');
            usartstat_int <= (others => '0');
            txstart <= '0';
            txstate <= tx_idle;
            txbuffer <= (others => '0');
            txbittimer <= 0;
            TxD <= '1';
            rxbuffer <= (others => '0');
            rxstate <= rx_idle;
            rxbittimer <= 0;
            rxshiftcounter <= 0;
            RxD_sync <= '1';
        elsif rising_edge(clk) then
            -- Default for start transmission
            txstart <= '0';
            -- Common register writes
            if wren = '1' and isword and csio = '1' then
                if reg_int = usartbaud_addr then
                    -- A write to the baud rate register
                    -- Use only 16 bits for baud rate
                    usartbaud_int <= (others => '0');
                    usartbaud_int(15 downto 0) <= datain(15 downto 0);
                elsif reg_int = usartctrl_addr then
                    -- A write to the control register
                    usartctrl_int <= datain;
                elsif reg_int = usartstat_addr then
                    -- A write to the status register
                    usartstat_int <= datain;
                elsif reg_int = usartdata_addr then
                    -- A write to the data register triggers a transmission
                    -- Signal start
                    txstart <= '1';
                    -- Load transmit buffer with 8 data bits and a start bit
                    -- Stop bits will be automatically added since the remaining
                    -- bits are set to 1. Most right bit is start bit.
                    txbuffer <= (others => '1');
                    txbuffer(8 downto 0) <= datain(7 downto 0) & '0';
                    -- Signal that we are sending
                    usartstat_int(4) <= '0'; 
                end if;
            end if;
            
            -- If data register is read
            if wren = '0' and isword and csio = '1' then
                if reg_int = usartdata_addr then
                    -- Clear the received status bits
                    usartstat_int(2) <= '0';
                    usartstat_int(1) <= '0';
                    usartstat_int(0) <= '0';
                end if;
            end if;
            
            -- Transmit a character
            case txstate is
                -- Tx idle state, wait for start
                when tx_idle =>
                    TxD <= '1';
                    -- If start triggered...
                    if txstart = '1' then
                        -- Load the prescaler, set the number of bits (including start bit)
                        txbittimer <= to_integer(unsigned(usartbaud_int));
                        -- Test for one or two stop bits
                        if usartctrl_int(0) = '1' then
                            txshiftcounter <= 10;
                        else
                            txshiftcounter <= 9;
                        end if;
                        txstate <= tx_iter;
                    else
                        txstate <= tx_idle;
                    end if;
                -- Transmit the bits
                when tx_iter =>
                    -- Cycle trough all bits in the transmit buffer
                    -- First in line is the start bit
                    TxD <= txbuffer(0);
                    if txbittimer > 0 then
                        txbittimer <= txbittimer - 1;
                    elsif txshiftcounter > 0 then
                        txbittimer <= to_integer(unsigned(usartbaud_int));
                        txshiftcounter <= txshiftcounter - 1;
                        txbuffer <= '1' & txbuffer(31 downto 1);
                    else
                        txstate <= tx_ready;
                    end if;
                -- Signal ready
                when tx_ready =>
                    TxD <= '1';
                    txstate <= tx_idle;
                    -- Signal character transmitted
                    usartstat_int(4) <= '1'; 
                when others =>
                    TxD <= '1';
                    txstate <= tx_idle;
            end case;
            
            -- Receive character
            -- Input synchronizer
            RxD_sync <= RxD;
            case rxstate is
                -- Rx idle, wait for start bit
                when rx_idle =>
                    -- If detected a start bit ...
                    if RxD_sync = '0' then
                        -- Set half bit time ...
                        rxbittimer <= to_integer(unsigned(usartbaud_int))/2;
                        rxstate <= rx_wait;
                    else
                        rxstate <= rx_idle;
                    end if;
                -- Hunt for start bit, check start bit at half bit time
                when rx_wait =>
                    if rxbittimer > 0 then
                        rxbittimer <= rxbittimer - 1;
                    else
                        -- At half bit time...
                        -- Start bit is still 0, so continue
                        if RxD_sync = '0' then
                            rxbittimer <= to_integer(unsigned(usartbaud_int));
                            rxshiftcounter <= 8;
                            rxbuffer <= (others => '0');
                            rxstate <= rx_iter;
                        else
                            -- Start bit is not 0, so invalid transmission
                            rxstate <= rx_fail;
                        end if;
                    end if;
                -- Shift in the data bits
                -- We sample in the middle of a bit time...
                when rx_iter =>
                    if rxbittimer > 0 then
                        -- Bit timer not finished, so keep counting...
                        rxbittimer <= rxbittimer - 1;
                    elsif rxshiftcounter > 0 then
                        -- Bit counter not finished, so restart timer and shift in data bit
                        rxbittimer <= to_integer(unsigned(usartbaud_int));
                        rxshiftcounter <= rxshiftcounter - 1;
                        rxbuffer(7 downto 0) <= RxD_sync & rxbuffer(7 downto 1);
                    else
                        rxstate <= rx_ready;
                    end if;
                -- When ready, all bits are shifted in
                -- Even if we use two stop bits, we only check one and
                -- signal reception. This leave some computation time
                -- before the next reception occurs.
                when rx_ready =>
                    -- Test for a stray 0 in position of start bit
                    if RxD_sync = '0' then
                        -- Signal frame error
                        usartstat_int(0) <= '1';
                    end if;
                    -- Anyway, copy the received data to the data register
                    usartdata_int <= (others => '0');
                    usartdata_int(7 downto 0) <= rxbuffer(7 downto 0);
                    usartstat_int(2) <= '1';
                    rxstate <= rx_idle;
                -- Wrong start bit detected, no data present
                when rx_fail =>
                    -- Failed to receive a correct start bit...
                    rxstate <= rx_idle;
                    usartstat_int(1) <= '1';
                when others =>
                    rxstate <= rx_idle;
            end case;
        end if;
    end process;
    
end architecture rtl;
      
