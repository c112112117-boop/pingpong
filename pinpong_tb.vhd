
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pingpong_tb is
end pingpong_tb;

architecture Behavioral of pingpong_tb is

    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';

    signal sw_r  : std_logic := '0';
    signal sw_l  : std_logic := '0';

    signal led_r : std_logic_vector(7 downto 0);

begin

    -- 100 MHz clock
    clk <= not clk after 5 ns;

    -- Device Under Test
    uut: entity work.top

        generic map (
            DEBOUNCE_MAX => 10,
            MOVE_MAX     => 1000
        )

        port map (
            clk   => clk,
            rst   => rst,
            sw_r  => sw_r,
            sw_l  => sw_l,
            led_r => led_r
        );


    ------------------------------------------------
    -- Test Sequence
    ------------------------------------------------
    process
    begin

        -- Reset
        rst <= '1';
        wait for 100 ns;
        rst <= '0';

        -- Wait for LED to reach right side
        wait for 81 us;

        -- Right player presses
        sw_r <= '1';
        wait for 500 ns;
        sw_r <= '0';

        -- Wait for LED to reach left side
        wait for 80 us;

        -- Left player presses
        sw_l <= '1';
        wait for 500 ns;
        sw_l <= '0';

        -- Wait for next movement
        wait for 100 us;

        -- Test right player again
        sw_r <= '1';
        wait for 500 ns;
        sw_r <= '0';

        -- Observe
        wait for 100 us;

        wait;

    end process;

end Behavioral;
