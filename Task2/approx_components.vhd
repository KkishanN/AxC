--------------------------------------------------------------------------------
-- Approximate Computing Components: Parametric Adders and Multipliers
-- AxC Course 2026 - Paderborn University
-- Author: Kishan Nadageri
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
-- 1. Approximate 32-bit Adder with Configurable LSB and MSB Bit-Truncation
--------------------------------------------------------------------------------
entity approx_adder is
    generic (
        DATA_WIDTH : integer := 32;
        TRUNC_LSB  : integer := 0; -- Number of truncated lower bits (0 to 8)
        TRUNC_MSB  : integer := 0  -- Number of truncated upper bits (0 to 8)
    );
    port (
        a   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        b   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        sum : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity approx_adder;

architecture behavioral of approx_adder is
begin
    process(a, b)
        variable full_sum : unsigned(DATA_WIDTH-1 downto 0);
        variable res      : unsigned(DATA_WIDTH-1 downto 0);
    begin
        full_sum := unsigned(a) + unsigned(b);
        res := full_sum;

        -- Zero out truncated LSB bits (pruning lower carry-propagation logic)
        if TRUNC_LSB > 0 and TRUNC_LSB < DATA_WIDTH then
            res(TRUNC_LSB-1 downto 0) := (others => '0');
        end if;

        -- Mask/truncate upper MSB bits if configured
        if TRUNC_MSB > 0 and TRUNC_MSB < DATA_WIDTH then
            res(DATA_WIDTH-1 downto DATA_WIDTH-TRUNC_MSB) := (others => '0');
        end if;

        sum <= std_logic_vector(res);
    end process;
end architecture behavioral;

--------------------------------------------------------------------------------
-- 2. Approximate 32-bit Multiplier with Configurable LSB/MSB Bit-Truncation
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity approx_multiplier is
    generic (
        DATA_WIDTH : integer := 32;
        TRUNC_LSB  : integer := 0; -- Truncate partial products on LSB (0 to 8)
        TRUNC_MSB  : integer := 0  -- Truncate partial products on MSB (0 to 8)
    );
    port (
        a       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        b_coeff : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        prod    : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity approx_multiplier;

architecture behavioral of approx_multiplier is
begin
    process(a, b_coeff)
        variable full_prod : unsigned(63 downto 0);
        variable res       : unsigned(DATA_WIDTH-1 downto 0);
    begin
        full_prod := unsigned(a) * unsigned(b_coeff);
        -- Extract lower 32-bit word (carry/overflow ignored as per specification)
        res := full_prod(DATA_WIDTH-1 downto 0);

        -- LSB bit truncation (reduces partial product matrix columns)
        if TRUNC_LSB > 0 and TRUNC_LSB < DATA_WIDTH then
            res(TRUNC_LSB-1 downto 0) := (others => '0');
        end if;

        -- MSB bit truncation
        if TRUNC_MSB > 0 and TRUNC_MSB < DATA_WIDTH then
            res(DATA_WIDTH-1 downto DATA_WIDTH-TRUNC_MSB) := (others => '0');
        end if;

        prod <= std_logic_vector(res);
    end process;
end architecture behavioral;
