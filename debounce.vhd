library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity debounce is
  port
  (
    signal clk  : in std_logic;
    signal btn  : in std_logic;
    signal dbnc : out std_logic);
end debounce;

architecture Behavioral of debounce is
  signal shift_register : std_logic_vector(1 downto 0)  := (others => '0');
  signal counter        : std_logic_vector(21 downto 0) := (others => '0');

begin

  process (clk)
  begin
    if (rising_edge(clk)) then -- only on rising edge
      shift_register(0) <= btn; -- store the current value of the button
      shift_register(1) <= shift_register(0); -- store the previous value of the shift register
      if shift_register(1) = '1' then -- if the previous value of the shift register was high
        counter <= std_logic_vector(unsigned(counter) + 1); -- increment the counter
        if unsigned(counter) = 2500000 then -- if the counter has reached 2500000; 20ms stable time
          dbnc <= '1'; -- set the debounced signal high
        end if;
      else -- if the previous value of the shift register was low
        counter <= (others => '0'); -- reset the counter
        dbnc    <= '0'; -- set the debounced signal low
      end if;
    end if;
  end process;

end Behavioral;