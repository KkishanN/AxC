library ieee;
use ieee.std_logic_1164.all;

entity fadd is
    port (
        a, b, ci : in std_logic;
        o, co : out std_logic
    );
end entity fadd;

architecture rtl of fadd is
begin
    o <= a xor b xor ci;
    co <= (a and b) or (ci and (a xor b));
end rtl;
