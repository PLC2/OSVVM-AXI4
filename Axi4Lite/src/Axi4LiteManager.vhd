--
--  File Name:         Axi4LiteManager.vhd
--  Design Unit Name:  Axi4LiteManager
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      AXI LIte Manager Model
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date      Version    Description
--    10/2022   2022.10    Changed enum value PRIVATE to PRIVATE_NAME due to VHDL-2019 keyword conflict.   
--    05/2022   2022.05    Updated FIFOs so they are Search => PRIVATE
--    03/2022   2022.03    Rederived from the 2022.02 version of Axi4 Full Manager
--
--
--  This file is part of OSVVM.
--
--  Copyright (c) 2017 - 2022 by SynthWorks Design Inc.
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      https://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
--
library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;
  use ieee.numeric_std_unsigned.all ;
  use ieee.math_real.all ;

library osvvm ;
  context osvvm.OsvvmContext ;
  use osvvm.ScoreboardPkg_slv.all ;

library osvvm_common ;
  context osvvm_common.OsvvmCommonContext ;

  use work.Axi4OptionsPkg.all ;
  use work.Axi4ModelPkg.all ;
  use work.Axi4InterfaceCommonPkg.all ;
  use work.Axi4LiteInterfacePkg.all ;
  use work.Axi4CommonPkg.all ;

entity Axi4LiteManager is
generic (
  MODEL_ID_NAME    : string := "" ;
  tperiod_Clk      : time   := 10 ns ;
  
  DEFAULT_DELAY    : time   := 1 ns ; 

  tpd_Clk_AWAddr   : time   := DEFAULT_DELAY ;
  tpd_Clk_AWProt   : time   := DEFAULT_DELAY ;
  tpd_Clk_AWValid  : time   := DEFAULT_DELAY ;

  tpd_Clk_WValid   : time   := DEFAULT_DELAY ;
  tpd_Clk_WData    : time   := DEFAULT_DELAY ;
  tpd_Clk_WStrb    : time   := DEFAULT_DELAY ;

  tpd_Clk_BReady   : time   := DEFAULT_DELAY ;

  tpd_Clk_ARValid  : time   := DEFAULT_DELAY ;
  tpd_Clk_ARProt   : time   := DEFAULT_DELAY ;
  tpd_Clk_ARAddr   : time   := DEFAULT_DELAY ;

  tpd_Clk_RReady   : time   := DEFAULT_DELAY
) ;
port (
  -- Globals
  Clk         : in   std_logic ;
  nReset      : in   std_logic ;

  -- AXI Manager Functional Interface
  AxiBus      : inout Axi4LiteRecType ;

  -- Testbench Transaction Interface
  TransRec    : inout AddressBusRecType 
) ;

  -- Model Configuration 
  -- Access via transactions or external name
  shared variable params : ModelParametersPType ;

  -- Derive AXI interface properties from the AxiBus
  constant AXI_ADDR_WIDTH      : integer := AxiBus.WriteAddress.Addr'length ;
  constant AXI_DATA_WIDTH      : integer := AxiBus.WriteData.Data'length ;
  
  -- Derive ModelInstance label from path_name
  constant MODEL_INSTANCE_NAME : string :=
    -- use MODEL_ID_NAME Generic if set, otherwise use instance label (preferred if set as entityname_1)
    IfElse(MODEL_ID_NAME /= "", MODEL_ID_NAME, PathTail(to_lower(Axi4LiteManager'PATH_NAME))) ;
  
end entity Axi4LiteManager ;
architecture behavioral of Axi4LiteManager is

  signal ModelID, ProtocolID, DataCheckID, BusFailedID : AlertLogIDType ;

  constant AXI_DATA_BYTE_WIDTH : integer := AXI_DATA_WIDTH / 8 ;
  constant AXI_BYTE_ADDR_WIDTH : integer := integer(ceil(log2(real(AXI_DATA_BYTE_WIDTH)))) ;
  constant AXI_STRB_WIDTH      : integer := AXI_DATA_WIDTH/8 ;

  -- Internal Resources
  signal WriteAddressFifo            : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;
  signal WriteDataFifo               : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;

  signal ReadAddressFifo             : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;
  signal ReadAddressTransactionFifo  : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;
  signal ReadDataFifo                : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;

  signal WriteResponseScoreboard     : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;
  signal ReadResponseScoreboard      : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;

  signal WriteAddressRequestCount, WriteAddressDoneCount      : integer := 0 ;
  signal WriteDataRequestCount,    WriteDataDoneCount         : integer := 0 ;
  signal WriteResponseExpectCount, WriteResponseReceiveCount  : integer := 0 ;
  signal ReadAddressRequestCount,  ReadAddressDoneCount       : integer := 0 ;
  signal ReadDataExpectCount,      ReadDataReceiveCount       : integer := 0 ;

  signal WriteResponseActive, ReadDataActive : boolean ;
  
  constant DEFAULT_BURST_MODE : AddressBusFifoBurstModeType := ADDRESS_BUS_BURST_WORD_MODE ;
  signal   BurstFifoMode      : AddressBusFifoBurstModeType := DEFAULT_BURST_MODE ;
  signal   BurstFifoByteMode  : boolean := (DEFAULT_BURST_MODE = ADDRESS_BUS_BURST_BYTE_MODE) ; 
begin

  ------------------------------------------------------------
  -- Turn off drivers not being driven by this model
  ------------------------------------------------------------
  InitAxi4LiteRec (AxiBusRec => AxiBus) ;


  ------------------------------------------------------------
  --  Initialize alerts
  ------------------------------------------------------------
  Initialize : process
    variable ID : AlertLogIDType ;
  begin
    InitAxiOptions(Params) ;

    -- Alerts
    ID                      := NewID(MODEL_INSTANCE_NAME) ;
    ModelID                 <= ID ;
    ProtocolID              <= NewID("Protocol Error", ID ) ;
    DataCheckID             <= NewID("Data Check",     ID ) ;
    BusFailedID             <= NewID("No response",    ID ) ;

    WriteResponseScoreboard <= NewID("WriteResponse Scoreboard", ID, Search => PRIVATE_NAME);
    ReadResponseScoreboard  <= NewID("ReadResponse Scoreboard",  ID, Search => PRIVATE_NAME);

    -- FIFOs get an AlertLogID with NewID, however, it does not print in ReportAlerts (due to DoNotReport)
    --   FIFOS only generate usage type errors 
    WriteAddressFifo           <= NewID("WriteAddressFIFO",             ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
    WriteDataFifo              <= NewID("WriteDataFifo",                ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
    ReadAddressFifo            <= NewID("ReadAddressFifo",              ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
    ReadAddressTransactionFifo <= NewID("ReadAddressTransactionFifo",   ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
    ReadDataFifo               <= NewID("ReadDataFifo",                 ID, ReportMode => DISABLED, Search => PRIVATE_NAME);

    wait ;
  end process Initialize ;


  ------------------------------------------------------------
  --  Transaction Dispatcher
  --    Dispatches transactions to
  ------------------------------------------------------------
  TransactionDispatcher : process
    variable ReadDataTransactionCount : integer := 1 ;
    variable ByteCount          : integer ;
    variable TransfersInBurst   : integer ;

    variable Axi4Option    : Axi4OptionsType ;
    variable Axi4OptionVal : integer ;

    variable AxiDefaults    : AxiBus'subtype ;

    alias    LAW : AxiDefaults.WriteAddress'subtype  is AxiDefaults.WriteAddress ;
    alias    LWD : AxiDefaults.WriteData'subtype     is AxiDefaults.WriteData ;
    alias    LWR : AxiDefaults.WriteResponse'subtype is AxiDefaults.WriteResponse ;
    alias    LAR : AxiDefaults.ReadAddress'subtype   is AxiDefaults.ReadAddress ;
    alias    LRD : AxiDefaults.ReadData'subtype      is AxiDefaults.ReadData ;
    
    variable WriteByteAddr   : integer ;

    variable BytesToSend              : integer ;
    variable BytesPerTransfer         : integer ;
    variable MaxBytesInFirstTransfer  : integer ;

    variable BytesInTransfer : integer ;
    variable BytesToReceive  : integer ;
    variable DataBitOffset   : integer ;

    variable ReadByteAddr    : integer ;
    variable ReadProt        : Axi4ProtType ;

    variable ExpectedData    : std_logic_vector(LRD.Data'range) ;

    variable Operation       : AddressBusOperationType ;
    variable WriteDataCount  : integer := 0 ; 
  begin
    AxiDefaults := InitAxi4LiteRec(AxiBus, '0') ;
    LWR.Resp    := to_Axi4RespType(OKAY);
    LRD.Resp    := to_Axi4RespType(OKAY) ;
    
    wait for 0 ns ; 
    TransRec.WriteBurstFifo <= NewID("WriteBurstFifo", ModelID, Search => PRIVATE_NAME) ;
    TransRec.ReadBurstFifo  <= NewID("ReadBurstFifo",  ModelID, Search => PRIVATE_NAME) ;
    
--!! AWCache, ARCache Defaults
    loop
      WaitForTransaction(
         Clk      => Clk,
         Rdy      => TransRec.Rdy,
         Ack      => TransRec.Ack
      ) ;
      Operation := TransRec.Operation ;

      case Operation is
        -- Execute Standard Directive Transactions
        when WAIT_FOR_TRANSACTION =>
          -- Waits for All WRITE and READ Transactions to complete
          if WriteAddressRequestCount /= WriteAddressDoneCount then
            -- Block until both write address done.
            wait until WriteAddressRequestCount = WriteAddressDoneCount ;
          end if ;
          if WriteDataRequestCount /= WriteDataDoneCount then
            -- Block until both write data done.
            wait until WriteDataRequestCount = WriteDataDoneCount ;
          end if ;
          if WriteResponseExpectCount /= WriteResponseReceiveCount then
            -- Block until both write response done.
            wait until WriteResponseExpectCount = WriteResponseReceiveCount ;
          end if ;

          if ReadAddressRequestCount /= ReadAddressDoneCount then
            -- Block until both read address done.
            wait until ReadAddressRequestCount = ReadAddressDoneCount ;
          end if ;
          if ReadDataExpectCount /= ReadDataReceiveCount then
            -- Block until both read data done.
            wait until ReadDataExpectCount = ReadDataReceiveCount ;
          end if ;

        when WAIT_FOR_WRITE_TRANSACTION =>
          if WriteAddressRequestCount /= WriteAddressDoneCount then
            -- Block until both write address done.
            wait until WriteAddressRequestCount = WriteAddressDoneCount ;
          end if ;
          if WriteDataRequestCount /= WriteDataDoneCount then
            -- Block until both write data done.
            wait until WriteDataRequestCount = WriteDataDoneCount ;
          end if ;
          if WriteResponseExpectCount /= WriteResponseReceiveCount then
            -- Block until both write response done.
            wait until WriteResponseExpectCount = WriteResponseReceiveCount ;
          end if ;
          wait for 0 ns ; 

        when WAIT_FOR_READ_TRANSACTION =>
          if ReadAddressRequestCount /= ReadAddressDoneCount then
            -- Block until both read address done.
            wait until ReadAddressRequestCount = ReadAddressDoneCount ;
          end if ;
          if ReadDataExpectCount /= ReadDataReceiveCount then
            -- Block until both read data done.
            wait until ReadDataExpectCount = ReadDataReceiveCount ;
          end if ;
          wait for 0 ns ; 

        when WAIT_FOR_CLOCK =>
          WaitForClock(Clk, TransRec.IntToModel) ;

        when GET_ALERTLOG_ID =>
          TransRec.IntFromModel <= integer(ModelID) ;

        when SET_BURST_MODE =>                      
          BurstFifoMode       <= TransRec.IntToModel ;
          BurstFifoByteMode   <= (TransRec.IntToModel = ADDRESS_BUS_BURST_BYTE_MODE) ;
          wait for 0 ns ; 
          AlertIf(ModelID, not IsAddressBusBurstMode(BurstFifoMode), 
            "Invalid Burst Mode " & to_string(BurstFifoMode), FAILURE) ;
              
        when GET_BURST_MODE =>                      
          TransRec.IntFromModel <= BurstFifoMode ;

        when GET_TRANSACTION_COUNT =>
          TransRec.IntFromModel <= integer(TransRec.Rdy) ; --  WriteAddressDoneCount + ReadAddressDoneCount ;

        when GET_WRITE_TRANSACTION_COUNT =>
          TransRec.IntFromModel <= WriteAddressDoneCount ;

        when GET_READ_TRANSACTION_COUNT =>
          TransRec.IntFromModel <= ReadAddressDoneCount ;

        -- Model Transaction Dispatch
        when WRITE_OP | WRITE_ADDRESS | WRITE_DATA | ASYNC_WRITE | ASYNC_WRITE_ADDRESS | ASYNC_WRITE_DATA =>
          -- For All Write Operations - Write Address and Write Data
          LAW.Addr  := SafeResize(TransRec.Address, LAW.Addr'length) ;
          WriteByteAddr := CalculateByteAddress(LAW.Addr, AXI_BYTE_ADDR_WIDTH) ;

          if IsWriteAddress(Operation) then
            -- AlertIf(ModelID, TransRec.AddrWidth /= AXI_ADDR_WIDTH, "Write Address length does not match", FAILURE) ;

            -- Initiate Write Address
            Push(WriteAddressFifo, LAW.Addr & LAW.Prot) ; 
            Increment(WriteAddressRequestCount) ;
          end if ;

          if IsWriteData(Operation) then
            -- Single Transfer Write Data Handling
            CheckDataIsBytes(ModelID, TransRec.DataWidth, "Manager Write: ", WriteDataRequestCount+1) ;
            CheckDataWidth  (ModelID, TransRec.DataWidth, WriteByteAddr, AXI_DATA_WIDTH, "Manager Write: ", WriteDataRequestCount+1) ;
            LWD.Data  := AlignBytesToDataBus(SafeResize(TransRec.DataToModel, LWD.Data'length), TransRec.DataWidth, WriteByteAddr) ;
            LWD.Strb  := CalculateWriteStrobe(LWD.Data) ;
--            Push(WriteDataFifo, '0' & '1' & LWD.Data & LWD.Strb) ;
            Push(WriteDataFifo, LWD.Data & LWD.Strb) ;

            Increment(WriteDataRequestCount) ;
            WriteDataCount := WriteDataCount + 1; 
          end if ;
          
          -- Allow RequestCounts to update
          wait for 0 ns ;  

--!! If burst emulation is added, then this will need to be a while loop since
--!! more than one transaction will be dispatched at a time.
          if WriteAddressRequestCount /= WriteResponseExpectCount and
             WriteDataCount           /= WriteResponseExpectCount 
          then
            -- Queue Expected Write Response
            Push(WriteResponseScoreboard, LWR.Resp) ;
            Increment(WriteResponseExpectCount) ;
          end if ;
          
          if IsBlockOnWriteAddress(Operation) and
              WriteAddressRequestCount /= WriteAddressDoneCount then
            -- Block until both write address done.
            wait until WriteAddressRequestCount = WriteAddressDoneCount ;
          end if ;
          if IsBlockOnWriteData(Operation) and
              WriteDataRequestCount /= WriteDataDoneCount then
            -- Block until both write data done.
            wait until WriteDataRequestCount = WriteDataDoneCount ;
          end if ;


        -- Model Transaction Dispatch
        when WRITE_BURST | ASYNC_WRITE_BURST =>
          LAW.Addr  := SafeResize(TransRec.Address, LAW.Addr'length) ;
          WriteByteAddr := CalculateByteAddress(LAW.Addr, AXI_BYTE_ADDR_WIDTH);
          BytesPerTransfer := AXI_DATA_BYTE_WIDTH ;
--!!          BytesPerTransfer := 2**to_integer(LAW.Size);
--            AlertIf(ModelID, BytesPerTransfer /= AXI_DATA_BYTE_WIDTH,
--              "Write Bytes Per Transfer (" & to_string(BytesPerTransfer) & ") " &
--              "/= AXI_DATA_BYTE_WIDTH (" & to_string(AXI_DATA_BYTE_WIDTH) & ")"
--            );

          if IsWriteAddress(Operation) then
            -- Write Address Handling
--!! Translate into multiple single cycle addresses          
--!!            -- Burst transfer, calculate burst length
--!!            if BurstFifoByteMode then 
--!!              LAW.Len := to_slv(CalculateBurstLen(TransRec.DataWidth, WriteByteAddr, BytesPerTransfer), LAW.Len'length) ;
--!!            else 
--!!              LAW.Len := to_slv(TransRec.DataWidth-1, LAW.Len'length) ;
--!!            end if ;

            -- Initiate Write Address
            Push(WriteAddressFifo, LAW.Addr  & LAW.Prot) ;

            Increment(WriteAddressRequestCount) ;
          end if ;

          if IsWriteData(Operation) then
            if BurstFifoByteMode then 
              BytesToSend       := TransRec.DataWidth ;
              TransfersInBurst  := 1 + CalculateBurstLen(BytesToSend, WriteByteAddr, BytesPerTransfer) ;
            else
              TransfersInBurst := TransRec.DataWidth ;
            end if ; 
            
            PopWriteBurstData(TransRec.WriteBurstFifo, BurstFifoMode, LWD.Data, LWD.Strb, BytesToSend, WriteByteAddr) ;

            for BurstLoop in TransfersInBurst downto 2 loop    
--              Push(WriteDataFifo, '1' & '0' & LWD.Data & LWD.Strb) ;
              Push(WriteDataFifo, LWD.Data & LWD.Strb) ;
              PopWriteBurstData(TransRec.WriteBurstFifo, BurstFifoMode, LWD.Data, LWD.Strb, BytesToSend, 0) ;
            end loop ; 
            
            -- Special handle last push
--            Push(WriteDataFifo, '1' & '1' & LWD.Data & LWD.Strb) ;
            Push(WriteDataFifo, LWD.Data & LWD.Strb) ;

            -- Increment(WriteDataRequestCount) ;
            WriteDataRequestCount        <= Increment(WriteDataRequestCount, TransfersInBurst) ;
            WriteDataCount := WriteDataCount + 1; 
          end if ;

          -- Allow RequestCounts to update
          wait for 0 ns ;  

--!! will need to be a while loop if more than one transaction can be dispatched at a time.
--!! only happens if bursts are emulated - ie translated from a burst cycle to a multiple individual cycles
          if WriteAddressRequestCount /= WriteResponseExpectCount and 
             WriteDataCount           /= WriteResponseExpectCount 
          then
            -- Queue Expected Write Response
            Push(WriteResponseScoreboard, LWR.Resp) ;
            Increment(WriteResponseExpectCount) ;
          end if ;

          if IsBlockOnWriteAddress(Operation) and
              WriteAddressRequestCount /= WriteAddressDoneCount then
            -- Block until write address done.
            wait until WriteAddressRequestCount = WriteAddressDoneCount ;
          end if ;
          if IsBlockOnWriteData(Operation) and
              WriteDataRequestCount /= WriteDataDoneCount then
            -- Block until write data done.
            wait until WriteDataRequestCount = WriteDataDoneCount ;
          end if ;

        when READ_OP | READ_CHECK | READ_ADDRESS | READ_DATA | READ_DATA_CHECK | ASYNC_READ_ADDRESS | ASYNC_READ_DATA | ASYNC_READ_DATA_CHECK =>
          if IsReadAddress(Operation) then
            -- Send Read Address to Read Address Handler and Read Data Handler
            LAR.Addr   :=  SafeResize(TransRec.Address, LAR.Addr'length) ;
            ReadByteAddr  :=  CalculateByteAddress(LAR.Addr, AXI_BYTE_ADDR_WIDTH);
--             AlertIf(ModelID, TransRec.AddrWidth /= AXI_ADDR_WIDTH, "Read Address length does not match", FAILURE) ;
--            BytesPerTransfer := 2**to_integer(LAR.Size);
            BytesPerTransfer := AXI_DATA_BYTE_WIDTH ;

            Push(ReadAddressFifo, LAR.Addr & LAR.Prot) ;
            Push(ReadAddressTransactionFifo, LAR.Addr & LAR.Prot);
            Increment(ReadAddressRequestCount) ;

            -- Expect a Read Data Cycle
            Push(ReadResponseScoreboard, LRD.Resp) ;
            increment(ReadDataExpectCount) ;
          end if ;
          wait for 0 ns ; 

          if IsTryReadData(Operation) and Empty(ReadDataFifo) then
            -- Data not available
            -- ReadDataReceiveCount < ReadDataTransactionCount then
            TransRec.BoolFromModel <= FALSE ;
            TransRec.DataFromModel <= (TransRec.DataFromModel'range => '0') ; 
          elsif IsReadData(Operation) then
            (LAR.Addr, ReadProt) := Pop(ReadAddressTransactionFifo) ;
            ReadByteAddr  :=  CalculateByteAddress(LAR.Addr, AXI_BYTE_ADDR_WIDTH);

            -- Wait for Data Ready
            if Empty(ReadDataFifo) then
              WaitForToggle(ReadDataReceiveCount) ;
            end if ;
            TransRec.BoolFromModel <= TRUE ;

            -- Get Read Data
            LRD.Data := Pop(ReadDataFifo) ;
            CheckDataIsBytes(ModelID, TransRec.DataWidth, "Manager Read: ", ReadDataExpectCount) ;
            CheckDataWidth  (ModelID, TransRec.DataWidth, ReadByteAddr, AXI_DATA_WIDTH, "Manager Read: ", ReadDataExpectCount) ;
            LRD.Data := AlignDataBusToBytes(LRD.Data, TransRec.DataWidth, ReadByteAddr) ;
--            AxiReadDataAlignCheck (ModelID, LRD.Data, TransRec.DataWidth, LAR.Addr, AXI_DATA_BYTE_WIDTH, AXI_BYTE_ADDR_WIDTH) ;
            TransRec.DataFromModel <= SafeResize(LRD.Data, TransRec.DataFromModel'length) ;

            -- Check or Log Read Data
            if IsReadCheck(TransRec.Operation) then
              ExpectedData := SafeResize(TransRec.DataToModel, ExpectedData'length) ;
  --!!9 TODO:  Change format to Transaction #, Address, Prot, Read Data
  --!! Run regressions before changing
              AffirmIf( DataCheckID, LRD.Data = ExpectedData,
                "Read Data: " & to_hxstring(LRD.Data) &
                "  Read Address: " & to_hxstring(LAR.Addr) &
                "  Prot: " & to_hxstring(ReadProt),
                "  Expected: " & to_hxstring(ExpectedData),
                TransRec.StatusMsgOn or IsLogEnabled(ModelID, INFO) ) ;
            else
  --!!9 TODO:  Change format to Transaction #, Address, Prot, Read Data
  --!! Run regressions before changing
              Log( ModelID,
                "Read Data: " & to_hxstring(LRD.Data) &
                "  Read Address: " & to_hxstring(LAR.Addr) &
                "  Prot: " & to_hxstring(ReadProt),
                INFO,
                TransRec.StatusMsgOn
              ) ;
            end if ;
          end if ;

          -- Transaction wait time
          wait for 0 ns ;  wait for 0 ns ;

        when READ_BURST =>
          if IsReadAddress(Operation) then
            -- Send Read Address to Read Address Handler and Read Data Handler
            LAR.Addr   :=  SafeResize(TransRec.Address, LAR.Addr'length) ;
            ReadByteAddr  :=  CalculateByteAddress(LAR.Addr, AXI_BYTE_ADDR_WIDTH);
--            AlertIf(ModelID, TransRec.AddrWidth /= AXI_ADDR_WIDTH, "Read Address length does not match", FAILURE) ;
--            BytesPerTransfer := 2**to_integer(LAR.Size);
            BytesPerTransfer := AXI_DATA_BYTE_WIDTH ;

            -- Burst transfer, calculate burst length
            if BurstFifoByteMode then 
              TransfersInBurst := 1 + CalculateBurstLen(TransRec.DataWidth, ReadByteAddr, BytesPerTransfer) ;
            else 
              TransfersInBurst := TransRec.DataWidth ; 
            end if ;

            Push(ReadAddressFifo, LAR.Addr & LAR.Prot) ; 
            Push(ReadAddressTransactionFifo, LAR.Addr & LAR.Prot);
            Increment(ReadAddressRequestCount) ;

            -- Expect a Read Data Cycle
            for i in 1 to TransfersInBurst loop
              Push(ReadResponseScoreboard, LRD.Resp) ;
            end loop ;
  -- Should this be + TransfersInBurst ; ???
--            ReadDataExpectCount <= Increment(ReadDataExpectCount, TransfersInBurst) ;
            ReadDataExpectCount <= ReadDataExpectCount + 1 ;
          end if ;

  --!!3 Implies that any separate ReadDataBurst or TryReadDataBurst
  --!!3 must include the transfer length and for Try
  --!!3 if ReadDataFifo has that number of transfers.
  --!!3 First Check IsReadData, then Calculate #Transfers,
  --!!3 Then if TryRead, and ReadDataFifo.FifoCount < #Transfers, then FALSE
  --!!3 Which reverses the order of the following IF statements
          if IsTryReadData(Operation) and Empty(ReadDataFifo) then
            -- Data not available
            -- ReadDataReceiveCount < ReadDataTransactionCount then
            TransRec.BoolFromModel <= FALSE ;
          elsif IsReadData(Operation) then
            TransRec.BoolFromModel <= TRUE ;
            (LAR.Addr, ReadProt) := Pop(ReadAddressTransactionFifo) ;
            ReadByteAddr := CalculateByteAddress(LAR.Addr, AXI_BYTE_ADDR_WIDTH);
            BytesPerTransfer  := AXI_DATA_BYTE_WIDTH ;
--!!            BytesPerTransfer := 2**to_integer(LAR.Size);

--!!            AlertIf(ModelID, BytesPerTransfer /= AXI_DATA_BYTE_WIDTH,
--!!              "Write Bytes Per Transfer (" & to_string(BytesPerTransfer) & ") " &
--!!              "/= AXI_DATA_BYTE_WIDTH (" & to_string(AXI_DATA_BYTE_WIDTH) & ")"
--!!            );

            if BurstFifoByteMode then 
              BytesToReceive    := TransRec.DataWidth ;
              TransfersInBurst  := 1 + CalculateBurstLen(BytesToReceive, ReadByteAddr, BytesPerTransfer) ;
            else
              TransfersInBurst  := TransRec.DataWidth ;
            end if ; 

            for BurstLoop in 1 to TransfersInBurst loop
              if Empty(ReadDataFifo) then
                WaitForToggle(ReadDataReceiveCount) ;
              end if ;
              LRD.Data := Pop(ReadDataFifo) ;
              
              PushReadBurstData(TransRec.ReadBurstFifo, BurstFifoMode, LRD.Data, BytesToReceive, ReadByteAddr) ;
              ReadByteAddr := 0 ;
            end loop ;
          end if ;

        -- Model Configuration Options
        when SET_MODEL_OPTIONS =>
          Axi4Option := Axi4OptionsType'val(TransRec.Options) ;
          if IsAxiInterface(Axi4Option) then
            SetAxi4LiteInterfaceDefault(AxiDefaults, Axi4Option, TransRec.IntToModel) ;
          else
            SetAxi4Parameter(Params, Axi4Option, TransRec.IntToModel) ;
          end if ;

        when GET_MODEL_OPTIONS =>
          Axi4Option := Axi4OptionsType'val(TransRec.Options) ;
          if IsAxiInterface(Axi4Option) then
            TransRec.IntFromModel <= GetAxi4LiteInterfaceDefault(AxiDefaults, Axi4Option) ;
          else
            GetAxi4Parameter(Params, Axi4Option, Axi4OptionVal) ;
            TransRec.IntFromModel <= Axi4OptionVal ;
          end if ;

        when MULTIPLE_DRIVER_DETECT =>
          Alert(ModelID, "Multiple Drivers on Transaction Record." & 
                         "  Transaction # " & to_string(TransRec.Rdy), FAILURE) ;

        when others =>
          Alert(ModelID, "Unimplemented Transaction: " & to_string(TransRec.Operation), FAILURE) ;
      end case ;
    end loop ;
  end process TransactionDispatcher ;

  ------------------------------------------------------------
  --  WriteAddressHandler
  --    Execute Write Address Transactions
  ------------------------------------------------------------
  WriteAddressHandler : process
    alias    AW    : AxiBus.WriteAddress'subtype is AxiBus.WriteAddress ;
    variable Local : AxiBus.WriteAddress'subtype ;
    variable WriteAddressReadyTimeOut : integer ;
  begin
    -- AXI4 Lite Signaling
    AW.Valid  <= '0' ;
    AW.Addr   <= (Local.Addr'range   => '0') ;
    AW.Prot   <= (Local.Prot'range   => '0') ;
    wait for 0 ns ; -- Allow WriteAddressFifo to initialize

    WriteAddressLoop : loop
      -- Find Transaction
      if Empty(WriteAddressFifo) then
         WaitForToggle(WriteAddressRequestCount) ;
      end if ;
      (Local.Addr, Local.Prot) := Pop(WriteAddressFifo) ;

      WaitForClock(Clk, integer'(Params.Get(Axi4OptionsType'POS(WRITE_ADDRESS_VALID_DELAY_CYCLES)))) ; 

      -- Do Transaction
      AW.Addr   <= Local.Addr      after tpd_Clk_AWAddr   ;
      AW.Prot   <= Local.Prot      after tpd_clk_AWProt   ;

      Log(ModelID,
        "Write Address." &
        "  AWAddr: "  & to_hxstring(Local.Addr) &
        "  AWProt: "  & to_string(Local.Prot) &
        "  Operation# " & to_string(WriteAddressDoneCount + 1),
        INFO
      ) ;

      GetAxi4Parameter(Params, WRITE_ADDRESS_READY_TIME_OUT, WriteAddressReadyTimeOut) ;

      ---------------------
      DoAxiValidHandshake (
      ---------------------
        Clk            =>  Clk,
        Valid          =>  AxiBus.WriteAddress.Valid,  --!GHDL
        Ready          =>  AxiBus.WriteAddress.Ready,  --!GHDL
        tpd_Clk_Valid  =>  tpd_Clk_AWValid,
        AlertLogID     =>  BusFailedID,
        TimeOutMessage =>  "Write Address # " & to_string(WriteAddressDoneCount + 1),
        TimeOutPeriod  =>  WriteAddressReadyTimeOut * tperiod_Clk
      ) ;

      -- State after operation
      AW.Addr   <= Local.Addr   + 4  after tpd_Clk_AWAddr   ;
      AW.Prot   <= Local.Prot   + 1  after tpd_clk_AWProt   ;
      -- Signal completion
      Increment(WriteAddressDoneCount) ;
      wait for 0 ns ;
    end loop WriteAddressLoop ;
  end process WriteAddressHandler ;

  ------------------------------------------------------------
  --  WriteDataHandler
  --    Execute Write Data Transactions
  ------------------------------------------------------------
  WriteDataHandler : process
    alias    WD : AxiBus.WriteData'subtype is AxiBus.WriteData ;

    variable Local : AxiBus.WriteData'subtype ;
    
    variable WriteDataReadyTimeOut : integer ;
  begin
    -- initialize
    WD.Valid <= '0' ;
    WD.Data  <= (Local.Data'range => '0') ;
    WD.Strb  <= (Local.Strb'range => '0') ;
    wait for 0 ns ; -- Allow WriteDataFifo to initialize

    WriteDataLoop : loop
      -- Find Transaction
      if Empty(WriteDataFifo) then
         WaitForToggle(WriteDataRequestCount) ;
      end if ;
--!!      (Burst, Local.Last, Local.Data, Local.Strb) := Pop(WriteDataFifo) ;
      (Local.Data, Local.Strb) := Pop(WriteDataFifo) ;
            
      WaitForClock(Clk, integer'(Params.Get(Axi4OptionsType'POS(WRITE_DATA_VALID_DELAY_CYCLES)))) ; 

      -- Do Transaction
      WD.Data  <= Local.Data after tpd_clk_WStrb ;
      WD.Strb  <= Local.Strb after tpd_Clk_WData ;

      Log(ModelID,
        "Write Data." &
        "  WData: "  & to_hxstring(Local.Data) &
        "  WStrb: "  & to_string( Local.Strb) &
        "  Operation# " & to_string(WriteDataDoneCount + 1),
        INFO
      ) ;

      GetAxi4Parameter(Params, WRITE_DATA_READY_TIME_OUT, WriteDataReadyTimeOut) ;

      ---------------------
      DoAxiValidHandshake (
      ---------------------
        Clk            =>  Clk,
        Valid          =>  AxiBus.WriteData.Valid,  --!GHDL
        Ready          =>  AxiBus.WriteData.Ready,  --!GHDL
        tpd_Clk_Valid  =>  tpd_Clk_WValid,
        AlertLogID     =>  BusFailedID,
        TimeOutMessage =>  "Write Data # " & to_string(WriteDataDoneCount + 1),
        TimeOutPeriod  =>  WriteDataReadyTimeOut * tperiod_Clk
      ) ;

      -- State after operation
      WD.Data  <= not Local.Data      after tpd_Clk_WData ;
      WD.Strb  <= Local.Strb          after tpd_clk_WStrb ; -- allow writes

      -- Signal completion
      Increment(WriteDataDoneCount) ;
      wait for 0 ns ;
    end loop WriteDataLoop ;
  end process WriteDataHandler ;

  ------------------------------------------------------------
  -- WriteResponseHandler
  --   Receive and Check Write Responses
  ------------------------------------------------------------
  WriteResponseHandler : process
    variable WriteResponseReadyBeforeValid  : boolean ;
    variable WriteResponseReadyDelayCycles  : integer ;
    variable WriteResponseValidTimeOut : integer ;
  begin
    -- initialize
    AxiBus.WriteResponse.Ready <= '0' ;
    wait for 0 ns ; -- Allow WriteResponseScoreboard to initialize

    WriteResponseOperation : loop
      -- Find Expected Transaction
      WriteResponseActive <= FALSE ;
      if empty(WriteResponseScoreboard) then
        WaitForToggle(WriteResponseExpectCount) ;
      end if ;
      WriteResponseActive <= TRUE ;

      Log(ModelID, "Waiting for Write Response.", DEBUG) ;


      GetAxi4Parameter(Params, WRITE_RESPONSE_READY_BEFORE_VALID, WriteResponseReadyBeforeValid) ;
      GetAxi4Parameter(Params, WRITE_RESPONSE_READY_DELAY_CYCLES, WriteResponseReadyDelayCycles) ;
      GetAxi4Parameter(Params, WRITE_RESPONSE_VALID_TIME_OUT,     WriteResponseValidTimeOut) ;

      ---------------------
      DoAxiReadyHandshake (
      ---------------------
        Clk                     => Clk,
        Valid                   => AxiBus.WriteResponse.Valid,
        Ready                   => AxiBus.WriteResponse.Ready,
        ReadyBeforeValid        => WriteResponseReadyBeforeValid,
        ReadyDelayCycles        => WriteResponseReadyDelayCycles * tperiod_Clk,
        tpd_Clk_Ready           => tpd_Clk_BReady,
        AlertLogID              => BusFailedID,
        TimeOutMessage          => "Write Response # " & to_string(WriteResponseReceiveCount + 1),
        TimeOutPeriod           => WriteResponseValidTimeOut * tperiod_Clk
      ) ;

      -- Check Write Response
      Check(WriteResponseScoreboard, AxiBus.WriteResponse.Resp) ;

      -- Signal Completion
      increment(WriteResponseReceiveCount) ;
      wait for 0 ns ;
    end loop WriteResponseOperation ;
  end process WriteResponseHandler ;


  ------------------------------------------------------------
  --  WriteResponseProtocolChecker
  --    Error if Write Response BValid happens without a Write cycle
  ------------------------------------------------------------
  WriteResponseProtocolChecker : process
  begin
    wait on Clk until Clk = '1' and AxiBus.WriteResponse.Valid = '1' ;
    AlertIf(ProtocolID, not WriteResponseActive,
      "Unexpected Write Response Cycle. " &
      " BValid: " & to_string(AxiBus.WriteResponse.Valid) &
      " BResp: "  & to_string(AxiBus.WriteResponse.Resp) &
      "  Operation# " & to_string(WriteResponseReceiveCount + 1),
      FAILURE
    ) ;
  end process WriteResponseProtocolChecker ;

  ------------------------------------------------------------
  --  ReadAddressHandler
  --    Execute Read Address Transactions
  ------------------------------------------------------------
  ReadAddressHandler : process
    alias    AR : AxiBus.ReadAddress'subtype is AxiBus.ReadAddress ;

    variable Local : AxiBus.ReadAddress'subtype ;

    variable ReadAddressReadyTimeOut : integer ;
  begin
    -- AXI4 Lite Signaling
    AR.Valid  <= '0' ;
    AR.Addr   <= (Local.Addr'range   => '0') ;
    AR.Prot   <= (Local.Prot'range   => '0') ;
    wait for 0 ns ; -- Allow ReadAddressFifo to initialize


    AddressReadLoop : loop
      -- Find Transaction
      if Empty(ReadAddressFifo) then
         WaitForToggle(ReadAddressRequestCount) ;
      end if ;
      (Local.Addr, Local.Prot) := Pop(ReadAddressFifo) ;

      WaitForClock(Clk, integer'(Params.Get(Axi4OptionsType'POS(READ_ADDRESS_VALID_DELAY_CYCLES)))) ; 

      -- Do Transaction
      AR.Addr   <= Local.Addr   after tpd_Clk_ARAddr   ;
      AR.Prot   <= Local.Prot   after tpd_clk_ARProt   ;

      Log(ModelID,
        "Read Address." &
        "  ARAddr: "  & to_hxstring(Local.Addr) &
        "  ARProt: "  & to_string( Local.Prot) &
        "  Operation# " & to_string(ReadAddressDoneCount + 1),
        INFO
      ) ;

      GetAxi4Parameter(Params, READ_ADDRESS_READY_TIME_OUT, ReadAddressReadyTimeOut) ;

      ---------------------
      DoAxiValidHandshake (
      ---------------------
        Clk            =>  Clk,
        Valid          =>  AxiBus.ReadAddress.Valid,
        Ready          =>  AxiBus.ReadAddress.Ready,
        tpd_Clk_Valid  =>  tpd_Clk_ARValid,
        AlertLogID     =>  BusFailedID,
        TimeOutMessage =>  "Read Address # " & to_string(ReadAddressDoneCount + 1),
        TimeOutPeriod  =>  ReadAddressReadyTimeOut * tperiod_Clk
      ) ;

      -- State after operation
      AR.Addr   <= Local.Addr   + 4  after tpd_Clk_ARAddr   ;
      AR.Prot   <= Local.Prot   + 1  after tpd_clk_ARProt   ;

      -- Signal completion
      Increment(ReadAddressDoneCount) ;
      wait for 0 ns;
    end loop AddressReadLoop ;
  end process ReadAddressHandler ;


  ------------------------------------------------------------
  --  ReadDataHandler
  --    Receive Read Data Transactions
  ------------------------------------------------------------
  ReadDataHandler : process
    variable ReadDataReadyBeforeValid : boolean ;
    variable ReadDataReadyDelayCycles : integer ;
    variable ReadDataValidTimeOut     : integer ;
  begin
    AxiBus.ReadData.Ready <= '0' ;
    WaitForClock(Clk, 2) ;  -- Initialize

    ReadDataOperation : loop
      -- Find Expected Transaction
      ReadDataActive <= FALSE ;
      if ReadDataReceiveCount >= ReadDataExpectCount then
        WaitForToggle(ReadDataExpectCount) ;
      end if ;
      ReadDataActive <= TRUE ;

      GetAxi4Parameter(Params, READ_DATA_READY_BEFORE_VALID, ReadDataReadyBeforeValid) ;
      GetAxi4Parameter(Params, READ_DATA_READY_DELAY_CYCLES, ReadDataReadyDelayCycles) ;
      GetAxi4Parameter(Params, READ_DATA_VALID_TIME_OUT,     ReadDataValidTimeOut) ;

      ---------------------
      DoAxiReadyHandshake (
      ---------------------
        Clk                     => Clk,
        Valid                   => AxiBus.ReadData.Valid,
        Ready                   => AxiBus.ReadData.Ready,
        ReadyBeforeValid        => ReadDataReadyBeforeValid,
        ReadyDelayCycles        => ReadDataReadyDelayCycles * tperiod_Clk,
        tpd_Clk_Ready           => tpd_Clk_RReady,
        AlertLogID              => BusFailedID,
        TimeOutMessage          => "Read Data # " & to_string(ReadDataReceiveCount + 1),
        TimeOutPeriod           => ReadDataValidTimeOut * tperiod_Clk
      ) ;

      -- capture data
      push(ReadDataFifo, AxiBus.ReadData.Data) ;
      Check(ReadResponseScoreboard, AxiBus.ReadData.Resp) ;

      increment(ReadDataReceiveCount) ;
      wait for 0 ns ; -- Allow ReadDataReceiveCount to update
    end loop ReadDataOperation ;
  end process ReadDataHandler ;

  ------------------------------------------------------------
  --  ReadDataProtocolChecker
  --    Receive Read Data Transactions
  ------------------------------------------------------------
  ReadDataProtocolChecker : process
  begin
    wait on Clk until Clk = '1' and AxiBus.ReadData.Valid = '1' ;
    AlertIf(ProtocolID, not ReadDataActive,
      "Unexpected Read Data Cycle. " &
      " RValid: " & to_string (AxiBus.ReadData.Valid) &
      " RData: "  & to_hxstring(AxiBus.ReadData.Data) &
      " RResp: "  & to_string (AxiBus.ReadData.Resp) &
      "  Operation# " & to_string(ReadDataReceiveCount + 1),
      FAILURE
    ) ;
  end process ReadDataProtocolChecker ;
end architecture behavioral ;
