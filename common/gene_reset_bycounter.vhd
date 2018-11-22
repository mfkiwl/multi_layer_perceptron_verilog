library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity gene_reset_bycounter is
    generic (
        value : std_logic_vector(31 downto 0) := X"0000ffff"
        );
    port (
      pReset_n : in std_logic;
      pLocked  : in std_logic;
      pClk     : in std_logic;

      pResetOut_n : out std_logic
    );
end gene_reset_bycounter;
 
architecture RTL of gene_reset_bycounter is

  -- create a synchronous reset in the transmitter clock domain
  signal ll_pre_reset_0_i : std_logic_vector(5 downto 0) := "000000";
  signal ll_reset_0_i     : std_logic := '0';

  attribute async_reg : string;
  attribute async_reg of ll_pre_reset_0_i : signal is "true";

  attribute keep : string;
  attribute keep of ll_reset_0_i : signal is "true";

  signal counter : std_logic_vector(31 downto 0) := X"00000000";

  signal ResetOut_n  : std_logic := '0';
  signal ResetOut_n1 : std_logic := '0';

begin

    pResetOut_n <= ResetOut_n1;
  
    process (pClk, pReset_n, pLocked)
    begin
      if ( pReset_n = '0' or pLocked = '0' ) then

        ll_pre_reset_0_i <= (others => '0');
        ll_reset_0_i     <= '0';

        counter          <= (others => '0');
        ResetOut_n       <= '0';
        ResetOut_n1      <= '0';

      elsif (pClk'event and pClk = '1') then
        ll_pre_reset_0_i(0)          <= '1';
        ll_pre_reset_0_i(5 downto 1) <= ll_pre_reset_0_i(4 downto 0);
        ll_reset_0_i                 <= ll_pre_reset_0_i(5);

        ResetOut_n1 <= ResetOut_n;
        
        if( ll_reset_0_i = '1' ) then
          if( counter /= value  ) then
            counter <= counter+1;
            ResetOut_n <= '0';
          else
            ResetOut_n <= '1';            
          end if;
        else
          ResetOut_n <= '0';
          counter <= (others => '0');
        end if;
      end if;
    end process;
    
end RTL;
