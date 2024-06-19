library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- random number generator
entity random_generator is
  generic
  (
    input_width  : integer := 8;
    output_width : integer := 4
  );
  port
  (
    clk      : in std_logic;
    rst      : in std_logic := '0';
    seed     : in std_logic_vector(input_width - 1 downto 0);
    rand_out : out std_logic_vector(output_width - 1 downto 0)
  );
end entity random_generator;

architecture rtl of random_generator is

  signal curr, ns : std_logic_vector(input_width - 1 downto 0) := x"01"; -- current and next state
  signal fb       : std_logic; -- feedback bit; randomizes  
begin

  -- feedback logic
  fb <= curr(0) xor curr(1) xor curr(2) xor curr(3); -- xor the first 4 bits

  -- next state logic
  ns <= fb & curr(input_width - 1 downto 1); -- shift left and add feedback

  -- state transition logic
  state_machine : process (clk, rst)
  begin
    if rst = '1' then
      curr <= seed; -- reset to seed
    elsif rising_edge(clk) then
      curr <= ns; -- update to ns state
    end if;
  end process state_machine;

  -- output logic (output set values based on generated number)
  rand_out <= "0001" when curr(input_width - 4) = '1' else
    "0010" when curr(input_width - 3) = '1' else
    "0100" when curr(input_width - 2) = '1' else
    "1000" when curr(input_width - 1) = '1' else
    "0001";

end architecture;