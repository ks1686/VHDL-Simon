library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top_level_tb is
end entity top_level_tb;

architecture tb_arch of top_level_tb is

  -- ** Constants ** --
  constant clk_period : time := 8 ns;

  -- ** Signals ** --
  signal clk                : std_logic                    := '0';
  signal tb_btn             : std_logic_vector(3 downto 0) := "0000";
  signal start_sig, rst_sig : std_logic                    := '0';
  signal dispSeg_tb         : std_logic_vector(7 downto 0) := (others => '0');

  -- ** Components ** --
  component top_level
    port
    (
      clk                : in std_logic;
      p_btn              : in std_logic_vector(3 downto 0); -- 4 PMOD buttons
      start_btn, rst_btn : in std_logic; -- start/reset button
      dispSeg            : out std_logic_vector(7 downto 0) := (others => '0')
    );
  end component top_level;
begin

  -- ** DUT ** --
  DUT : top_level
  port map
  (
    clk       => clk,
    p_btn     => tb_btn,
    dispSeg   => dispSeg_tb,
    start_btn => start_sig,
    rst_btn   => rst_sig
  );

  -- clock process
  clk_process : process
  begin
    clk <= '0'; -- initial clk
    wait for clk_period/2; -- half period
    clk <= '1'; -- change clk
    wait for clk_period/2; -- half period
  end process;

  -- stimulus process
  stimulus : process
  begin
    wait for 30 ns; -- wait for start signal
    start_sig <= '1'; -- start
    wait for 25 ms; -- db
    start_sig <= '0';
    rst_sig   <= '1'; -- reset test
    wait for 25 ms; -- db
    rst_sig   <= '0';
    start_sig <= '1'; -- start
    wait for 25 ms; -- db
    start_sig <= '0';
    wait for 1200 ms; -- generate pattern and display, then move to user input

    -- start the game, change test input as needed
    tb_btn(0) <= '1';
    wait for 25 ms;
    tb_btn(0) <= '0';
    wait for 3000 ms;

    -- test an incorrect input, put a wrong input
    tb_btn(0) <= '1';
    wait for 25 ms;
    tb_btn(0) <= '0';
    tb_btn(2) <= '1';
    wait for 25 ms;
    tb_btn(2) <= '0';
    wait for 2000ms;
    start_sig <= '1';

    wait; -- watch the new generated starting number

  end process;
end architecture;