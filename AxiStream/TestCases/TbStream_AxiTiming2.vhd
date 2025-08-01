--
--  File Name:         TbStream_AxiTiming2.vhd
--  Design Unit Name:  Architecture of TestCtrl
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Set AXI Ready Time.   Check Timeout on Valid (nominally large or infinite?)
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date      Version    Description
--    10/2020   2020.10    Initial revision
--
--
--  This file is part of OSVVM.
--  
--  Copyright (c) 2018 - 2020 by SynthWorks Design Inc.  
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
architecture AxiTiming2 of TestCtrl is

  signal TestDone, TestPhaseStart : integer_barrier := 1 ;
   
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("TbStream_AxiTiming2") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable INFO logs
    SetAlertStopCount(FAILURE, integer'right) ;  -- Allow FAILURES

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 35 ms) ;
    
    TranscriptClose ; 
    if CHECK_TRANSCRIPT then 
      AffirmIfTranscriptsMatch(PATH_TO_VALIDATED_RESULTS) ; 
    end if ;   
   
    EndOfTestReports(TimeOut => (now >= 35 ms)) ; 
    std.env.stop ; 
    wait ; 
  end process ControlProc ; 

  
  ------------------------------------------------------------
  -- AxiTransmitterProc
  --   Generate transactions for AxiTransmitter
  ------------------------------------------------------------
  AxiTransmitterProc : process
    variable Data : std_logic_vector(DATA_WIDTH-1 downto 0) ;
  begin
    wait until nReset = '1' ;  
    WaitForClock(StreamTxRec, 2) ; 
    
log("Ready before Valid Tests.") ;
WaitForBarrier(TestPhaseStart) ;
    -- Cycle to allow settings to update
    WaitForClock(StreamTxRec, 5) ; 
    Data := (others => '0') ;
    Send(StreamTxRec,  Data) ;  

    Data := Data + 4096 ;
    for i in 0 to 4 loop 
      WaitForClock(StreamTxRec, 5) ; 
    
      for j in 1 to 3 loop 
        Send(StreamTxRec,  Data) ;  
        Data := Data + 1 ; 
      end loop ; 
      Data := Data + 253 ; 
    end loop ; 
          
log("Ready after Valid Tests.") ;
WaitForBarrier(TestPhaseStart) ;
    -- Cycle to allow settings to update
    WaitForClock(StreamTxRec, 5) ; 
    Data := (others => '0') ;
    Send(StreamTxRec,  Data) ;  

    Data := Data + 8192 ;
    for i in 0 to 4 loop 
      WaitForClock(StreamTxRec, 5) ; 
    
      for j in 1 to 3 loop 
        Send(StreamTxRec,  Data) ;  
        Data := Data + 1 ; 
      end loop ; 
      Data := Data + 253 ; 
    end loop ; 
       
    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(StreamTxRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process AxiTransmitterProc ;


  ------------------------------------------------------------
  -- AxiReceiverProc
  --   Generate transactions for AxiReceiver
  ------------------------------------------------------------
  AxiReceiverProc : process
    variable Data : std_logic_vector(DATA_WIDTH-1 downto 0) ;  
  begin
    WaitForClock(StreamRxRec, 2) ; 
    
-- Start test phase 1:  
WaitForBarrier(TestPhaseStart) ;
-- log("Ready before Valid Tests.") ;
SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_BEFORE_VALID, TRUE) ;
    -- Cycle to allow settings to update
    -- WaitForClock(StreamRxRec, 5) ; 
    Data := (others => '0') ;
    Check(StreamRxRec,   Data) ;  

    Data := Data + 4096 ;
    for i in 0 to 4 loop 
      SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_DELAY_CYCLES, i) ;
      -- WaitForClock(StreamRxRec, 5) ; 
    
      for j in 1 to 3 loop 
        Check(StreamRxRec,  Data) ;  
        Data := Data + 1 ; 
      end loop ; 
      Data := Data + 253 ; 
    end loop ; 
          
WaitForBarrier(TestPhaseStart) ;
-- log("Ready after Valid Tests.") ;
    SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_BEFORE_VALID, FALSE) ;
    SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_DELAY_CYCLES, 0) ;
    -- Cycle to allow settings to update
    -- WaitForClock(StreamRxRec, 5) ; 
    Data := (others => '0') ;
    Check(StreamRxRec,   Data) ;  

    Data := Data + 8192 ;
    for i in 0 to 4 loop 
      SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_DELAY_CYCLES, i) ;
      -- WaitForClock(StreamRxRec, 5) ; 

      for j in 1 to 3 loop 
        Check(StreamRxRec,  Data) ;  
        Data := Data + 1 ; 
      end loop ; 
      Data := Data + 253 ; 
    end loop ;   
     
    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(StreamRxRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process AxiReceiverProc ;

end AxiTiming2 ;

Configuration TbStream_AxiTiming2 of TbStream is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(AxiTiming2) ; 
    end for ; 
  end for ; 
end TbStream_AxiTiming2 ; 