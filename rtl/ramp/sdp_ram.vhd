library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;

-- Implemented separate write and read addresses.
-- When write enable is asserted and the read address equals the write address, read data presents the pre-write
-- contents of that location.
-- The return of uninitialized reads is undefined. Once-written locations will always return non-metavalues.
-- No reset was included because block RAM contents cannot be reset.

entity sdp_ram is
  generic (
    DATA_WIDTH : positive := 8;
    ADDR_WIDTH : positive := 8;
    INIT_FILE  : string   := ""
  );
  port (
    clk_i          : in    std_logic;
    write_enable_i : in    std_logic;
    write_addr_i   : in    std_logic_vector(ADDR_WIDTH - 1 downto 0);
    write_data_i   : in    std_logic_vector(DATA_WIDTH - 1 downto 0);
    read_addr_i    : in    std_logic_vector(ADDR_WIDTH - 1 downto 0);
    read_data_o    : out   std_logic_vector(DATA_WIDTH - 1 downto 0)
  );
end entity sdp_ram;

architecture rtl of sdp_ram is

  type mem_t is array(2 ** ADDR_WIDTH - 1 downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);

  impure function load_hex_file (
    filename : string
  ) return mem_t is

    file     f      : text;
    variable l      : line;
    variable word   : std_logic_vector(DATA_WIDTH - 1 downto 0);
    variable ok     : boolean;
    variable result : mem_t;
    variable idx    : natural;
    variable status : file_open_status;

  begin

    if (filename = "") then
      return result;
    end if;

    file_open(status, f, filename, read_mode);

    if (status /= open_ok) then
      report "error: cannot open " & filename
             & " (status=" & file_open_status'image(status) & ")"
        severity failure;
      return result;
    end if;

    result := (others => (others => '0'));
    idx    := 0;

    while true loop

      if endfile(f) then
        report "note: loaded " & integer'image(idx) & " out of "
               & integer'image(2 ** ADDR_WIDTH) & " possible instructions"
          severity note;
        exit;
      end if;

      if (idx = result'length) then
        report "error: file load exited prematurely (file too long)"
          severity failure;
        return result;
      end if;

      readline(f, l);
      hread(l, word, ok);

      assert ok
        report "error: malformed hex encountered"
        severity failure;

      result(idx) := word;
      idx         := idx + 1;

    end loop;

    return result;

  end function load_hex_file;

  signal mem_r : mem_t := load_hex_file(INIT_FILE);

begin

  reg_proc : process (clk_i) is
  begin

    if (rising_edge(clk_i)) then
      if (write_enable_i = '1') then
        mem_r(to_integer(unsigned(write_addr_i))) <= write_data_i;
      end if;

      read_data_o <= mem_r(to_integer(unsigned(read_addr_i)));
    end if;

  end process reg_proc;

end architecture rtl;
