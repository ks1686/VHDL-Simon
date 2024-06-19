library ieee;
use ieee.std_logic_1164.all;

entity debounce_tb is
end debounce_tb;

architecture testbench of debounce_tb is

  signal tb_clk  : std_logic := '0';
  signal tb_btn  : std_logic;
  signal tb_dbnc : std_logic;

  component debounce is
    port
    (
      clk  : in std_logic;
      btn  : in std_logic;
      dbnc : out std_logic
    );
  end component;

begin
  clk : process
  begin
    wait for 4 ns;
    tb_clk <= '1';
    wait for 4 ns;
    tb_clk <= '0';
  end process;

  btn : process
  begin
    wait for 10 ms;
    tb_btn <= '1';
    wait for 30 ms;
    tb_btn <= '0';
  end process;

  dbnc : debounce
  port map
  (
    clk  => tb_clk,
    btn  => tb_btn,
    dbnc => tb_dbnc
  );
end testbench;