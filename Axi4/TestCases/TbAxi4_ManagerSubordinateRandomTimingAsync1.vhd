--
--  File Name:         TbAxi4_ManagerSubordinateRandomTimingAsync1.vhd
--  Design Unit Name:  Architecture of TestCtrl
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Testing of Burst Features in AXI Model
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date      Version    Description
--    05/2023   2023.05    Initial revision
--
--
--  This file is part of OSVVM.
--
--  Copyright (c) 2023 by SynthWorks Design Inc.
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

architecture ManagerSubordinateRandomTimingAsync1 of TestCtrl is

  signal SyncPoint, TestDone, WriteDone : integer_barrier := 1 ;
  constant BURST_MODE : AddressBusFifoBurstModeType := ADDRESS_BUS_BURST_WORD_MODE ;
--  constant BURST_MODE : AddressBusFifoBurstModeType := ADDRESS_BUS_BURST_BYTE_MODE ;
  constant DATA_WIDTH : integer := IfElse(BURST_MODE = ADDRESS_BUS_BURST_BYTE_MODE, 8, AXI_DATA_WIDTH)  ;

begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("TbAxi4_ManagerSubordinateRandomTimingAsync1") ;
    SetLogEnable(PASSED, TRUE) ;   -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;     -- Enable INFO logs
    -- SetLogEnable(DEBUG, TRUE) ;    -- Enable INFO logs

    -- Wait for testbench initialization
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen ;
    SetTranscriptMirror(TRUE) ;
    SetAlertLogOptions(WriteTimeLast => FALSE) ; 
    SetAlertLogOptions(TimeJustifyAmount => 15) ; 
    SetAlertLogJustify ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 1 ms) ;

    TranscriptClose ;
    -- Printing differs in different simulators due to differences in process order execution
    -- AffirmIfTranscriptsMatch(PATH_TO_VALIDATED_RESULTS) ;

    EndOfTestReports(TimeOut => (now >= 1 ms)) ; 
    std.env.stop ;
    wait ;
  end process ControlProc ;

  ------------------------------------------------------------
  -- ManagerProc
  --   Generate transactions for AxiManager
  ------------------------------------------------------------
  ManagerProc : process
    variable BurstVal  : AddressBusFifoBurstModeType ;
    variable RxData    : std_logic_vector(31 downto 0) ;
    constant DATA_ZERO : std_logic_vector := (DATA_WIDTH - 1 downto 0 => '0') ;
    variable CoverID1, CoverID2 : CoverageIdType ;
    variable slvBurstVector : slv_vector(1 to 5)(31 downto 0) ;
    variable intBurstVector : integer_vector(1 to 5) ;
    variable DelayCov       : AxiDelayCoverageIdArrayType ; 
  begin
    wait until nReset = '1' ;
    WaitForClock(ManagerRec, 2) ;

    -- Use Coverage based delays
    SetUseRandomDelays(ManagerRec) ; 


-- Write and ReadCheck
    BlankLine ; 
    Print("-----------------------------------------------------------------") ;
    log("Write and ReadCheck. Addr = 0000_0000 + 16*i.  32 words") ;
    BlankLine ; 
    for I in 1 to 128 loop
      WriteAsync( ManagerRec, X"0000_0000" + 16*I, X"0000_0000" + I ) ;
    end loop ;
    
    -- Let some number of Write Cycles complete before starting Read.   
    -- Reads will fail if this is too small
    WaitForClock(ManagerRec, 8) ;

    for I in 1 to 128 loop
      ReadAddressAsync ( ManagerRec, X"0000_0000" + 16*I) ;
    end loop ;
    
    for I in 1 to 128 loop
      ReadCheckData ( ManagerRec, X"0000_0000" + I ) ;
    end loop ;

    WaitForTransaction(ManagerRec) ; 
    WaitForClock(ManagerRec, 2) ;

-- Subordinate does not currently support bursting
--
--  -- Burst Increment
--      BlankLine ; 
--      Print("-----------------------------------------------------------------") ;
--      log("Burst Increment.  Addr = 0000_1000, 6 Word bursts -- word aligned") ;
--      BlankLine ; 
--  
--      WaitForBarrier(SyncPoint) ; 
--  --    -- Make burst length on address smaller s.t. burst address and data collide more.
--  --    GetDelayCoverageID(ManagerRec, DelayCov) ; 
--  --    DeallocateBins(DelayCov(WRITE_ADDRESS_ID).BurstLengthCov) ;  -- Remove old coverage model
--  --    AddBins(DelayCov(WRITE_ADDRESS_ID).BurstLengthCov, GenBin(2,4,1)) ; 
--  --    DeallocateBins(DelayCov(READ_ADDRESS_ID).BurstLengthCov) ;  -- Remove old coverage model
--  --    AddBins(DelayCov(READ_ADDRESS_ID).BurstLengthCov, GenBin(2,4,1)) ; 
--      WaitForBarrier(SyncPoint) ; 
--  
--      for i in 1 to 32 loop 
--        WriteBurstIncrement    (ManagerRec, X"0000_1000" + 256*I, X"0000_1000" + 256*I, 6) ;
--      end loop ;
--  
--      for I in 1 to 32 loop
--        ReadCheckBurstIncrement(ManagerRec, X"0000_1000" + 256*I, X"0000_1000" + 256*I, 6) ;
--      end loop ;

    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(ManagerRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process ManagerProc ;


  ------------------------------------------------------------
  -- SubordinateProc
  --   Generate transactions for AxiSubordinate
  ------------------------------------------------------------
  SubordinateProc : process
    variable Addr : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0) ;
    variable Data : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) ;
    variable DelayCov       : AxiDelayCoverageIdArrayType ; 
    variable ReadIndex, WriteIndex : integer ; 
    variable Available : boolean ; 
  begin
    SetUseRandomDelays(SubordinateRec) ; 
    GetDelayCoverageID(SubordinateRec, DelayCov) ; 
    DeallocateBins(DelayCov(WRITE_ADDRESS_ID).BurstLengthCov) ;  -- Remove old coverage model
    AddBins(DelayCov(WRITE_ADDRESS_ID).BurstLengthCov, GenBin(2,4,1)) ; 
    DeallocateBins(DelayCov(READ_ADDRESS_ID).BurstLengthCov) ;  -- Remove old coverage model
    AddBins(DelayCov(READ_ADDRESS_ID).BurstLengthCov, GenBin(2,4,1)) ; 
    WaitForClock(SubordinateRec, 2) ;
    
    WriteIndex := 1 ; 
    ReadIndex  := 1 ; 
    while WriteIndex <= 128 or ReadIndex <= 128 loop 
      TryGetWrite(SubordinateRec, Addr, Data, Available) ;
      if Available then 
        AffirmIfEqual(Addr, X"0000_0000" + 16*WriteIndex, "Subordinate Write Addr: ") ;
        AffirmIfEqual(Data, X"0000_0000" + WriteIndex, "Subordinate Write Data: ") ;
        WriteIndex := WriteIndex + 1 ; 
      end if ; 
      
      TrySendRead(SubordinateRec, Addr, X"0000_0000" + ReadIndex, Available) ; 
      if Available then 
        AffirmIfEqual(Addr, X"0000_0000" + 16*ReadIndex, "Subordinate Read Addr: ") ;
        ReadIndex := ReadIndex + 1 ; 
      end if ; 
      WaitForClock(SubordinateRec, 1) ; 
    end loop ; 


--  Subordinate does not currently support bursting
--
--    WaitForBarrier(SyncPoint) ; 
--    WaitForBarrier(SyncPoint) ; 
--
--    -- Check burst transactions
--
    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(SubordinateRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process SubordinateProc ;


end ManagerSubordinateRandomTimingAsync1 ;

Configuration TbAxi4_ManagerSubordinateRandomTimingAsync1 of TbAxi4 is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(ManagerSubordinateRandomTimingAsync1) ;
    end for ;
  end for ;
end TbAxi4_ManagerSubordinateRandomTimingAsync1 ;
