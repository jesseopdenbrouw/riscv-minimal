--
-- This file is part of the THUAS RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- io.vhd - Simple I/O register file (input/output, UART, TIME/TIMECMP)

-- This hardware description is for educational purposes only. 
-- This hardware description is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE.

-- The I/O consists of a single 32 bits input register and a
-- single 32 bit output register. There is no data direction
-- register. Furthermore the I/O has one UART with 7/8/9 data
-- bits, N/E/O parity and 1/2 stop bits. Several UART flags
-- are available. A simple timer TIMER1 is provided, has no
-- prescaler and generates an interrupt when the CMPT register
-- is equal to or greater than the TCNT register. The TIME and
-- TIMECMP registers are provided. 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity io is
    generic (freq_sys : integer := SYSTEM_FREQUENCY;
             freq_count : integer := CLOCK_FREQUENCY
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_csio : in std_logic;
          I_address : in data_type;
          I_size : size_type;
          I_wren : in std_logic;
          I_datain : in data_type;
          O_dataout : out data_type;
          O_load_misaligned_error : out std_logic;
          O_store_misaligned_error : out std_logic;
          -- Connection with outside world
          I_pina : in data_type;
          O_pouta : out data_type;
          I_RxD : in std_logic;
          O_TxD : out std_logic;
          -- Hardware interrupt request
          O_intrio : out data_type;
          -- TIME and TIMEH
          O_time : out data_type;
          O_timeh : out data_type
         );
end entity io;
    
architecture rtl of io is
-- Some local internal signals
signal io : io_type;
signal reg_int : integer range 0 to io_size-1;
--attribute keep: boolean;
--attribute keep of reg_int: signal is true;
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
type rxstate_type is (rx_idle, rx_wait, rx_iter, rx_parity, rx_parity2, rx_ready, rx_fail);
signal rxstate : rxstate_type;
signal rxbittimer : integer range 0 to 65535;
signal rxshiftcounter : integer range 0 to 15;
signal RxD_sync : std_logic;

-- Timer/Counters
constant timer1ctrl_addr : integer := 32;
constant timer1stat_addr : integer := 33;
constant timer1cntr_addr : integer := 34;
constant timer1cmpt_addr : integer := 35;
alias timer1ctrl_int : data_type is io(timer1ctrl_addr);
alias timer1stat_int : data_type is io(timer1stat_addr);
alias timer1cntr_int : data_type is io(timer1cntr_addr);
alias timer1cmpt_int : data_type is io(timer1cmpt_addr);

-- RISC-V system timer TIME and TIMECMP
constant time_addr : integer := 60;
constant timeh_addr : integer := 61;
constant timecmp_addr : integer := 62;
constant timecmph_addr : integer := 63;
alias time_int : data_type is io(time_addr);
alias timeh_int : data_type is io(timeh_addr);
alias timecmp_int : data_type is io(timecmp_addr);
alias timecmph_int : data_type is io(timecmph_addr);

begin

    -- Fetch internal register of io_size_bits bits minus 2
    -- because we will use word size only
    reg_int <= to_integer(unsigned(I_address(io_size_bits-1 downto 2)));
    
    -- Check if an access is on a 4-byte boundary AND is word size
    isword <= TRUE when I_size = size_word and I_address(1 downto 0) = "00" else FALSE;
    -- Misaligned error, when (not on a 4-byte boundary OR not word size) AND chip select
    O_store_misaligned_error <= '1' when isword = FALSE and I_csio = '1' and I_wren = '1' else '0';
    O_load_misaligned_error <= '1' when isword = FALSE and I_csio = '1' and I_wren = '0' else '0';
    
    -- Data out to ALU
    process (I_clk, I_areset) is --, io, isword, reg_int, I_csio, I_wren) is
    begin
        -- Only at word boundaries AND chip select
        if I_areset = '1' then
            O_dataout <= (others => '0');
        elsif rising_edge(I_clk) then
            if isword and I_csio = '1' and I_wren = '0' then
                case reg_int is
                    when pina_addr => O_dataout <= pina_int;
                    when pouta_addr => O_dataout <= pouta_int;
                    when usartdata_addr => O_dataout <= usartdata_int;
                    when usartbaud_addr => O_dataout <= usartbaud_int;
                    when usartctrl_addr => O_dataout <= usartctrl_int;
                    when usartstat_addr => O_dataout <= usartstat_int;
                    when timer1cntr_addr => O_dataout <= timer1cntr_int;
                    when timer1ctrl_addr => O_dataout <= timer1ctrl_int;
                    when timer1stat_addr => O_dataout <= timer1stat_int;
                    when timer1cmpt_addr => O_dataout <= timer1cmpt_int;
                    when time_addr => O_dataout <= time_int;
                    when timeh_addr => O_dataout <= timeh_int;
                    when timecmp_addr => O_dataout <= timecmp_int;
                    when timecmph_addr => O_dataout <= timecmph_int;
                    when others => O_dataout <= (others => '-');
                end case;
            end if;
        end if;
    end process;

    -- GPIO A pin en pout    
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            pina_int <= (others => '0');
            pouta_int <= (others => '0');
        elsif rising_edge(I_clk) then
            -- Read data in from outside world
            pina_int <= I_pina;
            -- Only write to I/O when write is enabled AND size is word
            -- Only write to the outputs, not the inputs
            -- Only write if on 4-byte boundary
            -- Only write when Chip Select (cs)
            if isword and I_csio = '1' and I_wren = '1' then
                if reg_int = pouta_addr then
                    pouta_int <= I_datain;
                end if;
            end if;
        end if;
    end process;
     -- Data to outside world
    O_pouta <= pouta_int;
    
    -- USART (well, really an UART)
    process (I_clk, I_areset) is
    variable txshiftcounter_var : integer range 0 to 15;
    begin
        -- Common resets et al.
        if I_areset = '1' then
            usartdata_int <= (others => '0');
            usartbaud_int <= (others => '0');
            usartctrl_int <= (others => '0');
            usartstat_int <= (others => '0');
            txstart <= '0';
            txstate <= tx_idle;
            txbuffer <= (others => '0');
            txbittimer <= 0;
            txshiftcounter <= 0;
            O_TxD <= '1';
            rxbuffer <= (others => '0');
            rxstate <= rx_idle;
            rxbittimer <= 0;
            rxshiftcounter <= 0;
            RxD_sync <= '1';
        elsif rising_edge(I_clk) then
            -- Default for start transmission
            txstart <= '0';
            -- Common register writes
            if isword and I_csio = '1' and I_wren = '1' then
                if reg_int = usartbaud_addr then
                    -- A write to the baud rate register
                    -- Use only 16 bits for baud rate
                    usartbaud_int(31 downto 16) <= (others => '0');
                    usartbaud_int(15 downto 0) <= I_datain(15 downto 0);
                elsif reg_int = usartctrl_addr then
                    -- A write to the control register
                    usartctrl_int <= I_datain;
                elsif reg_int = usartstat_addr then
                    -- A write to the status register
                    usartstat_int <= I_datain;
                elsif reg_int = usartdata_addr then
                    -- A write to the data register triggers a transmission
                    -- Signal start
                    txstart <= '1';
                    -- Load transmit buffer with 7/8/9 data bits, parity bit and
                    -- a start bit
                    -- Stop bits will be automatically added since the remaining
                    -- bits are set to 1. Most right bit is start bit.
                    txbuffer <= (others => '1');
                    if usartctrl_int(3 downto 2) = "10" then
                        -- 9 bits data
                        txbuffer(9 downto 0) <= I_datain(8 downto 0) & '0';
                        -- Have parity
                        if usartctrl_int(5) = '1' then
                            txbuffer(10) <= I_datain(8) xor I_datain(7) xor I_datain(6) xor I_datain(5) xor I_datain(4)
                                            xor I_datain(3) xor I_datain(2) xor I_datain(1) xor I_datain(0) xor usartctrl_int(4);
                        end if;
                    elsif usartctrl_int(3 downto 2) = "11" then
                        -- 7 bits data
                        txbuffer(7 downto 0) <= I_datain(6 downto 0) & '0';
                        -- Have parity
                        if usartctrl_int(5) = '1' then
                            txbuffer(8) <= I_datain(6) xor I_datain(5) xor I_datain(4) xor I_datain(3)
                                         xor I_datain(2) xor I_datain(1) xor I_datain(0) xor usartctrl_int(4);
                        end if;
                    else
                        -- 8 bits data
                        txbuffer(8 downto 0) <= I_datain(7 downto 0) & '0';
                        -- Have parity
                        if usartctrl_int(5) = '1' then
                            txbuffer(9) <= I_datain(7) xor I_datain(6) xor I_datain(5) xor I_datain(4) xor I_datain(3)
                                         xor I_datain(2) xor I_datain(1) xor I_datain(0) xor usartctrl_int(4);
                        end if;
                    end if;
                    -- Signal that we are sending
                    usartstat_int(4) <= '0'; 
                end if;
            end if;
            
            -- If data register is read...
            if isword and I_csio = '1' and I_wren = '0' then
                if reg_int = usartdata_addr then
                    -- Clear the received status bits
                    -- PE, RC, RF, FE
                    usartstat_int(3) <= '0';
                    usartstat_int(2) <= '0';
                    usartstat_int(1) <= '0';
                    usartstat_int(0) <= '0';
                end if;
            end if;
            
            -- Transmit a character
            case txstate is
                -- Tx idle state, wait for start
                when tx_idle =>
                    O_TxD <= '1';
                    -- If start triggered...
                    if txstart = '1' then
                        -- Load the prescaler, set the number of bits (including start bit)
                        txbittimer <= to_integer(unsigned(usartbaud_int));
                        if usartctrl_int(3 downto 2) = "10" then
                            txshiftcounter_var := 10;
                        elsif usartctrl_int(3 downto 2) = "11" then
                            txshiftcounter_var := 8;
                        else
                            txshiftcounter_var := 9;
                        end if;
                        -- Add up posibly parity bit and posibly second stop bit
                        txshiftcounter <= txshiftcounter_var + to_integer(unsigned(usartctrl_int(5 downto 5))) + to_integer(unsigned(usartctrl_int(0 downto 0)));
                        txstate <= tx_iter;
                    else
                        txstate <= tx_idle;
                    end if;
                -- Transmit the bits
                when tx_iter =>
                    -- Cycle trough all bits in the transmit buffer
                    -- First in line is the start bit
                    O_TxD <= txbuffer(0);
                    if txbittimer > 0 then
                        txbittimer <= txbittimer - 1;
                    elsif txshiftcounter > 0 then
                        txbittimer <= to_integer(unsigned(usartbaud_int));
                        txshiftcounter <= txshiftcounter - 1;
                        -- Shift in stop bit
                        txbuffer <= '1' & txbuffer(txbuffer'high downto 1);
                    else
                        txstate <= tx_ready;
                    end if;
                -- Signal ready
                when tx_ready =>
                    O_TxD <= '1';
                    txstate <= tx_idle;
                    -- Signal character transmitted
                    usartstat_int(4) <= '1'; 
                when others =>
                    O_TxD <= '1';
                    txstate <= tx_idle;
            end case;
            
            -- Receive character
            -- Input synchronizer
            RxD_sync <= I_RxD;
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
                            -- Set reception size
                            if usartctrl_int(3 downto 2) = "10" then
                                -- 9 bits
                                rxshiftcounter <= 9;
                            elsif usartctrl_int(3 downto 2) = "11" then
                                -- 7 bits
                                rxshiftcounter <= 7;
                            else
                                -- 8 bits
                                rxshiftcounter <= 8;
                            end if;
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
                        if usartctrl_int(3 downto 2) = "10" then
                            -- 9 bits
                            rxbuffer(8 downto 0) <= RxD_sync & rxbuffer(8 downto 1);
                        elsif usartctrl_int(3 downto 2) = "11" then
                            -- 7 bits
                            rxbuffer(6 downto 0) <= RxD_sync & rxbuffer(6 downto 1);
                        else
                            -- 8 bits
                            rxbuffer(7 downto 0) <= RxD_sync & rxbuffer(7 downto 1);
                        end if;
                    else
                        -- Do we have a parity bit?
                        if usartctrl_int(5) = '1' then
                            rxstate <= rx_parity;
                        else
                            rxstate <= rx_ready;
                        end if;
                    end if;
                -- Check parity, we already there...
                when rx_parity =>
                    if usartctrl_int(3 downto 2) = "10" then
                        usartstat_int(3) <= rxbuffer(8) xor rxbuffer(7) xor rxbuffer(6) xor rxbuffer(5)
                                            xor rxbuffer(4) xor rxbuffer(3) xor rxbuffer(2)
                                            xor rxbuffer(1) xor rxbuffer(0) xor RxD_sync;
                    elsif usartctrl_int(3 downto 2) = "11" then
                        usartstat_int(3) <= rxbuffer(6) xor rxbuffer(5)
                                            xor rxbuffer(4) xor rxbuffer(3) xor rxbuffer(2)
                                            xor rxbuffer(1) xor rxbuffer(0) xor RxD_sync;
                    else
                        usartstat_int(3) <= rxbuffer(7) xor rxbuffer(6) xor rxbuffer(5)
                                            xor rxbuffer(4) xor rxbuffer(3) xor rxbuffer(2)
                                            xor rxbuffer(1) xor rxbuffer(0) xor RxD_sync;
                    end if;
                    rxbittimer <= to_integer(unsigned(usartbaud_int));
                    rxstate <= rx_parity2;
                -- Wait to middle of stop bit
                when rx_parity2 =>
                    if rxbittimer > 0 then
                        rxbittimer <= rxbittimer - 1;
                    else
                        rxstate <= rx_ready;
                    end if;
                -- When ready, all bits are shifted in
                -- Even if we use two stop bits, we only check one and
                -- signal reception. This leave some computation time
                -- before the next reception occurs.
                when rx_ready =>
                    -- Test for a stray 0 in position of (first) stop bit
                    if RxD_sync = '0' then
                        -- Signal frame error
                        usartstat_int(0) <= '1';
                    end if;
                    -- Any way, copy the received data to the data register
                    usartdata_int <= (others => '0');
                    if usartctrl_int(3 downto 2) = "10" then
                        -- 9 bits
                        usartdata_int(8 downto 0) <= rxbuffer(8 downto 0);
                    elsif usartctrl_int(3 downto 2) = "11" then
                        -- 7 bits
                        usartdata_int(6 downto 0) <= rxbuffer(6 downto 0);
                    else
                        -- 8 bits
                        usartdata_int(8 downto 0) <= rxbuffer(8 downto 0);
                    end if;
                    -- signal reception
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
    
    -- TIMER1 - a very simple timer
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            timer1ctrl_int <= (others => '0');
            timer1stat_int <= (others => '0');
            timer1cntr_int <= (others => '0');
            timer1cmpt_int <= (others => '0');
        elsif rising_edge(I_clk) then
            if isword and I_csio = '1' and I_wren = '1' then
                -- Write Timer Control Register
                if reg_int = timer1ctrl_addr then
                    timer1ctrl_int <= I_datain;
                end if;
                -- Write Timer Status Register
                if reg_int = timer1stat_addr then
                    timer1stat_int <= I_datain;
                end if;
                -- Write Timer Counter Register
                if reg_int = timer1cntr_addr then
                    timer1cntr_int <= I_datain;
                end if;
                -- Write Timer Compare Register
                if reg_int = timer1cmpt_addr then
                    timer1cmpt_int <= I_datain;
                end if;
            end if;
            -- Set unused bits to 0
            timer1ctrl_int(31 downto 12) <= (others => '0');
            timer1stat_int(31 downto 12) <= (others => '0');
            
            -- If timer is enabled....
            if timer1ctrl_int(0) = '1' then
                -- If we hit the Compare Register T...
                if timer1cntr_int >= timer1cmpt_int then
                    -- Reload Counter Register
                    timer1cntr_int <= (others => '0');
                    -- Signal hit
                    timer1stat_int(4) <= '1';
                else
                    -- else, increment the Counter Register
                    timer1cntr_int <= std_logic_vector(unsigned(timer1cntr_int) + 1);
                end if;
            end if;
        end if;
    end process;
    
    -- RISC-V system timer TIME and TIMECMP
    -- These registers are memory mapped
    process (I_clk, I_areset) is
    variable time_reg : unsigned(63 downto 0);
    variable timecmp_reg : unsigned(63 downto 0);
    variable prescaler : integer range 0 to freq_sys/freq_count-1;
    begin
        if I_areset = '1' then
            time_reg := (others => '0');
            timecmp_reg := (others => '0');
            prescaler := 0;
        elsif rising_edge(I_clk) then
            if isword and I_csio = '1' and I_wren = '1' then
--                -- Load time (low 32 bits)
--                if reg_int = time_addr then
--                    time_reg(31 downto 0) := unsigned(datain);
--                end if;
--                -- Load timeh (high 32 bits)
--                if reg_int = timeh_addr then
--                    time_reg(63 downto 32) := unsigned(datain);
--                end if;
                -- Load compare register (low 32 bits)
                if reg_int = timecmp_addr then
                    timecmp_reg(31 downto 0) := unsigned(I_datain);
                end if;
                -- Load compare register (high 32 bits)
                if reg_int = timecmph_addr then
                    timecmp_reg(63 downto 32) := unsigned(I_datain);
                end if;
            end if;
            -- Update system timer
            if prescaler = freq_sys/freq_count-1 then
                prescaler := 0;
                time_reg := time_reg + 1;
            else
                prescaler := prescaler + 1;
            end if;
        end if;
        time_int <= std_logic_vector(time_reg(31 downto 0));
        timeh_int <= std_logic_vector(time_reg(63 downto 32));
        timecmp_int <= std_logic_vector(timecmp_reg(31 downto 0));
        timecmph_int <= std_logic_vector(timecmp_reg(63 downto 32));
        -- If compare register >= time register, assert interrupt
        if time_reg >= timecmp_reg then
            O_intrio(7) <= '1';
        else
            O_intrio(7) <= '0';
        end if;
        O_time <= time_int;
        O_timeh <= timeh_int;
    end process;
    
    -- Unused local interrupts set to 0
    O_intrio(31 downto 19) <= (others => '0');
    O_intrio(15 downto 8) <= (others => '0');
    O_intrio(6 downto 0) <= (others => '0');

    -- O_intrio(7) is set by the System Timer

    -- USART receive or transmit interrupt. Software must determine if it was
    -- receive or transmit or both
    O_intrio(18) <= '1' when (usartstat_int(4) = '1' and usartctrl_int(7) = '1') or
                             (usartstat_int(2) = '1' and usartctrl_int(6) = '1') else '0';
    -- TIMER1 compare match interrupt
    O_intrio(17) <= '1' when timer1ctrl_int(4) = '1' and timer1stat_int(4) = '1' else '0';
    -- This next interrupt is for testing only, will be removed
    O_intrio(16) <= '1' when pina_int(0) = '1' else '0';
    
    
end architecture rtl;