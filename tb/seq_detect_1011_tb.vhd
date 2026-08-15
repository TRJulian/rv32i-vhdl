library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity seq_detect_1011_tb is
  generic (
    CLOCK_FREQUENCY_HZ : positive := 10 ** 6;
    SEQUENCE_LENGTH    : positive := 12;
    MAX_REPORTS        : positive := 20
  );
end entity seq_detect_1011_tb;

architecture tb of seq_detect_1011_tb is

  signal clk    : std_logic := '0';
  signal rst    : std_logic := '0';
  signal d      : std_logic := '0';
  signal enable : boolean   := true;
  signal match  : std_logic := '0';

  constant CLOCK_PERIOD : time := 1000 ms / CLOCK_FREQUENCY_HZ;

begin

  u_seq_detect_1011 : entity work.seq_detect_1011(rtl)
    port map (
      d_i     => d,
      clk_i   => clk,
      rst_i   => rst,
      match_o => match
    );

  clk_proc : process is
  begin

    if (enable) then
      clk <= not clk;
      wait for CLOCK_PERIOD / 2;
    else
      wait;
    end if;

  end process clk_proc;

  test_proc : process is

    variable errors           : natural;
    variable failed           : boolean;
    variable sequence_counter : natural;
    variable test_sequence    : std_logic_vector(0 to SEQUENCE_LENGTH - 1);
    variable prev_4_sequence  : std_logic_vector(0 to 3);
    variable expected         : std_logic;

  begin

    errors           := 0;
    sequence_counter := 0;

    for i in 0 to 2 ** SEQUENCE_LENGTH - 1 loop

      d   <= '0';
      rst <= '1';

      wait for CLOCK_PERIOD;

      if (match /= '0') then
        errors := errors + 1;
        if (errors <= MAX_REPORTS) then
          report "FAIL (RST)"
                 & " expected=0"
                 & " got=" & to_string(match)
            severity error;
        elsif (errors = MAX_REPORTS + 1) then
          report "further failures suppressed..."
            severity note;
        end if;
      end if;

      rst             <= '0';
      test_sequence   := std_logic_vector(to_unsigned(i, SEQUENCE_LENGTH));
      prev_4_sequence := "0000";

      for k in test_sequence'range loop

        wait until falling_edge(clk);
        d               <= test_sequence(k);
        prev_4_sequence := prev_4_sequence(1 to 3) & test_sequence(k);
        expected        := '1' when prev_4_sequence = "1011" else '0';
        failed          := false;
        wait for CLOCK_PERIOD;

        if (match /= expected) then
          failed := true;
        end if;

        if (failed) then
          errors := errors + 1;
          if (errors <= MAX_REPORTS) then
            report "FAIL"
                   & " test_sequence=" & to_string(test_sequence)
                   & " bit_index=" & integer'image(k)
                   & " prev_4_sequence=" & to_string(prev_4_sequence)
                   & " expected=" & to_string(expected)
                   & " got=" & to_string(match)
              severity error;
          elsif (errors = MAX_REPORTS + 1) then
            report "further failures suppressed..."
              severity note;
          end if;
        end if;

      end loop;

      sequence_counter := sequence_counter + 1;

    end loop;

    enable <= false;

    if (errors = 0) then
      report "PASS: all possible " & integer'image(sequence_counter) & " "
             & integer'image(SEQUENCE_LENGTH) & "-bit sequences"
        severity note;
    else
      report integer'image(errors) & " total errors"
        severity failure;
    end if;

    wait;

  end process test_proc;

end architecture tb;
