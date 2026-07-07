library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pRegisterBus.all;
use work.pReg_swan.all;

entity sound_module5 is
   port
   (
      clk            : in  std_logic;
      ce             : in  std_logic;
      reset          : in  std_logic;

      soundDMAvalue  : in  std_logic_vector(7 downto 0);
      soundDMAvalid  : in  std_logic;

      RegBus_Din     : in  std_logic_vector(BUS_buswidth-1 downto 0);
      RegBus_Adr     : in  std_logic_vector(BUS_busadr-1 downto 0);
      RegBus_wren    : in  std_logic;
      RegBus_rst     : in  std_logic;
      RegBus_Dout    : out std_logic_vector(BUS_buswidth-1 downto 0);

      soundEnable    : out std_logic;
      soundoutL      : out signed(12 downto 0) := (others => '0');
      soundoutR      : out signed(12 downto 0) := (others => '0')
   );
end entity;

architecture arch of sound_module5 is

   -- register
   signal SND_HYPER_CTRL      : std_logic_vector(7 downto 0);
   signal SND_HYPER_CHAN_CTRL : std_logic_vector(6 downto 0);

   signal SND_HYPERVOICE_written : std_logic;

   type t_reg_wired_or is array(0 to 2) of std_logic_vector(7 downto 0);
   signal reg_wired_or : t_reg_wired_or;

   -- Channel5 state, named after ares' APU::Channel5::State
   signal hyperChannel      : std_logic;          -- state.channel: L/R side for the next manual/mode-0 write
   signal hyperLeft         : unsigned(7 downto 0); -- state.left
   signal hyperRight        : unsigned(7 downto 0); -- state.right
   signal hyperLeftChanged  : std_logic;          -- state.leftChanged
   signal hyperRightChanged : std_logic;          -- state.rightChanged

   -- ce ticks at ~3.072MHz (36.864MHz/12, see swanTop ce_counter); ares calls
   -- Channel5::runOutput() once per 128-cycle APU sequencer round, i.e. at 24kHz.
   signal tickPrescale : unsigned(6 downto 0);    -- counts ce pulses 0..127
   signal speedClock   : unsigned(3 downto 0);    -- state.clock: counts 24kHz ticks up to the speed divisor

   -- APU::Channel5::scale(): volume=0 bypasses to full scale; otherwise the
   -- 2-bit scale field picks one of 4 shift-based curves. Returns a 16-bit
   -- value matching ares' i16 output.left/right.
   function hyperScale(sampleIn : unsigned(7 downto 0); volumeSel : std_logic_vector(1 downto 0); scaleSel : std_logic_vector(1 downto 0)) return signed is
      variable shiftMul  : integer range 1 to 128;
      variable offsetVal : integer range 0 to 32768;
      variable value     : integer range -32768 to 32767;
   begin
      if (volumeSel = "00") then
         value := to_integer(signed(sampleIn)) * 256;
      else
         case volumeSel is
            when "01"   => shiftMul := 128; offsetVal := 32768; -- shift 7 (8-1)
            when "10"   => shiftMul :=  64; offsetVal := 16384; -- shift 6 (8-2)
            when others => shiftMul :=  32; offsetVal :=  8192; -- "11": shift 5 (8-3)
         end case;
         case scaleSel is
            when "00"   => value := to_integer(sampleIn) * shiftMul;                        -- unsigned shift
            when "01"   => value := to_integer(sampleIn) * shiftMul - offsetVal;             -- unsigned shift, DC-offset down
            when "10"   => value := to_integer(signed(sampleIn)) * shiftMul;                 -- signed shift
            when others => value := to_integer(signed(sampleIn)) * 256;                      -- "11": full scale, ignores volume
         end case;
      end if;
      return to_signed(value, 16);
   end function;

begin

   iREG_SND_HYPER_CTRL      : entity work.eReg generic map ( REG_SND_HYPER_CTRL       ) port map (clk, RegBus_Din, RegBus_Adr, RegBus_wren, RegBus_rst, reg_wired_or(0), SND_HYPER_CTRL     , SND_HYPER_CTRL     );
   iREG_SND_HYPER_CHAN_CTRL : entity work.eReg generic map ( REG_SND_HYPER_CHAN_CTRL  ) port map (clk, RegBus_Din, RegBus_Adr, RegBus_wren, RegBus_rst, reg_wired_or(1), SND_HYPER_CHAN_CTRL, SND_HYPER_CHAN_CTRL);
   iREG_SND_HYPERVOICE      : entity work.eReg generic map ( REG_SND_HYPERVOICE       ) port map (clk, RegBus_Din, RegBus_Adr, RegBus_wren, RegBus_rst, reg_wired_or(2), x"00"              , open               , SND_HYPERVOICE_written);

   soundEnable <= SND_HYPER_CTRL(7);

   process (reg_wired_or)
      variable wired_or : std_logic_vector(7 downto 0);
   begin
      wired_or := reg_wired_or(0);
      for i in 1 to (reg_wired_or'length - 1) loop
         wired_or := wired_or or reg_wired_or(i);
      end loop;
      RegBus_Dout <= wired_or;
   end process;

   process (clk)
      variable tick          : std_logic;
      variable newSpeedClock : unsigned(3 downto 0);
      variable divisor       : unsigned(3 downto 0);
      variable scaled        : signed(15 downto 0);
   begin
      if rising_edge(clk) then

         if (reset = '1') then

            soundoutL         <= (others => '0');
            soundoutR         <= (others => '0');
            hyperChannel      <= '0';
            hyperLeft         <= (others => '0');
            hyperRight        <= (others => '0');
            hyperLeftChanged  <= '0';
            hyperRightChanged <= '0';
            tickPrescale      <= (others => '0');
            speedClock        <= (others => '0');

         else

            if (ce = '1') then

               -- prescale ce (~3.072MHz) down to the ~24kHz tick that ares' runOutput() runs at
               tick := '0';
               if (tickPrescale = 127) then
                  tick := '1';
                  tickPrescale <= (others => '0');
               else
                  tickPrescale <= tickPrescale + 1;
               end if;

               if (tick = '1') then

                  case (SND_HYPER_CTRL(6 downto 4)) is  -- io.speed -> divisors[] = {1,2,3,4,5,6,8,12}
                     when "000"  => divisor := to_unsigned( 1, 4);
                     when "001"  => divisor := to_unsigned( 2, 4);
                     when "010"  => divisor := to_unsigned( 3, 4);
                     when "011"  => divisor := to_unsigned( 4, 4);
                     when "100"  => divisor := to_unsigned( 5, 4);
                     when "101"  => divisor := to_unsigned( 6, 4);
                     when "110"  => divisor := to_unsigned( 8, 4);
                     when others => divisor := to_unsigned(12, 4);
                  end case;

                  newSpeedClock := speedClock + 1;
                  if (newSpeedClock < divisor) then
                     speedClock <= newSpeedClock;
                  else
                     speedClock <= (others => '0');

                     -- soundoutL/R hold the ares i16 output(15 downto 3): a plain
                     -- bit-slice down to this module's existing 13-bit output range
                     if (hyperLeftChanged = '1') then
                        scaled := hyperScale(hyperLeft, SND_HYPER_CTRL(1 downto 0), SND_HYPER_CTRL(3 downto 2));
                        soundoutL <= scaled(15 downto 3);
                        hyperLeftChanged <= '0';
                     end if;

                     if (hyperRightChanged = '1') then
                        scaled := hyperScale(hyperRight, SND_HYPER_CTRL(1 downto 0), SND_HYPER_CTRL(3 downto 2));
                        soundoutR <= scaled(15 downto 3);
                        hyperRightChanged <= '0';
                     end if;

                  end if;

               end if;

            end if;

            -- manualWrite(): CPU writes to the sample port always alternate L/R
            if (SND_HYPERVOICE_written = '1') then
               if (hyperChannel = '0') then
                  hyperLeft        <= unsigned(RegBus_Din);
                  hyperLeftChanged <= '1';
               else
                  hyperRight        <= unsigned(RegBus_Din);
                  hyperRightChanged <= '1';
               end if;
               hyperChannel <= not hyperChannel;
            end if;

            -- dmaWrite(): sound DMA writes are routed by the SND_HYPER_CHAN_CTRL mode bits
            if (soundDMAvalid = '1') then
               case (SND_HYPER_CHAN_CTRL(6 downto 5)) is
                  when "00" =>  -- alternate L/R, same as manualWrite
                     if (hyperChannel = '0') then
                        hyperLeft        <= unsigned(soundDMAvalue);
                        hyperLeftChanged <= '1';
                     else
                        hyperRight        <= unsigned(soundDMAvalue);
                        hyperRightChanged <= '1';
                     end if;
                     hyperChannel <= not hyperChannel;
                  when "01" =>  -- left only
                     hyperChannel     <= '0';
                     hyperLeft        <= unsigned(soundDMAvalue);
                     hyperLeftChanged <= '1';
                  when "10" =>  -- right only
                     hyperChannel      <= '1';
                     hyperRight        <= unsigned(soundDMAvalue);
                     hyperRightChanged <= '1';
                  when others =>  -- "11": both sides get the same sample
                     hyperLeft         <= unsigned(soundDMAvalue);
                     hyperLeftChanged  <= '1';
                     hyperRight        <= unsigned(soundDMAvalue);
                     hyperRightChanged <= '1';
                     hyperChannel      <= '1';
               end case;
            end if;

         end if;

      end if;
   end process;


end architecture;
