--
--  File Name:         TbStream_AxiBurstNoLast1.vhd
--  Design Unit Name:  Architecture of TestCtrl
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      GetBurst with no last, just ID and Dest changes
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
--  Copyright (c) 2020 by SynthWorks Design Inc.  
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
architecture AxiBurstNoLast1 of TestCtrl is

  signal   TestDone : integer_barrier := 1 ;
  
 
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("TbStream_AxiBurstNoLast1") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable INFO logs

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 5 ms) ;
    
    TranscriptClose ; 
    if CHECK_TRANSCRIPT then 
      AffirmIfTranscriptsMatch(PATH_TO_VALIDATED_RESULTS) ; 
    end if ;   
    
    EndOfTestReports(ExternalErrors => (FAILURE => 0, ERROR => -8, WARNING => 0), TimeOut => (now >= 5 ms)) ; -- expecting 8 errors from  
    std.env.stop ; 
    wait ; 
  end process ControlProc ; 

  
  ------------------------------------------------------------
  -- AxiTransmitterProc
  --   Generate transactions for AxiTransmitter
  ------------------------------------------------------------
  AxiTransmitterProc : process
    variable ID   : std_logic_vector(ID_LEN-1 downto 0) ;    -- 8
    variable Dest : std_logic_vector(DEST_LEN-1 downto 0) ;  -- 4
    variable User : std_logic_vector(USER_LEN-1 downto 0) ;  -- 4
    variable Data : std_logic_vector(DATA_WIDTH-1 downto 0) ;  
  begin
    wait until nReset = '1' ;  
    WaitForClock(StreamTxRec, 2) ; 
    SetBurstMode(StreamTxRec, STREAM_BURST_BYTE_MODE) ;
    
    ID   := to_slv(1, ID_LEN);
    Dest := to_slv(2, DEST_LEN) ; 
    User := to_slv(3, USER_LEN) ; 
    Data := (others => '0') ; 

    for i in 0 to 6 loop 
      log("Transmit " & to_string(32+5*i) & " Bytes. Starting with " & to_string(i*32)) ;
      ID    := ID + i mod 2 ; 
      Dest  := Dest + (i+1) mod 2 ; 
      for j in 0 to 31+5*i loop 
        Send(StreamTxRec, Data+(i*32+j), ID & Dest & User & '0') ;
      end loop ;
    end loop ; 
    
    Send(StreamTxRec, Data, (ID+2) & (Dest+2) & User & '0') ;

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
    variable NumBytes : integer ; 
    constant PARAM_LEN : integer := ID_LEN + DEST_LEN + USER_LEN + 1 ; 
    variable RxParam : std_logic_vector(PARAM_LEN-1 downto 0) ;
    alias RxID    : std_logic_vector(ID_LEN-1 downto 0) is RxParam(PARAM_LEN-1 downto PARAM_LEN-ID_LEN) ;
    alias RxDest  : std_logic_vector(DEST_LEN-1 downto 0) is RxParam(DEST_LEN-1 + USER_LEN+1 downto USER_LEN+1) ;
    alias RxUser  : std_logic_vector(USER_LEN-1 downto 0) is RxParam(USER_LEN downto 1) ;
    variable ID   : std_logic_vector(ID_LEN-1 downto 0) ;    -- 8
    variable Dest : std_logic_vector(DEST_LEN-1 downto 0) ;  -- 4
    variable User : std_logic_vector(USER_LEN-1 downto 0) ;  -- 4
    variable Data : std_logic_vector(DATA_WIDTH-1 downto 0) ;  
  begin
    WaitForClock(StreamRxRec, 2) ; 
    SetBurstMode(StreamRxRec, STREAM_BURST_WORD_MODE) ;
    
    ID   := to_slv(1, ID_LEN);
    Dest := to_slv(2, DEST_LEN) ; 
    User := to_slv(3, USER_LEN) ; 
    Data := (others => '0') ; 

    for i in 0 to 6 loop 
--      log("Transmit " & to_string(32+5*i) & " Bytes. Starting with " & to_string(i*32)) ;
      GetBurst (StreamRxRec, NumBytes, RxParam) ;
      AffirmIfEqual(NumBytes, 32 + 5*i, "Receiver: NumBytes Received") ;
      ID    := ID + i mod 2 ; 
      Dest  := Dest + (i+1) mod 2 ; 
      AffirmIfEqual(RxID,   ID,   "Receiver, ID: ") ; 
      AffirmIfEqual(RxDest, Dest, "Receiver, Dest: ") ; 
      AffirmIfEqual(RxUser, User, "Receiver, User: ") ; 
      CheckBurstIncrement(RxBurstFifo, i*32, NumBytes, DATA_WIDTH) ;
    end loop ; 
    
    Check (StreamRxRec, Data, (ID+2) & (Dest+2) & User & '0') ;
     
    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(StreamRxRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process AxiReceiverProc ;

end AxiBurstNoLast1 ;

Configuration TbStream_AxiBurstNoLast1 of TbStream is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(AxiBurstNoLast1) ; 
    end for ; 
  end for ; 
end TbStream_AxiBurstNoLast1 ; 