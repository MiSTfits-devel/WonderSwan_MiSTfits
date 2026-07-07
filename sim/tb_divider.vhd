-- SPDX-License-Identifier: GPL-2.0-or-later
-- Unit test for rtl/divider.vhd (the V30MZ DIV/IDIV helper) with nvc.
-- Checks quotient and remainder across sign combinations and edge sizes.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_divider is
end entity;

architecture sim of tb_divider is
   signal clk       : std_logic := '0';
   signal start     : std_logic := '0';
   signal done      : std_logic;
   signal busy      : std_logic;
   signal dividend  : signed(32 downto 0) := (others => '0');
   signal divisor   : signed(32 downto 0) := (others => '0');
   signal quotient  : signed(32 downto 0);
   signal remainder : signed(32 downto 0);
   signal finished  : boolean := false;
begin

   clk <= not clk after 5 ns when not finished else '0';

   dut : entity work.divider
      port map (
         clk       => clk,
         start     => start,
         done      => done,
         busy      => busy,
         dividend  => dividend,
         divisor   => divisor,
         quotient  => quotient,
         remainder => remainder
      );

   process
      type vec_t is record
         n, d : integer;
      end record;
      type vecs_t is array (natural range <>) of vec_t;
      -- expected results follow V30MZ truncating division:
      -- quotient rounds toward zero, remainder takes the dividend's sign
      constant vecs : vecs_t := (
         (100, 7), (-100, 7), (100, -7), (-100, -7),
         (0, 5), (65535, 256), (12345678, 1), (1, 12345678),
         (2147483647, 2), (-2147483647, 3));
      variable exp_q, exp_r : integer;
   begin
      wait for 20 ns;
      for i in vecs'range loop
         wait until rising_edge(clk);
         dividend <= to_signed(vecs(i).n, 33);
         divisor  <= to_signed(vecs(i).d, 33);
         start    <= '1';
         wait until rising_edge(clk);
         start    <= '0';
         wait until rising_edge(clk) and done = '1';
         exp_q := vecs(i).n / vecs(i).d;
         exp_r := vecs(i).n rem vecs(i).d;
         assert to_integer(quotient) = exp_q
            report "quotient " & integer'image(vecs(i).n) & "/" & integer'image(vecs(i).d) &
                   " = " & integer'image(to_integer(quotient)) & ", expected " & integer'image(exp_q)
            severity failure;
         assert to_integer(remainder) = exp_r
            report "remainder " & integer'image(vecs(i).n) & " rem " & integer'image(vecs(i).d) &
                   " = " & integer'image(to_integer(remainder)) & ", expected " & integer'image(exp_r)
            severity failure;
      end loop;
      report "tb_divider: all " & integer'image(vecs'length) & " vectors passed";
      finished <= true;
      wait;
   end process;

end architecture;
