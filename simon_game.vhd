library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity simon_game is
  port
  (
    clk                : in std_logic;
    p_btn              : in std_logic_vector(3 downto 0); -- 4 PMOD buttons
    start_btn, rst_btn : in std_logic; -- start/reset button
    dispSeg            : out std_logic_vector(7 downto 0) := (others => '0')
  );
end entity simon_game;

architecture rtl of simon_game is

  -- **  CONSTANTS ** -- 
  -- common constants
  constant addr_bus    : integer := 4; -- 4 address bits to store generated patterns
  constant data_bus    : integer := 4; -- 4 data bits to store input patterns
  constant max_pattern : integer := 15; -- 15 levels of difficulty
  constant clk_freq    : integer := 125000000; -- 125 MHz clock frequency

  -- ** SIGNALS ** -- 
  -- game specific signals 
  signal level       : integer := 0; -- current level of difficulty
  signal gen_pattern : std_logic_vector(data_bus - 1 downto 0); -- generated pattern
  signal seed        : std_logic_vector(7 downto 0) := "00000001"; -- seed for random generator

  -- control signals
  signal rst        : std_logic := '0'; -- reset signal
  signal pulse      : std_logic_vector(3 downto 0); -- debounced buttons and pulse signals
  signal start_game : std_logic;
  signal index      : integer := 0; -- index for memory access

  -- display signals
  signal disp_cntr     : integer := 0; -- display counter
  signal disp_data_reg : std_logic_vector(3 downto 0); -- display data register

  -- memory signals
  type mem_type is array(0 to max_pattern) of std_logic_vector(data_bus - 1 downto 0); -- memory type
  signal game_reg : mem_type; -- game memory register
  signal user_reg : mem_type; -- user memory register

  -- state machine signals
  type state_type is (idle, gen, display, input, check, win, lose); -- state type
  signal state : state_type := idle; -- state signal

  --  ** COMPONENT INSTANTIATION ** -- 
  -- debounce component
  component debounce is
    port
    (
      signal clk  : in std_logic;
      signal btn  : in std_logic;
      signal dbnc : out std_logic
    );
  end component debounce;

  -- pulse component (tie to PMOD if implemented)
  component pulse_detector is
    port
    (
      clk         : in std_logic;
      rst         : in std_logic;
      in_pulse    : in std_logic;
      detect_type : std_logic_vector(1 downto 0); -- default: rising edge, mapped below to falling edge
      out_pulse   : out std_logic
    );
  end component pulse_detector;

  -- random number generator component
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
  end component random_generator;

  -- vga display component
  --port
  --(
  --signal clk            : in std_logic;
  --signal en             : in std_logic;
  --signal hcount, vcount : out std_logic_vector(9 downto 0);
  --signal vid, hs, vs    : out std_logic := '1'
  --);

  -- pixel pusher component
begin

  -- ** MAPPING ** --
  -- debounce mapping
  dbnc_start_btn : debounce port map
    (clk => clk, btn => start_btn, dbnc => start_game);
  dbnc_rst_btn : debounce port
  map
  (clk => clk, btn => rst_btn, dbnc => rst);
  -- pulse mapping
  pulse_btn0 : pulse_detector port
  map
  (clk => clk, rst => rst, in_pulse => p_btn(0), detect_type => "01", out_pulse => pulse(0));
  pulse_btn1 : pulse_detector port
  map (clk => clk, rst => rst, in_pulse => p_btn(1), detect_type => "01", out_pulse => pulse(1));
  pulse_btn2 : pulse_detector port
  map (clk => clk, rst => rst, in_pulse => p_btn(2), detect_type => "01", out_pulse => pulse(2));
  pulse_btn3 : pulse_detector port
  map (clk => clk, rst => rst, in_pulse => p_btn(3), detect_type => "01", out_pulse => pulse(3));

  -- random number generator mapping
  random_gen : random_generator
  generic
  map
  (input_width => 8, output_width => data_bus)
  port
  map
  (clk => clk, rst => rst, seed => seed, rand_out => gen_pattern);
  -- ** PROCESS ** --

  -- Display Updater
  process (clk)
  begin

    if disp_data_reg = "1111" then -- user indication for input
      dispSeg <= (others => '1');
    elsif disp_data_reg(0) = '1' then -- display a 1
      dispSeg(0) <= '0';
      dispSeg(1) <= '1';
      dispSeg(2) <= '1';
      dispSeg(3) <= '0';
      dispSeg(4) <= '0';
      dispSeg(5) <= '0';
      dispSeg(6) <= '0';
    elsif disp_data_reg(1) = '1' then -- display a 2
      dispSeg(0) <= '1';
      dispSeg(1) <= '1';
      dispSeg(2) <= '0';
      dispSeg(3) <= '1';
      dispSeg(4) <= '1';
      dispSeg(5) <= '0';
      dispSeg(6) <= '1';
    elsif disp_data_reg(2) = '1' then -- display a 3
      dispSeg(0) <= '1';
      dispSeg(1) <= '1';
      dispSeg(2) <= '1';
      dispSeg(3) <= '1';
      dispSeg(4) <= '0';
      dispSeg(5) <= '0';
      dispSeg(6) <= '1';
    elsif disp_data_reg(3) = '1' then -- display a 4
      dispSeg(0) <= '0';
      dispSeg(1) <= '1';
      dispSeg(2) <= '1';
      dispSeg(3) <= '0';
      dispSeg(4) <= '0';
      dispSeg(5) <= '1';
      dispSeg(6) <= '1';
    else
      dispSeg <= (others => '0'); -- clear the display
    end if;

  end process;

  -- Seed Randomizer
  process (rst)
  begin
    if rst = '1' then
      -- shift seed to the left
      seed <= seed(6 downto 0) & seed(7);
    end if;
  end process;

  -- Simon Says state machine
  process (clk, start_game, rst)
  begin

    if rst = '1' then
      -- reset all signals
      state     <= idle; -- set state to idle
      level     <= 0; -- set level to 0
      index     <= 0; -- set index to 0
      disp_cntr <= 0; -- set display counter to 0
      -- reset memory registers
      game_reg      <= (others => (others => '0')); -- reset game memory register
      user_reg      <= (others => (others => '0')); -- reset user memory register
      disp_data_reg <= (others => '0'); -- reset display data register

    elsif rising_edge(clk) then -- on rising edge
      -- state machine
      case state is
        when idle => -- transition to generate state
          disp_cntr <= 0; -- set display counter to 0

          -- set all game signal values to 0
          level <= 0; -- set level to 0
          index <= 0; -- set index to 0
          -- reset memory registers
          game_reg <= (others => (others => '0')); -- reset game memory register
          user_reg <= (others => (others => '0')); -- reset user memory register
          -- once PMODs implemented, modify to have a start button
          if start_game = '1' then
            state <= gen;

          else
            state <= idle;
          end if;

        when gen => -- generate pattern
          -- generate pattern
          game_reg(level) <= gen_pattern; -- store generated pattern
          if level < max_pattern then -- if level is less than max pattern
            level <= level + 1; -- increment level
          else
            level <= max_pattern; -- set level to max pattern
          end if;
          state <= display; -- transition to display state

        when display => -- display pattern
          -- display pattern
          if disp_cntr = 0 then -- if display counter is 0
            disp_data_reg <= game_reg(index); -- load pattern to display
            index         <= index + 1; -- increment index

          elsif disp_cntr = (clk_freq / 2) - 1 then -- if display counter is half clock frequency
            disp_data_reg <= (others => '0'); -- clear display

          elsif disp_cntr = clk_freq - 1 then -- if display counter is clock frequency
            if index = level then -- if index is equal to level
              user_reg      <= (others => (others => '0')); -- reset user memory register
              disp_data_reg <= (others => '0'); -- clear display
              index         <= 0; -- reset index
              state         <= input; -- transition to input state
            end if;
          end if;

          -- incrementing display counter
          if disp_cntr < clk_freq - 1 then -- if display counter is clock frequency
            disp_cntr <= disp_cntr + 1; -- increment display counter
          else -- if display counter is not clock frequency
            disp_cntr <= 0; -- reset display counter
          end if;
        when input => -- input pattern

          --indicate it's user input time
          disp_data_reg <= (others => '1');
          if index = level then -- if index is equal to level
            state <= check; -- transition to check state
            index <= 0; -- reset index
          end if;

          if pulse(0) = '1' then -- if button 0 is pressed
            user_reg(index) <= "0001"; -- set user memory register to 0001
            index           <= index + 1; -- increment index
          elsif pulse(1) = '1' then -- if button 1 is pressed
            user_reg(index) <= "0010"; -- set user memory register to 0010
            index           <= index + 1; -- increment index
          elsif pulse(2) = '1' then -- if button 2 is pressed
            user_reg(index) <= "0100"; -- set user memory register to 0100
            index           <= index + 1; -- increment index
          elsif pulse(3) = '1' then -- if button 3 is pressed
            user_reg(index) <= "1000"; -- set user memory register to 1000
            index           <= index + 1; -- increment index
          end if;

        when check               => -- check pattern
          disp_data_reg <= (others => '0');
          if user_reg = game_reg then -- if user memory register is equal to game memory register
            if index = level - 1 then
              index     <= 0; -- reset index
              disp_cntr <= 0; -- reset display counter
              state     <= win; -- transition to win state
            else -- if index is not equal to level - 1
              index <= index + 1; -- increment index
            end if;
          else -- if user memory register is not equal to game memory register
            index     <= 0; -- reset index
            disp_cntr <= 0; -- reset display counter
            state     <= lose; -- transition to lose state
          end if;

        when win => -- win state

          if disp_cntr < clk_freq - 1 then -- if display counter is less than clock frequency - 1
            disp_cntr <= disp_cntr + 1; -- increment display counter
          else -- if display counter is not less than clock frequency - 1
            disp_cntr <= 0; -- reset display counter
            state     <= gen; -- transition to generate state
          end if;

        when lose => -- lose state
          -- need to indicate lose to user
          if disp_cntr < clk_freq - 1 then -- if display counter is less than clock frequency - 1
            disp_cntr <= disp_cntr + 1; -- increment display counter
          else -- if display counter is not less than clock frequency - 1
            disp_cntr <= 0; -- reset display counter
            state     <= idle; -- transition to idle state
          end if;
        when others => -- default
          state <= idle; -- set state to idle
      end case;
    end if;
  end process;
end architecture;