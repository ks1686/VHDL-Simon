library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity pulse_detector_tb is
end pulse_detector_tb;

architecture tb_arch of pulse_detector_tb is

  -- constants
  constant clk_period : time := 8 ns; -- 125 MHz

  -- signals
  signal clk, rst, in_pulse, out_pulse : std_logic                    := '0';
  signal detect_type                   : std_logic_vector(1 downto 0) := "00";

begin

  -- instantiate the unit under test 
  UUT : entity work.pulse_detector
    port map
    (
      clk         => clk,
      rst         => rst,
      in_pulse    => in_pulse,
      detect_type => detect_type,
      out_pulse   => out_pulse
    );

  -- clock process
  clk_process : process
  begin
    clk <= '0'; -- initial clk value
    wait for clk_period / 2; -- half period
    clk <= '1'; -- toggle clk
    wait for clk_period / 2; -- half period
  end process;

  -- stimulus process
  stim_proc : process
  begin
    -- test case 1: no pulse
    in_pulse <= '0'; -- initial in_pulse value
    wait for 50 ns; -- wait for 50 ns

    -- test case 2: rising edge pulse
    in_pulse <= '1'; -- set in_pulse to '1'
    wait for 8 ns; -- wait for 8 ns
    in_pulse <= '0'; -- set in_pulse to '0'
    wait for 50 ns; -- wait for 50 ns

    -- test case 3: falling edge pulse
    in_pulse <= '0'; -- set in_pulse to '0'
    wait for 8 ns; -- wait for 8 ns
    in_pulse <= '1'; -- set in_pulse to '1'
    wait for 8 ns; -- wait for 8 ns
    in_pulse <= '0'; -- set in_pulse to '0'
    wait for 50 ns; -- wait for 50 ns

    -- test case 4: level pulse 
    in_pulse <= '1'; -- set in_pulse to '1'
    wait for 50 ns; -- wait for 50 ns

  end process;
end architecture;