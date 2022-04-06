--
-- This file is part of the RISC-V Minimal Project
--
-- (c)2022, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
--
-- md.vhd - The Multiply and Divide Unit

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

entity md is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_start : in std_logic;
          I_op : in std_logic_vector(2 downto 0);
          I_rs1 : in data_type;
          I_rs2 : in data_type;
          O_ready : out std_logic;
          O_mul_rd : out data_type;
          O_div_rd : out data_type
         );
end entity md;

-- This architecture uses a 1-bit at-the-time divider, so
-- each division takes 32+2 clock pulses. The multiplier
-- takes 3 clock pulses.
architecture rtl of md is

-- The signals of the multiplier
signal rdata_a, rdata_b : unsigned(32 downto 0);
signal rddata : unsigned(63 downto 0);
signal mul_rd_int : signed(65 downto 0);
signal mul_running : std_logic;
signal mul_ready : std_logic;

-- The signals of the divider
signal buf : unsigned(63 downto 0);
signal divisor : unsigned(31 downto 0);
signal quotient : unsigned(31 downto 0);
signal remainder : unsigned(31 downto 0);
-- synthesis translate_off
signal count: integer range 0 to 32;
-- synthesis translate_on
signal outsign : std_logic;
signal div_ready : std_logic;

constant all_zeros : std_logic_vector(31 downto 0) := (others => '0');
 
alias buf1 is buf(63 downto 32); 
alias buf2 is buf(31 downto 0); 

begin

    -- Check start of multiplication and load registers
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            rdata_a <= (others => '0');
            rdata_b <= (others => '0');
            mul_running <= '0';
        elsif rising_edge(I_clk) then
            -- Clock in the multiplicand and multiplier
            -- In the Cyclone V, these are embedded registers
            -- in the DSP units.
            if I_op(1) = '1' then
                if I_op(0) = '1' then
                    rdata_a <= '0' & unsigned(I_rs1);
                else
                    rdata_a <= I_rs1(31) & unsigned(I_rs1);
                end if;
                rdata_b <= '0' & unsigned(I_rs2);
            else
                rdata_a <= I_rs1(31) & unsigned(I_rs1);
                rdata_b <= I_rs2(31) & unsigned(I_rs2);
            end if;
            -- Only start when start seen and multiply
            mul_running <= I_start and not I_op(2);
        end if;
    end process;

    -- Do the multiplication
    process(I_clk, I_areset) is
    begin
        if I_areset = '1' then
            mul_rd_int <= (others => '0');
            mul_ready <= '0';
        elsif rising_edge (I_clk) then
            -- Do the multiplication and store in embedded registers
            mul_rd_int <= signed(rdata_a) * signed(rdata_b);
            mul_ready <= mul_running;
        end if;
    end process;
    
    -- Output multiplier result
    process (mul_rd_int, I_op) is
    begin
        if I_op(1) = '1' or I_op(0) = '1' then
            O_mul_rd <= std_logic_vector(mul_rd_int(63 downto 32));
        else
            O_mul_rd <= std_logic_vector(mul_rd_int(31 downto 0));
        end if;
    end process;
    
    -- Check start of division, load registers and do the division
    process (I_clk, I_areset)
    variable div_running : std_logic;  
    variable count_int : integer range 0 to 32;
    begin 
        if I_areset = '1' then
            -- Reset everything
            count_int := 0;
            buf1 <= (others => '0');
            buf2 <= (others => '0');
            divisor <= (others => '0');
            div_running := '0';
            div_ready <= '0';
            outsign <= '0';
        elsif rising_edge(I_clk) then 
            -- If start and dividing...
            div_ready <= '0';
            if I_start = '1' and I_op(2) = '1' then
                div_running := '1';
                count_int := 0;
            end if;
            if div_running = '1' then
                case count_int is 
                when 0 => 
                    buf1 <= (others => '0');
                    -- If signed divide, check for negative
                    -- value and make it positive
                    if I_op(0) = '0' and I_rs1(31) = '1' then
                        buf2 <= unsigned(not I_rs1) + 1;
                    else
                        buf2 <= unsigned(I_rs1);
                    end if;
                    if I_op(0) = '0' and I_rs2(31) = '1' then
                        divisor <= unsigned(not I_rs2) + 1;
                    else
                        divisor <= unsigned(I_rs2); 
                    end if;
                    count_int := count_int + 1; 
                    div_ready <= '0';
                    -- Determine the result sign
                    if (I_op(0) = '0' and I_op(1) = '0' and (I_rs1(31) /= I_rs2(31)) and I_rs2 /= all_zeros) or (I_op(0) = '0' and I_op(1) = '1' and I_rs1(31) = '1') then
                        outsign <= '1';
                    else
                        outsign <= '0';
                    end if;

                when others =>
                    -- Do the division
                    if buf(62 downto 31) >= divisor then 
                        buf1 <= '0' & (buf(61 downto 31) - divisor(30 downto 0)); 
                        buf2 <= buf2(30 downto 0) & '1'; 
                    else 
                        buf <= buf(62 downto 0) & '0'; 
                    end if;
                    -- Do this 32 times, last one outputs the result
                    if count_int /= 32 then 
                        count_int := count_int + 1;
                    else
                        -- Signal ready
                        count_int := 0;
                        div_running := '0';
                        div_ready <= '1';
                    end if; 
                end case; 
            end if; 
        end if;
-- synthesis translate_off
        -- Only to view in simulator
        count <= count_int;
-- synthesis translate_on
    end process;
    
    -- Select the correct signedness of the results
    process (outsign, buf2, buf1) is
    begin
        if outsign = '1' then
            quotient <= not buf2 + 1;
            remainder <= not buf1 + 1;
        else
            quotient <= buf2;
            remainder <= buf1; 
        end if;
    end process;

    -- Select the divider output
    O_div_rd <= std_logic_vector(remainder) when I_op(1) = '1' else std_logic_vector(quotient);
    
    -- Signal that we are ready
    O_ready <= div_ready or mul_ready;

end architecture rtl;


-- This architecture uses a 2-bit at-the-time divider, so
-- each division takes 16+2 clock pulses. The multiplier
-- takes 3 clock pulses.
architecture rtl_div4 of md is

-- The signals of the multiplier
signal rdata_a, rdata_b : unsigned(32 downto 0);
signal rddata : unsigned(63 downto 0);
signal mul_rd_int : signed(65 downto 0);
signal mul_running : std_logic;
signal mul_ready : std_logic;

-- The buffer contains the dividend and the quotient and is
-- used along the division operation.
signal buf: unsigned(63 downto 0);
-- The divisor times 1, 2 and 3
signal divisor1: unsigned(33 downto 0);
signal divisor2: unsigned(33 downto 0);
signal divisor3: unsigned(33 downto 0);
-- The quotient, simple signal only
signal quotient : unsigned(31 downto 0);
-- The remainder, simple signal only
signal remainder : unsigned(31 downto 0);
-- To keep track of the number of iterations
-- synthesis translate_off
signal count : integer range 0 to 16;
-- synthesis translate_on
-- The sign of the quotient and the remainder
signal outsign : std_logic;
-- Signal ready
signal div_ready : std_logic;

-- All 32 bits zero for comparison
constant all_zeros : std_logic_vector(31 downto 0) := (others => '0');

-- Buf1 is part of the the dividend during the process,
-- contains the remainder when the division is ready
alias buf1 is buf(63 downto 32);
-- Buf2 is the dividend part when starting, quotient
-- bit are shifted in.
alias buf2 is buf(31 downto 0);

begin

    -- Check start of multiplication and load registers
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            rdata_a <= (others => '0');
            rdata_b <= (others => '0');
            mul_running <= '0';
        elsif rising_edge(I_clk) then
            -- Clock in the multiplicand and multiplier
            -- In the Cyclone V, these are embedded registers
            -- in the DSP units.
            if I_op(1) = '1' then
                if I_op(0) = '1' then
                    rdata_a <= '0' & unsigned(I_rs1);
                else
                    rdata_a <= I_rs1(31) & unsigned(I_rs1);
                end if;
                rdata_b <= '0' & unsigned(I_rs2);
            else
                rdata_a <= I_rs1(31) & unsigned(I_rs1);
                rdata_b <= I_rs2(31) & unsigned(I_rs2);
            end if;
            -- Only start when start seen and multiply
            mul_running <= I_start and not I_op(2);
        end if;
    end process;

    -- Do the multiplication
    process(I_clk, I_areset) is
    begin
        if I_areset = '1' then
            mul_rd_int <= (others => '0');
            mul_ready <= '0';
        elsif rising_edge (I_clk) then
            -- Do the multiplication and store in embedded registers
            mul_rd_int <= signed(rdata_a) * signed(rdata_b);
            mul_ready <= mul_running;
        end if;
    end process;
    
    -- Output multiplier result
    process (mul_rd_int, I_op) is
    begin
        if I_op(1) = '1' or I_op(0) = '1' then
            O_mul_rd <= std_logic_vector(mul_rd_int(63 downto 32));
        else
            O_mul_rd <= std_logic_vector(mul_rd_int(31 downto 0));
        end if;
    end process;
    
    -- The main divider process. The divider retires 2 bits
    -- at a time, hence 16 cycles are needed. We use a
    -- poor man's radix-4 subtraction unit. It is not the
    -- fastest hardware but the easiest to follow. Consider
    -- a SRT radix-4 divider.
    process (I_clk, I_areset)
    variable div_running : std_logic;
    variable count_int : integer range 0 to 16;
    begin 
        if I_areset = '1' then
            -- Reset everything
            count_int := 0;
            buf1 <= (others => '0');
            buf2 <= (others => '0');
            divisor1 <= (others => '0');
            divisor2 <= (others => '0');
            divisor3 <= (others => '0');
            div_running := '0';
            div_ready <= '0';
            outsign <= '0';
        elsif rising_edge(I_clk) then 
            -- If start and dividing...
            div_ready <= '0';
            if I_start = '1' and I_op(2) = '1' then
                -- Signal that we are running
                div_running := '1';
                -- For restarting the division
                count_int := 0;
            end if;
            if div_running = '1' then
                case count_int is 
                    when 0 =>
                        buf1 <= (others => '0');
                        -- If signed divide, check for negative
                        -- value and make it positive
                        if I_op(0) = '0' and I_rs1(31) = '1' then
                            buf2 <= unsigned(not I_rs1) + 1;
                        else
                            buf2 <= unsigned(I_rs1);
                        end if;
                        -- Load the divisor x1, divisor x2 and divisor x3
                        if I_op(0) = '0' and I_rs2(31) = '1' then
                            divisor1 <= "00" & (unsigned(not I_rs2) + 1);
                            divisor2 <= ("0" & (unsigned(not I_rs2) + 1) & "0");
                            divisor3 <= ("0" & (unsigned(not I_rs2) + 1) & "0") + ("00" & (unsigned(not I_rs2) + 1));
--                            divisor2 <= ("00" & (unsigned(not I_rs2) + 1)) + ("00" & (unsigned(not I_rs2) + 1));
--                            divisor3 <= ("00" & (unsigned(not I_rs2) + 1)) + ("00" & (unsigned(not I_rs2) + 1)) + ("00" & (unsigned(not I_rs2) + 1));
                        else
                            divisor1 <= ("00" & unsigned(I_rs2));
                            divisor2 <= ("0" & unsigned(I_rs2) & "0");
                            divisor3 <= ("0" & unsigned(I_rs2) & "0") + ("00" & unsigned(I_rs2));
--                            divisor2 <= ("00" & unsigned(I_rs2)) + ("00" & unsigned(I_rs2));
--                            divisor3 <= ("00" & unsigned(I_rs2)) + ("00" & unsigned(I_rs2)) + ("00" & unsigned(I_rs2));
                        end if;
                        count_int := count_int + 1;
                        div_ready <= '0';
                        -- Determine the sign of the quotient and remainder
                        if (I_op(0) = '0' and I_op(1) = '0' and (I_rs1(31) /= I_rs2(31)) and I_rs2 /= all_zeros) or (I_op(0) = '0' and I_op(1) = '1' and I_rs1(31) = '1') then
                            outsign <= '1';
                        else
                            outsign <= '0';
                        end if;
                    when others =>
                        -- Do the divide
                        -- First check is divisor x3 can be subtracted...
                        if buf(63 downto 30) >= divisor3 then
                            buf1(63 downto 32) <= buf(61 downto 30) - divisor3(31 downto 0);
                            buf2 <= buf2(29 downto 0) & "11";
                        -- Then check is divisor x2 can be subtracted...
                        elsif buf(63 downto 30) >= divisor2 then
                            buf1(63 downto 32) <= buf(61 downto 30) - divisor2(31 downto 0);
                            buf2 <= buf2(29 downto 0) & "10";
                        -- Then check is divisor x1 can be subtracted...
                        elsif buf(63 downto 30) >= divisor1 then
                            buf1(63 downto 32) <= buf(61 downto 30) - divisor1(31 downto 0);
                            buf2 <= buf2(29 downto 0) & "01";
                       -- Else no subtraction can be performed.
                        else
                            -- Shift in 0 (00)
                            buf <= buf(61 downto 0) & "00";
                        end if;
                        -- Do this 16 times (32 bit/2 bits at a time, output in last cycle)
                        if count_int /= 16 then
                            count_int := count_int + 1;
                        else
                            -- Ready, show the result
                            count_int := 0;
                            div_running := '0';
                            div_ready <= '1';
                        end if;
                end case;
            end if;
        end if;
-- synthesis translate_off
        count <= count_int;
-- synthesis translate_on
    end process;
    
    -- Select the signedness of the quotient and remainder
    process (outsign, buf2, buf1) is
    begin
        if outsign = '1' then
            quotient <= not buf2 + 1;
            remainder <= not buf1 + 1;
        else
            quotient <= buf2;
            remainder <= buf1;
        end if;
    end process;
    
    -- Select the quotient and remainder
    O_div_rd <= std_logic_vector(remainder) when I_op(1) = '1' else std_logic_vector(quotient);
    
    -- Signal that we are ready
    O_ready <= div_ready or mul_ready;

end architecture rtl_div4;
