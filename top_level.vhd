library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top_level is
  port
  (
    clk                : in std_logic;
    p_btn              : in std_logic_vector(3 downto 0); -- 4 PMOD buttons
    start_btn, rst_btn : in std_logic; -- start/reset button
    dispSeg            : out std_logic_vector(7 downto 0) := (others => '0')
  );
end entity top_level;
architecture rtl of top_level is

  -- * Component Declarations * --
  component simon_game is
    port
    (
      clk                : in std_logic;
      p_btn              : in std_logic_vector(3 downto 0); -- 4 PMOD buttons
      start_btn, rst_btn : in std_logic; -- start/reset button
      dispSeg            : out std_logic_vector(7 downto 0) := (others => '0')
    );
  end component simon_game;

begin
  -- * Component Instantiations * --
  simon_game_inst : simon_game
  port map
  (
    clk       => clk,
    p_btn     => p_btn,
    start_btn => start_btn,
    rst_btn   => rst_btn,
    dispSeg   => dispSeg
  );

end architecture;