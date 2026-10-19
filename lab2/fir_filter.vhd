--------------------------------------------------------------------------------
-- 10-Stage Approximate FIR Filter (Pipelined Architecture)
-- Approximate Computing (AxC)
-- Author: Kishan Nadageri
--
-- Specifications:
--   Inputs: 1 32-bit number (std_logic_vector)
--   Output: 1 32-bit number (std_logic_vector)
--   Constants:
--     b0 = b9 = 3
--     b1 = b8 = 25
--     b2 = b7 = 96
--     b3 = b6 = 384
--     b4 = b5 = 3073
--   Constraints:
--     Clock cycle: 1.0 ns
--     Throughput: 1 result per cycle
--     Latency: <= 3 cycles
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_filter is
    generic (
        DATA_WIDTH : integer := 32;
        -- Configurable bit truncation per stage for approximate synthesis
        MUL0_TRUNC_LSB : integer := 0;
        MUL1_TRUNC_LSB : integer := 0;
        MUL2_TRUNC_LSB : integer := 0;
        MUL3_TRUNC_LSB : integer := 0;
        MUL4_TRUNC_LSB : integer := 0;
        MUL5_TRUNC_LSB : integer := 0;
        MUL6_TRUNC_LSB : integer := 0;
        MUL7_TRUNC_LSB : integer := 0;
        MUL8_TRUNC_LSB : integer := 0;
        MUL9_TRUNC_LSB : integer := 0;
        
        ADD0_TRUNC_LSB : integer := 0;
        ADD1_TRUNC_LSB : integer := 0;
        ADD2_TRUNC_LSB : integer := 0;
        ADD3_TRUNC_LSB : integer := 0;
        ADD4_TRUNC_LSB : integer := 0;
        ADD5_TRUNC_LSB : integer := 0;
        ADD6_TRUNC_LSB : integer := 0;
        ADD7_TRUNC_LSB : integer := 0;
        ADD8_TRUNC_LSB : integer := 0
    );
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        x_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        y_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity fir_filter;

architecture rtl of fir_filter is

    -- Constant Coefficients defined in specification
    constant B0 : std_logic_vector(DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(3, DATA_WIDTH));
    constant B1 : std_logic_vector(DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(25, DATA_WIDTH));
    constant B2 : std_logic_vector(DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(96, DATA_WIDTH));
    constant B3 : std_logic_vector(DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(384, DATA_WIDTH));
    constant B4 : std_logic_vector(DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(3073, DATA_WIDTH));
    constant B5 : std_logic_vector(DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(3073, DATA_WIDTH));
    constant B6 : std_logic_vector(DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(384, DATA_WIDTH));
    constant B7 : std_logic_vector(DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(96, DATA_WIDTH));
    constant B8 : std_logic_vector(DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(25, DATA_WIDTH));
    constant B9 : std_logic_vector(DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(3, DATA_WIDTH));

    -- Shift register for past inputs x[n-k]
    type shift_reg_type is array(0 to 9) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal x_reg : shift_reg_type := (others => (others => '0'));

    -- Multiplier outputs
    type prod_array_type is array(0 to 9) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal prod_comb : prod_array_type;
    signal prod_pipe : prod_array_type := (others => (others => '0'));

    -- Pipelined Adder Tree signals (Latency = 3 cycles total)
    -- Stage 1: 5 parallel pairwise sums
    type sum_tree_l1_type is array(0 to 4) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sum_l1_comb : sum_tree_l1_type;
    signal sum_l1_pipe : sum_tree_l1_type := (others => (others => '0'));

    -- Stage 2: 2 parallel sums + 1 passthrough
    signal sum_l2_0, sum_l2_1 : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sum_l2_0_pipe, sum_l2_1_pipe, sum_l2_2_pipe : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    -- Stage 3: Final accumulation
    signal final_sum_a, final_sum_b : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal y_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    -- Approximate Component Declarations
    component approx_multiplier is
        generic (
            DATA_WIDTH : integer := 32;
            TRUNC_LSB  : integer := 0;
            TRUNC_MSB  : integer := 0
        );
        port (
            a       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            b_coeff : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            prod    : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;

    component approx_adder is
        generic (
            DATA_WIDTH : integer := 32;
            TRUNC_LSB  : integer := 0;
            TRUNC_MSB  : integer := 0
        );
        port (
            a   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            b   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            sum : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;

begin

    ----------------------------------------------------------------------------
    -- 1. Input Shift Register (Pipeline Stage 0)
    ----------------------------------------------------------------------------
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            x_reg <= (others => (others => '0'));
        elsif rising_edge(clk) then
            x_reg(0) <= x_in;
            for i in 1 to 9 loop
                x_reg(i) <= x_reg(i-1);
            end loop;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 2. Multiplier Array (10 Parallel Multipliers)
    ----------------------------------------------------------------------------
    m0: approx_multiplier generic map (DATA_WIDTH, MUL0_TRUNC_LSB, 0) port map (x_reg(0), B0, prod_comb(0));
    m1: approx_multiplier generic map (DATA_WIDTH, MUL1_TRUNC_LSB, 0) port map (x_reg(1), B1, prod_comb(1));
    m2: approx_multiplier generic map (DATA_WIDTH, MUL2_TRUNC_LSB, 0) port map (x_reg(2), B2, prod_comb(2));
    m3: approx_multiplier generic map (DATA_WIDTH, MUL3_TRUNC_LSB, 0) port map (x_reg(3), B3, prod_comb(3));
    m4: approx_multiplier generic map (DATA_WIDTH, MUL4_TRUNC_LSB, 0) port map (x_reg(4), B4, prod_comb(4));
    m5: approx_multiplier generic map (DATA_WIDTH, MUL5_TRUNC_LSB, 0) port map (x_reg(5), B5, prod_comb(5));
    m6: approx_multiplier generic map (DATA_WIDTH, MUL6_TRUNC_LSB, 0) port map (x_reg(6), B6, prod_comb(6));
    m7: approx_multiplier generic map (DATA_WIDTH, MUL7_TRUNC_LSB, 0) port map (x_reg(7), B7, prod_comb(7));
    m8: approx_multiplier generic map (DATA_WIDTH, MUL8_TRUNC_LSB, 0) port map (x_reg(8), B8, prod_comb(8));
    m9: approx_multiplier generic map (DATA_WIDTH, MUL9_TRUNC_LSB, 0) port map (x_reg(9), B9, prod_comb(9));

    -- Register products for Stage 1 Pipeline Boundary
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            prod_pipe <= (others => (others => '0'));
        elsif rising_edge(clk) then
            prod_pipe <= prod_comb;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 3. Pipelined Adder Tree (Stage 1: Pairwise Additions)
    ----------------------------------------------------------------------------
    a0: approx_adder generic map (DATA_WIDTH, ADD0_TRUNC_LSB, 0) port map (prod_pipe(0), prod_pipe(1), sum_l1_comb(0));
    a1: approx_adder generic map (DATA_WIDTH, ADD1_TRUNC_LSB, 0) port map (prod_pipe(2), prod_pipe(3), sum_l1_comb(1));
    a2: approx_adder generic map (DATA_WIDTH, ADD2_TRUNC_LSB, 0) port map (prod_pipe(4), prod_pipe(5), sum_l1_comb(2));
    a3: approx_adder generic map (DATA_WIDTH, ADD3_TRUNC_LSB, 0) port map (prod_pipe(6), prod_pipe(7), sum_l1_comb(3));
    a4: approx_adder generic map (DATA_WIDTH, ADD4_TRUNC_LSB, 0) port map (prod_pipe(8), prod_pipe(9), sum_l1_comb(4));

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            sum_l1_pipe <= (others => (others => '0'));
        elsif rising_edge(clk) then
            sum_l1_pipe <= sum_l1_comb;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 4. Pipelined Adder Tree (Stage 2: Reduction)
    ----------------------------------------------------------------------------
    a5: approx_adder generic map (DATA_WIDTH, ADD5_TRUNC_LSB, 0) port map (sum_l1_pipe(0), sum_l1_pipe(1), sum_l2_0);
    a6: approx_adder generic map (DATA_WIDTH, ADD6_TRUNC_LSB, 0) port map (sum_l1_pipe(2), sum_l1_pipe(3), sum_l2_1);

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            sum_l2_0_pipe <= (others => '0');
            sum_l2_1_pipe <= (others => '0');
            sum_l2_2_pipe <= (others => '0');
        elsif rising_edge(clk) then
            sum_l2_0_pipe <= sum_l2_0;
            sum_l2_1_pipe <= sum_l2_1;
            sum_l2_2_pipe <= sum_l1_pipe(4);
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 5. Final Stage Accumulation (Latency = 3 cycles total)
    ----------------------------------------------------------------------------
    a7: approx_adder generic map (DATA_WIDTH, ADD7_TRUNC_LSB, 0) port map (sum_l2_0_pipe, sum_l2_1_pipe, final_sum_a);
    a8: approx_adder generic map (DATA_WIDTH, ADD8_TRUNC_LSB, 0) port map (final_sum_a, sum_l2_2_pipe, final_sum_b);

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            y_reg <= (others => '0');
        elsif rising_edge(clk) then
            y_reg <= final_sum_b;
        end if;
    end process;

    y_out <= y_reg;

end architecture rtl;
