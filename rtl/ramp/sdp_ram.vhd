library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

-- Implemented separate write and read addresses.
-- When write enable is asserted and the read address equals the write address, read data presents the pre-write
-- contents of that location.
-- The return of uninitialized reads is undefined. Once-written locations will always return non-metavalues.
-- No reset was included because block RAM contents cannot be reset.

entity sdp_ram is
  generic (
    DATA_WIDTH : positive := 8;
    ADDR_WIDTH : positive := 8
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

  type mem_array_t is array(natural range <>) of std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal mem_r : mem_array_t(2 ** ADDR_WIDTH - 1 downto 0);

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
