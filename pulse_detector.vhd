library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- a pulse detector with a synchronous reset; works in hand with debounce.vhd
entity pulse_detector is
  port
  (
    clk         : in std_logic;
    rst         : in std_logic;
    in_pulse    : in std_logic;
    detect_type : std_logic_vector(1 downto 0); -- default: rising edge
    out_pulse   : out std_logic
  );
end entity pulse_detector;

architecture rtl of pulse_detector is

  -- signal declarations
  signal ff1, ff2 : std_logic := '0'; -- flip-flops

begin

  process (clk, rst)
  begin
    if rst = '1' then
      ff1 <= '0'; -- reset
      ff2 <= '0'; -- reset
    elsif rising_edge(clk) then
      ff1 <= in_pulse; -- sample the input
      ff2 <= ff1; -- delay by one clock cycle
    end if;
  end process;

  with detect_type select
    out_pulse <= not ff2 and ff1 when "00", -- rising edge
    ff2 and not ff1 when "01", -- falling edge
    ff2 xor ff1 when "10", -- detect a pulse 
    '0' when others; -- detect a level

end architecture;