library ieee;
use ieee.std_logic_1164.all;

entity fadd_tb is 
end fadd_tb;

architecture sim of fadd_tb is
    component fadd 
        port(
            a, b, ci: in std_logic; 
            o, co: out std_logic
        ); 
    end component;
    
    signal a, b, ci, o, co : std_logic;
begin
    -- Instantiate DUT (Design Under Test)
    dut: fadd port map(a=>a, b=>b, ci=>ci, o=>o, co=>co);
    
    -- Stimulus process
    stim: process
    begin
        -- Test Case 1: 0 + 0 + 0 = 0 (carry 0)
        a<='0'; b<='0'; ci<='0'; 
        wait for 10 ns;
        assert (o='0' and co='0') report "Test 0+0+0 FAILED" severity error;
        
        -- Test Case 2: 1 + 1 + 0 = 0 (carry 1)
        a<='1'; b<='1'; ci<='0'; 
        wait for 10 ns;
        assert (o='0' and co='1') report "Test 1+1+0 FAILED" severity error;
        
        -- Stop simulation
        wait; 
    end process;
end sim;
