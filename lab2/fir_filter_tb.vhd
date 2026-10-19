--------------------------------------------------------------------------------
-- Testbench for 10-Stage FIR Filter (Exact vs Approximate Verification)
-- Approximate Computing (AxC)
-- Author: Kishan Nadageri
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_filter_tb is
end entity fir_filter_tb;

architecture sim of fir_filter_tb is

    constant CLK_PERIOD : time := 1.0 ns; -- 1.0 ns clock constraint
    constant DATA_WIDTH : integer := 32;

    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal x_in  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal y_out : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    -- Instantiate Device Under Test (DUT)
    dut: entity work.fir_filter
        generic map (
            DATA_WIDTH => 32,
            MUL0_TRUNC_LSB => 2,
            MUL1_TRUNC_LSB => 2,
            MUL2_TRUNC_LSB => 0,
            MUL3_TRUNC_LSB => 0,
            MUL4_TRUNC_LSB => 0,
            MUL5_TRUNC_LSB => 0,
            MUL6_TRUNC_LSB => 0,
            MUL7_TRUNC_LSB => 0,
            MUL8_TRUNC_LSB => 2,
            MUL9_TRUNC_LSB => 2,
            ADD0_TRUNC_LSB => 1,
            ADD1_TRUNC_LSB => 0,
            ADD2_TRUNC_LSB => 0,
            ADD3_TRUNC_LSB => 0,
            ADD4_TRUNC_LSB => 0,
            ADD5_TRUNC_LSB => 0,
            ADD6_TRUNC_LSB => 0,
            ADD7_TRUNC_LSB => 0,
            ADD8_TRUNC_LSB => 0
        )
        port map (
            clk   => clk,
            rst_n => rst_n,
            x_in  => x_in,
            y_out => y_out
        );

    -- Clock Generation (1.0 GHz = 1.0 ns period)
    clk_process: process
    begin
        while now < 100 ns loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Stimulus Generation: Feeding input samples in range [0, 255]
    stim_process: process
    begin
        rst_n <= '0';
        wait for 2 ns;
        rst_n <= '1';
        wait for 1 ns;

        -- Test impulse response
        x_in <= std_logic_vector(to_unsigned(100, DATA_WIDTH));
        wait for CLK_PERIOD;
        x_in <= std_logic_vector(to_unsigned(200, DATA_WIDTH));
        wait for CLK_PERIOD;
        x_in <= std_logic_vector(to_unsigned(50, DATA_WIDTH));
        wait for CLK_PERIOD;
        x_in <= std_logic_vector(to_unsigned(128, DATA_WIDTH));
        wait for CLK_PERIOD;
        x_in <= std_logic_vector(to_unsigned(75, DATA_WIDTH));
        wait for CLK_PERIOD;
        x_in <= std_logic_vector(to_unsigned(220, DATA_WIDTH));
        wait for CLK_PERIOD;
        x_in <= std_logic_vector(to_unsigned(15, DATA_WIDTH));
        wait for CLK_PERIOD;

        wait for 20 ns;
        report "Simulation completed successfully!" severity note;
        wait;
    end process;

end architecture sim;
