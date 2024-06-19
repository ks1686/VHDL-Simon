library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity random_generator_tb is
end random_generator_tb;

architecture rtl of random_generator_tb is

  -- component under test
  component random_generator is
    generic
    (
      input_width  : integer := 8;
      output_width : integer := 4
    );
    port
    (
      clk, rst : in std_logic;
      seed     : in std_logic_vector(input_width - 1 downto 0);
      rand_out : out std_logic_vector(output_width - 1 downto 0)
    );
  end component;

  -- signal declaration
  signal clk, rst : std_logic                    := '0';
  signal seed     : std_logic_vector(7 downto 0) := (others => '0');
  signal rand_out : std_logic_vector(3 downto 0);

begin

  -- component instantiation
  uut : random_generator
  generic
  map
  (
  input_width  => 8, -- input width
  output_width => 4 -- output width
  )
  port map
  (
    clk      => clk,
    rst      => rst,
    seed     => seed,
    rand_out => rand_out
  );

  -- clock generation
  clk <= not clk after 4 ns;

  -- stimulus process
  stim_proc : process
  begin
    rst  <= '1'; -- reset
    seed <= "10101010"; -- seed
    wait for 8 ns; -- wait for 8 ns
    rst <= '0'; -- release resets
    wait for 100 ns; -- wait for 100 nss
    seed <= "01010101"; -- seed
    wait for 100 ns; -- wait for 100 ns
    wait;
  end process;

end architecture;