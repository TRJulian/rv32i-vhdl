library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity sdp_ram_tb is
  generic (
    CLOCK_FREQUENCY_HZ : natural  := 10 ** 6;
    DATA_WIDTH         : positive := 8;
    ADDR_WIDTH         : positive := 8;
    MAX_REPORTS        : natural  := 20
  );
end entity sdp_ram_tb;

architecture tb of sdp_ram_tb is

  signal clk          : std_logic                                 := '0';
  signal write_enable : std_logic                                 := '0';
  signal write_addr   : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
  signal write_data   : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  signal read_addr    : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
  signal read_data    : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal clk_enable   : boolean                                   := true;

  constant CLOCK_PERIOD : time := 1000 ms / CLOCK_FREQUENCY_HZ;

  type dir_t is (ASCENDING, DESCENDING, DONT_CARE);

  type op_t is (READ0, READ1, WRITE0, WRITE1, NOOP);

  type test_name_t is (W0, AR0W1, AR1W0, DR0W1, DR1W0, R0);

  type test_element_t is record
    name      : test_name_t;
    direction : dir_t;
    op_1      : op_t;
    op_2      : op_t;
  end record test_element_t;

  type test_vec_array_t is array(natural range <>) of test_element_t;

  constant TESTS : test_vec_array_t :=
  (
    (
      name      => W0,
      direction => DONT_CARE,
      op_1      => WRITE0,
      op_2      => NOOP
    ),
    (
      name      => AR0W1,
      direction => ASCENDING,
      op_1      => READ0,
      op_2      => WRITE1
    ),
    (
      name      => AR1W0,
      direction => ASCENDING,
      op_1      => READ1,
      op_2      => WRITE0
    ),
    (
      name      => DR0W1,
      direction => DESCENDING,
      op_1      => READ0,
      op_2      => WRITE1
    ),
    (
      name      => DR1W0,
      direction => DESCENDING,
      op_1      => READ1,
      op_2      => WRITE0
    ),
    (
      name      => R0,
      direction => DONT_CARE,
      op_1      => READ0,
      op_2      => NOOP
    )
  );

begin

  assert DATA_WIDTH >= ADDR_WIDTH
    report "sdp_ram_tb: address-in-address requires DATA_WIDTH >= ADDR_WIDTH"
    severity failure;

  u_sdp_ram : entity work.sdp_ram(rtl)
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      ADDR_WIDTH => ADDR_WIDTH
    )
    port map (
      clk_i          => clk,
      write_enable_i => write_enable,
      write_addr_i   => write_addr,
      write_data_i   => write_data,
      read_addr_i    => read_addr,
      read_data_o    => read_data
    );

  clk_proc : process is
  begin

    if (clk_enable) then
      clk <= not clk;
      wait for CLOCK_PERIOD / 2;
    else
      wait;
    end if;

  end process clk_proc;

  stim_check_proc : process is

    variable addr          : natural;
    variable errors        : natural;
    variable check_counter : natural;

    procedure print_error (
      constant name_p     : in test_name_t;
      constant op_p       : in op_t;
      constant addr_p     : in natural;
      constant actual_p   : in std_logic_vector := read_data;
      constant expected_p : in std_logic_vector
    ) is
    begin

      errors := errors + 1;

      if (errors <= MAX_REPORTS) then
        report "FAIL"
               & " name=" & to_string(name_p)
               & " op=" & to_string(op_p)
               & " addr=" & to_string(addr_p)
               & " expected=" & to_string(expected_p)
               & " got=" & to_string(actual_p)
          severity error;
      elsif (errors = MAX_REPORTS + 1) then
        report "further failures suppressed..."
          severity note;
      end if;

    end procedure print_error;

    procedure exec_check_op (
      constant name_p     : in test_name_t;
      constant op_p       : in op_t;
      constant addr_vec_p : in std_logic_vector
    ) is

      variable pre_write_data : std_logic_vector(DATA_WIDTH - 1 downto 0);

    begin

      case op_p is

        when READ0 =>

          check_counter := check_counter + 1;

          read_addr  <= addr_vec_p;
          write_data <= not std_logic_vector(resize(unsigned(write_addr), DATA_WIDTH));
          wait for CLOCK_PERIOD;

          if (read_data /= std_logic_vector(resize(unsigned(addr_vec_p), DATA_WIDTH))) then
            print_error(name_p     => name_p, op_p => READ0, addr_p => to_integer(unsigned(addr_vec_p)),
                        expected_p => std_logic_vector(resize(unsigned(addr_vec_p), DATA_WIDTH)));
          end if;

        when READ1 =>

          check_counter := check_counter + 1;

          read_addr  <= addr_vec_p;
          write_data <= std_logic_vector(resize(unsigned(write_addr), DATA_WIDTH));
          wait for CLOCK_PERIOD;

          if (read_data /= not std_logic_vector(resize(unsigned(addr_vec_p), DATA_WIDTH))) then
            print_error(name_p     => name_p, op_p => READ1, addr_p => to_integer(unsigned(addr_vec_p)),
                        expected_p => not std_logic_vector(resize(unsigned(addr_vec_p), DATA_WIDTH)));
          end if;

        when WRITE0 =>

          write_enable <= '1';
          write_addr   <= addr_vec_p;
          write_data   <= std_logic_vector(resize(unsigned(addr_vec_p), DATA_WIDTH));

          if (read_addr = addr_vec_p) then
            check_counter  := check_counter + 1;
            pre_write_data := read_data;

            wait for CLOCK_PERIOD;
            if (read_data /= pre_write_data) then
              print_error(name_p => name_p, op_p => WRITE0,
                          addr_p => to_integer(unsigned(addr_vec_p)), expected_p => pre_write_data);
            end if;
          else
            wait for CLOCK_PERIOD;
          end if;

          write_enable <= '0';

        when WRITE1 =>

          write_enable <= '1';
          write_addr   <= addr_vec_p;
          write_data   <= not std_logic_vector(resize(unsigned(addr_vec_p), DATA_WIDTH));

          if (read_addr = addr_vec_p) then
            check_counter  := check_counter + 1;
            pre_write_data := read_data;

            wait for CLOCK_PERIOD;
            if (read_data /= pre_write_data) then
              print_error(name_p => name_p, op_p => WRITE1,
                          addr_p => to_integer(unsigned(addr_vec_p)), expected_p => pre_write_data);
            end if;
          else
            wait for CLOCK_PERIOD;
          end if;

          write_enable <= '0';

        when NOOP =>

          wait for CLOCK_PERIOD;

      end case;

    end procedure exec_check_op;

  begin

    errors        := 0;
    check_counter := 0;

    wait until falling_edge(clk);

    for i in TESTS'range loop

      for j in 0 to 2 ** ADDR_WIDTH - 1 loop

        if (TESTS(i).direction = DESCENDING) then
          addr       := 2 ** ADDR_WIDTH - 1 - j;
          write_addr <= std_logic_vector(to_unsigned(addr - 1, ADDR_WIDTH)) when (addr /= 0);
        else
          addr       := j;
          write_addr <= std_logic_vector(to_unsigned(addr + 1, ADDR_WIDTH)) when (addr /= 2 ** ADDR_WIDTH - 1);
        end if;

        wait for CLOCK_PERIOD;

        exec_check_op(name_p     => TESTS(i).name,
                      op_p       => TESTS(i).op_1,
                      addr_vec_p => std_logic_vector(to_unsigned(addr, ADDR_WIDTH)));

        exec_check_op(name_p     => TESTS(i).name,
                      op_p       => TESTS(i).op_2,
                      addr_vec_p => std_logic_vector(to_unsigned(addr, ADDR_WIDTH)));

      end loop;

    end loop;

    clk_enable <= false;

    if (errors = 0) then
      report "PASS: " & integer'image(check_counter) & " memory checks"
        severity note;
    else
      report integer'image(errors) & " total errors"
        severity failure;
    end if;

    wait;

  end process stim_check_proc;

end architecture tb;
