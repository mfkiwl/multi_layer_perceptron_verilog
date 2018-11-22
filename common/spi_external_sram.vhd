library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;


--library unisim;
--use unisim.vcomponents.all;

entity spi_external_sram is
  port(
    sysclk : in std_logic;
    reset  : in std_logic;

    spi_cs_n : in  std_logic;
    spi_clk  : in  std_logic;
    spi_din  : in  std_logic;
    spi_dout : out std_logic;

    sram0_addr : out std_logic_vector(16 downto 0);
    sram0_data : inout std_logic_vector(7 downto 0);
    sram0_cs_n : out std_logic;
    sram0_oe_n : out std_logic;
    sram0_we_n : out std_logic;

    sram1_addr : out std_logic_vector(16 downto 0);
    sram1_data : inout std_logic_vector(7 downto 0);
    sram1_cs_n : out std_logic;
    sram1_oe_n : out std_logic;
    sram1_we_n : out std_logic;

    internal_enable : in std_logic;

    internal_sram0_addr           : in  std_logic_vector(16 downto 0);
    internal_sram0_data_input     : out std_logic_vector(7 downto 0);
    internal_sram0_data_output    : in  std_logic_vector(7 downto 0);
    internal_sram0_data_output_en : in  std_logic;
    internal_sram0_cs_n           : in  std_logic;
    internal_sram0_oe_n           : in  std_logic;
    internal_sram0_we_n           : in  std_logic;

    internal_sram1_addr           : in  std_logic_vector(16 downto 0);
    internal_sram1_data_input     : out std_logic_vector(7 downto 0);
    internal_sram1_data_output    : in  std_logic_vector(7 downto 0);
    internal_sram1_data_output_en : in  std_logic;
    internal_sram1_cs_n           : in  std_logic;
    internal_sram1_oe_n           : in  std_logic;
    internal_sram1_we_n           : in  std_logic;

    gpio_output0 : out std_logic_vector(31 downto 0);
    gpio_output1 : out std_logic_vector(31 downto 0);    
    gpio_output2 : out std_logic_vector(31 downto 0);
    gpio_output3 : out std_logic_vector(31 downto 0);
    gpio_output4 : out std_logic_vector(31 downto 0);
    gpio_output5 : out std_logic_vector(31 downto 0);
    gpio_output6 : out std_logic_vector(31 downto 0);
    gpio_output7 : out std_logic_vector(31 downto 0);

    gpio_input0 : in std_logic_vector(31 downto 0);
    gpio_input1 : in std_logic_vector(31 downto 0);    
    gpio_input2 : in std_logic_vector(31 downto 0);
    gpio_input3 : in std_logic_vector(31 downto 0);
    gpio_input4 : in std_logic_vector(31 downto 0);
    gpio_input5 : in std_logic_vector(31 downto 0);
    gpio_input6 : in std_logic_vector(31 downto 0);
    gpio_input7 : in std_logic_vector(31 downto 0)
    );    
end spi_external_sram;

architecture RTL of spi_external_sram is

  type fsm is (PRE_IDLE,
               IDLE,
               RECV_CMD,
               RECV_END_CMD,
               SEND_SRAM_DATA,
               SEND_GPIO_DATA, SEND_GPIO_DATA_END,
               RECV_SRAM0_DATA, RECV_SRAM1_DATA,
               RECV_GPIO_DATA, RECV_GPIO_DATA_END,
               ENDWAIT );
  signal state        : fsm;


  signal sram0_addr_i : std_logic_vector(16 downto 0);
  signal sram0_cs_n_i : std_logic;
  signal sram0_oe_n_i : std_logic;
  signal sram0_we_n_i : std_logic;

  signal sram1_addr_i : std_logic_vector(16 downto 0);
  signal sram1_cs_n_i : std_logic;
  signal sram1_oe_n_i : std_logic;
  signal sram1_we_n_i : std_logic;

  signal sram0_data_in       : std_logic_vector(7 downto 0);
  signal sram0_data_out_i    : std_logic_vector(7 downto 0);
  signal sram0_data_out_en_i : std_logic;

  signal sram0_data_out    : std_logic_vector(7 downto 0);
  signal sram0_data_out_en : std_logic;

  signal sram1_data_in     : std_logic_vector(7 downto 0);
  signal sram1_data_out_i  : std_logic_vector(7 downto 0);
  signal sram1_data_out_en_i : std_logic;

  signal sram1_data_out    : std_logic_vector(7 downto 0);
  signal sram1_data_out_en : std_logic;

  signal gpio_output0_i : std_logic_vector(31 downto 0);
  signal gpio_output1_i : std_logic_vector(31 downto 0);    
  signal gpio_output2_i : std_logic_vector(31 downto 0);
  signal gpio_output3_i : std_logic_vector(31 downto 0);
  signal gpio_output4_i : std_logic_vector(31 downto 0);
  signal gpio_output5_i : std_logic_vector(31 downto 0);
  signal gpio_output6_i : std_logic_vector(31 downto 0);
  signal gpio_output7_i : std_logic_vector(31 downto 0);

  signal spi_cs_n_d, spi_cs_n_d0 : std_logic;
  signal spi_clk_d, spi_clk_d0   : std_logic;
  signal spi_din_d, spi_din_d0   : std_logic;
  signal spi_clk_dd              : std_logic;

  signal command_address : std_logic_vector(31 downto 0);
  signal header_count : std_logic_vector(5 downto 0);

  signal gpio_count : std_logic_vector(5 downto 0);
  signal gpio_recv_data : std_logic_vector(31 downto 0);
  signal gpio_send_data : std_logic_vector(31 downto 0);

  signal sram_count : std_logic_vector(2 downto 0);
  signal sram_send_data : std_logic_vector(7 downto 0);
  signal sram_recv_data : std_logic_vector(7 downto 0);
  signal sram_read_data : std_logic_vector(7 downto 0);

  signal write_control : std_logic_vector( 1 downto 0);
  
begin

  -- IOポート接続
  gpio_output0 <= gpio_output0_i;
  gpio_output1 <= gpio_output1_i;
  gpio_output2 <= gpio_output2_i;
  gpio_output3 <= gpio_output3_i;
  gpio_output4 <= gpio_output4_i;
  gpio_output5 <= gpio_output5_i;
  gpio_output6 <= gpio_output6_i;
  gpio_output7 <= gpio_output7_i;

  -- スリーステートポート
  process( sram0_data_out, sram0_data_out_en )
  begin
    if( sram0_data_out_en = '1' ) then
      sram0_data <= sram0_data_out;
    else
      sram0_data <= "ZZZZZZZZ";      
    end if;
  end process;
  sram0_data_in             <= sram0_data;
  internal_sram0_data_input <= sram0_data;

  -- スリーステートポート
  process( sram1_data_out, sram1_data_out_en )
  begin
    if( sram1_data_out_en = '1' ) then
      sram1_data <= sram1_data_out;
    else
      sram1_data <= "ZZZZZZZZ";      
    end if;
  end process;
  sram1_data_in             <= sram1_data;
  internal_sram1_data_input <= sram1_data;

  sram0_addr        <= sram0_addr_i        when internal_enable = '0' else internal_sram0_addr;
  sram0_cs_n        <= sram0_cs_n_i        when internal_enable = '0' else internal_sram0_cs_n;
  sram0_oe_n        <= sram0_oe_n_i        when internal_enable = '0' else internal_sram0_oe_n;
  sram0_we_n        <= sram0_we_n_i        when internal_enable = '0' else internal_sram0_we_n;
  sram0_data_out    <= sram0_data_out_i    when internal_enable = '0' else internal_sram0_data_output;
  sram0_data_out_en <= sram0_data_out_en_i when internal_enable = '0' else internal_sram0_data_output_en;

  sram1_addr        <= sram1_addr_i        when internal_enable = '0' else internal_sram1_addr;
  sram1_cs_n        <= sram1_cs_n_i        when internal_enable = '0' else internal_sram1_cs_n;
  sram1_oe_n        <= sram1_oe_n_i        when internal_enable = '0' else internal_sram1_oe_n;
  sram1_we_n        <= sram1_we_n_i        when internal_enable = '0' else internal_sram1_we_n;
  sram1_data_out    <= sram1_data_out_i    when internal_enable = '0' else internal_sram1_data_output;
  sram1_data_out_en <= sram1_data_out_en_i when internal_enable = '0' else internal_sram1_data_output_en;

  -- SRAM選択
  sram_read_data <= sram0_data_in when command_address(20) = '1' else
                    sram1_data_in;
                                                                
  
  process( sysclk, reset )
  begin
    if( reset = '1' ) then

      spi_cs_n_d  <= '1';
      spi_cs_n_d0 <= '1';
      spi_clk_dd  <= '0';
      spi_clk_d   <= '0';
      spi_clk_d0  <= '0';
      spi_din_d   <= '0';
      spi_din_d0  <= '0';

      spi_dout <= 'Z';
      
      sram0_addr_i <= (others => '0');
      sram0_cs_n_i <= '1';
      sram0_oe_n_i <= '1';
      sram0_we_n_i <= '1';

      sram0_data_out_i <= (others => '0');
      sram0_data_out_en_i <= '0';

      sram1_addr_i <= (others => '0');
      sram1_cs_n_i <= '1';
      sram1_oe_n_i <= '1';
      sram1_we_n_i <= '1';

      sram1_data_out_i <= (others => '0');
      sram1_data_out_en_i <= '0';

      gpio_output0_i <= (others => '0');
      gpio_output1_i <= (others => '0');
      gpio_output2_i <= (others => '0');
      gpio_output3_i <= (others => '0');
      gpio_output4_i <= (others => '0');
      gpio_output5_i <= (others => '0');
      gpio_output6_i <= (others => '0');
      gpio_output7_i <= (others => '0');
      
      -- 内部変数
      state <= PRE_IDLE;
      command_address <= (others => '0');
      header_count    <= (others => '0');
      gpio_count      <= (others => '0');
      gpio_recv_data  <= (others => '0');
      gpio_send_data  <= (others => '0');
      sram_count      <= (others => '0');
      sram_recv_data  <= (others => '0');
      sram_send_data  <= (others => '0');
      
    elsif( sysclk'event and sysclk= '1' ) then

      -- メタステーブル対策
      spi_cs_n_d  <= spi_cs_n_d0;
      spi_cs_n_d0 <= spi_cs_n;
      spi_clk_dd  <= spi_clk_d;         -- エッジ検出用
      spi_clk_d   <= spi_clk_d0;
      spi_clk_d0  <= spi_clk;
      spi_din_d   <= spi_din_d0;
      spi_din_d0  <= spi_din;

      case state is
        when PRE_IDLE =>

          -- cs_nがデアサートされるのを待つ
          if( spi_cs_n_d = '1' ) then
            state <= IDLE;
          end if;

          spi_dout <= 'Z';

          sram0_data_out_i <= X"00";
          sram0_data_out_en_i <= '0';
          sram0_cs_n_i <= '1';
          sram0_oe_n_i <= '1';
          sram0_we_n_i <= '1';
          sram1_data_out_i <= X"00";
          sram1_data_out_en_i <= '0';
          sram1_cs_n_i <= '1';
          sram1_oe_n_i <= '1';
          sram1_we_n_i <= '1';

          command_address <= (others => '0');
          header_count    <= (others => '0');
          gpio_count      <= (others => '0');
          gpio_recv_data  <= (others => '0');
          gpio_send_data  <= (others => '0');
          sram_count      <= (others => '0');
          sram_recv_data  <= (others => '0');
          sram_send_data  <= (others => '0');

          write_control <= "00";
          
        when IDLE =>
          -- cs_nのアサートを待つ
          if( spi_cs_n_d = '0' ) then
            state <= RECV_CMD;
          end if;

        when RECV_CMD =>
          -- クロックの立ち上がりでデータを取り込む
          if( spi_cs_n_d = '1' ) then
            state <= PRE_IDLE;
          elsif( spi_clk_dd = '0' and spi_clk_d = '1' ) then

            command_address(31 downto 0) <= command_address(30 downto 0) & spi_din_d;
            header_count <= header_count + 1;
            
            if( header_count = "11111" ) then
              state <= RECV_END_CMD;
            end if;
            
          end if;

        when RECV_END_CMD   =>
          -- 次のクロックの立ち上がりまでの4clk間に、SRAMへのリードライト処理を起動する
          if( command_address(31 downto 24) = "00000011" ) then  -- read
            case command_address(23 downto 20) is

              when "0001" =>            -- SRAM0

                sram0_cs_n_i <= '0';
                sram0_oe_n_i <= '0';
                sram0_addr_i <= command_address(16 downto 0);
                
                state <= SEND_SRAM_DATA;

              when "0010"=>            -- SRAM1

                sram1_cs_n_i <= '0';
                sram1_oe_n_i <= '0';
                sram1_addr_i <= command_address(16 downto 0);
                
                state <= SEND_SRAM_DATA;
                
              when others =>            -- GPIO
                case command_address(4 downto 2) is
                  when "000"   => gpio_send_data <= gpio_input0;
                  when "001"   => gpio_send_data <= gpio_input1;
                  when "010"   => gpio_send_data <= gpio_input2;
                  when "011"   => gpio_send_data <= gpio_input3;
                  when "100"   => gpio_send_data <= gpio_input4;
                  when "101"   => gpio_send_data <= gpio_input5;
                  when "110"   => gpio_send_data <= gpio_input6;
                  when "111"   => gpio_send_data <= gpio_input7;
                  when others => null;
                end case;

                state <= SEND_GPIO_DATA;
            end case;

          elsif( command_address(31 downto 24) = "00000010" ) then  -- write

            case command_address(23 downto 20) is

              when "0001" =>            -- SRAM0

                state <= RECV_SRAM0_DATA;
                
              when "0010"=>             -- SRAM1

                state <= RECV_SRAM1_DATA;
                
              when others =>            -- GPIO

                state <= RECV_GPIO_DATA;

            end case;

          else
            -- 未定義コマンド
            -- 無視する
            state <= PRE_IDLE;
            
          end if;


        when RECV_SRAM0_DATA =>
          -- クロックの立ち上がりでデータを取り込む
          if( spi_cs_n_d = '1' ) then
            state <= PRE_IDLE;
            sram0_cs_n_i <= '1';
            sram0_we_n_i <= '1';
            sram0_data_out_i <= (others => '0');
            sram0_data_out_en_i <= '0';
          elsif( spi_clk_dd = '0' and spi_clk_d = '1' ) then
            sram_count <= sram_count+1;
            sram_recv_data(7 downto 0) <= sram_recv_data(6 downto 0) & spi_din_d;
            if( sram_count = "111" ) then
              write_control <= "01";
            else
              write_control <= "00";
            end if;
            sram0_cs_n_i <= '1';
            sram0_we_n_i <= '1';
            sram0_data_out_i <= (others => '0');
            sram0_data_out_en_i <= '0';
          elsif( sram_count = "000" ) then
            if( write_control = "00" ) then
              sram0_data_out_i <= (others => '0');
              sram0_data_out_en_i <= '0';
            elsif( write_control = "01" ) then
              sram0_addr_i <= command_address(16 downto 0);
              sram0_data_out_i <= sram_recv_data;
              sram0_data_out_en_i <= '1';
              sram0_cs_n_i <= '0';
              sram0_we_n_i <= '0';
              write_control <=write_control+1;              
            elsif (write_control = "10" ) then
              command_address(16 downto 0) <= command_address(16 downto 0)+1;
              write_control <=write_control+1;
            elsif( write_control = "11" ) then
              sram0_cs_n_i <= '1';
              sram0_we_n_i <= '1';
              write_control <=write_control+1;              
              null;
            end if;
          end if;


        when RECV_SRAM1_DATA =>
          -- クロックの立ち上がりでデータを取り込む
          if( spi_cs_n_d = '1' ) then
            state <= PRE_IDLE;
            sram1_cs_n_i <= '1';
            sram1_we_n_i <= '1';
            sram1_data_out_i <= (others => '0');
            sram1_data_out_en_i <= '0';
          elsif( spi_clk_dd = '0' and spi_clk_d = '1' ) then
            sram_count <= sram_count+1;
            sram_recv_data(7 downto 0) <= sram_recv_data(6 downto 0) & spi_din_d;
            if( sram_count = "111" ) then
              write_control <= "01";
            else
              write_control <= "00";
            end if;
            sram1_cs_n_i <= '1';
            sram1_we_n_i <= '1';
            sram1_data_out_i <= (others => '0');
            sram1_data_out_en_i <= '0';
          elsif( sram_count = "000" ) then
            if( write_control = "00" ) then
              sram1_data_out_i <= (others => '0');
              sram1_data_out_en_i <= '0';
            elsif( write_control = "01" ) then
              sram1_addr_i <= command_address(16 downto 0);
              sram1_data_out_i <= sram_recv_data;
              sram1_data_out_en_i <= '1';
              sram1_cs_n_i <= '0';
              sram1_we_n_i <= '0';
              write_control <=write_control+1;              
            elsif (write_control = "10" ) then
              command_address(16 downto 0) <= command_address(16 downto 0)+1;
              write_control <=write_control+1;
            elsif( write_control = "11" ) then
              sram1_cs_n_i <= '1';
              sram1_we_n_i <= '1';
              write_control <=write_control+1;              
              null;
            end if;
          end if;

          
          
        when SEND_SRAM_DATA =>
          -- クロックの立下りでデータを送出する
          if( spi_cs_n_d = '1' ) then
            state <= PRE_IDLE;
          elsif( spi_clk_dd = '1' and spi_clk_d = '0' ) then
            if( sram_count = "000" ) then
              sram_send_data(7 downto 0) <= sram_read_data(6 downto 0) & "0";
              spi_dout <= sram_read_data(7);
            else
              sram_send_data(7 downto 0) <= sram_send_data(6 downto 0) & "0";
              spi_dout <= sram_send_data(7);
            end if;

            sram_count <= sram_count+1;
            
            if( sram_count = "111" ) then
              command_address(16 downto 0) <= command_address(16 downto 0) +1;
              sram0_addr_i <= command_address(16 downto 0)+1;
              sram1_addr_i <= command_address(16 downto 0)+1;
            end if;
          end if;
          
        when SEND_GPIO_DATA =>          -- GPIO -> SPI
         
          -- クロックの立ち上がりでデータを取り込む
          if( spi_cs_n_d = '1' ) then
            state <= PRE_IDLE;
          elsif( spi_clk_dd = '1' and spi_clk_d = '0' ) then

            spi_dout <= gpio_send_data(31);
            gpio_send_data(31 downto 0) <= gpio_send_data(30 downto 0) & "0";
            gpio_count <= gpio_count+1;
            
            if( gpio_count = "11111" ) then
              state <= SEND_GPIO_DATA_END;
            end if;
          end if;

        when SEND_GPIO_DATA_END =>
          
          if( spi_clk_dd = '1' and spi_clk_d = '0' ) then
            state <= PRE_IDLE;
          end if;
          
        when RECV_GPIO_DATA =>          -- SPI -> GPIO

          -- クロックの立ち上がりでデータを取り込む
          if( spi_cs_n_d = '1' ) then
            state <= PRE_IDLE;
          elsif( spi_clk_dd = '0' and spi_clk_d = '1' ) then

            gpio_recv_data(31 downto 0) <= gpio_recv_data(30 downto 0) & spi_din_d;
            gpio_count <= gpio_count+1;
            
            if( gpio_count = "11111" ) then
              state <= RECV_GPIO_DATA_END;
            end if;
          end if;

        when RECV_GPIO_DATA_END =>
          -- GPIOに反映する
          case command_address(4 downto 2) is
            when "000"   => gpio_output0_i <= gpio_recv_data;
            when "001"   => gpio_output1_i <= gpio_recv_data;
            when "010"   => gpio_output2_i <= gpio_recv_data;
            when "011"   => gpio_output3_i <= gpio_recv_data;
            when "100"   => gpio_output4_i <= gpio_recv_data;
            when "101"   => gpio_output5_i <= gpio_recv_data;
            when "110"   => gpio_output6_i <= gpio_recv_data;
            when "111"   => gpio_output7_i <= gpio_recv_data;
            when others => null;
          end case;
          state <= PRE_IDLE;

        when others => null;
      end case;
      
    end if;
  end process;
  
  

end RTL;
