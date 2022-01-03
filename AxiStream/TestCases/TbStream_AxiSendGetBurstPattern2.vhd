--
--  File Name:         TbStream_AxiSendGetBurst2.vhd
--  Design Unit Name:  Architecture of TestCtrl
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Validates Stream Model Independent Transactions
--      SendBurst, GetBurst with 2 parameters
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
architecture AxiSendGetBurst2 of TestCtrl is

  signal   TestDone : integer_barrier := 1 ;
  
 
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetAlertLogName("TbStream_AxiSendGetBurst2") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable INFO logs

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen("./results/TbStream_AxiSendGetBurst2.txt") ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 5 ms) ;
    AlertIf(now >= 5 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
--    AlertIfDiff("./results/TbStream_AxiSendGetBurst2.txt", "../sim_shared/validated_results/TbStream_AxiSendGetBurst2.txt", "") ; 
    
    EndOfTestReports ; 
    std.env.stop(GetAlertCount) ; 
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
  begin
    wait until nReset = '1' ;  
    WaitForClock(StreamTxRec, 2) ; 
    SetBurstMode(StreamTxRec, STREAM_BURST_BYTE_MODE) ;
    
    ID   := to_slv(1, ID_LEN);
    Dest := to_slv(2, DEST_LEN) ; 
    User := to_slv(3, USER_LEN) ; 

    log("Transmit 16 words.  Incrementing.  Starting with X00010003") ;
    SendBurstIncrement(StreamTxRec, X"00010003", 16, ID & Dest & User & '0') ;

    WaitForClock(StreamTxRec, 4) ; 

    log("Transmit 8 words.") ;
    SendBurst(StreamTxRec, 
      (X"00010203", X"04050607", X"08090A0B", X"0C0D0E0F", X"10111213", X"14151617", X"18191A1B", X"1C1D1E1F"),
      (ID+1) & (Dest+1) & (User+1) & '0') ;

    WaitForClock(StreamTxRec, 4) ; 

    log("Transmit 8 words.  Random.  Starting with X00010001") ;
    SendBurstRandom(StreamTxRec, X"00010001", 8, (ID+2) & (Dest+2) & (User+2) & '0') ;
    
    ID   := to_slv(8, ID_LEN);
    Dest := to_slv(9, DEST_LEN) ; 
    User := to_slv(10, USER_LEN) ; 

    for i in 0 to 6 loop 
      log("Transmit " & to_string(32+5*i) & " Bytes. Starting with " & to_string(i*32)) ;
      SendBurstIncrement(StreamTxRec, to_slv(i*32, 32), 32 + 5*i, (ID+i/2) & (Dest+i/2) & (User+i/2) & '0') ;
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
    variable NumBytes : integer ; 
    constant PARAM_LEN : integer := ID_LEN + DEST_LEN + USER_LEN + 1 ; 
    variable RxParam : std_logic_vector(PARAM_LEN-1 downto 0) ;
    alias RxID   : std_logic_vector(ID_LEN-1 downto 0) is RxParam(PARAM_LEN-1 downto PARAM_LEN-ID_LEN) ;
    alias RxDest : std_logic_vector(DEST_LEN-1 downto 0) is RxParam(DEST_LEN-1 + USER_LEN+1 downto USER_LEN+1) ;
    alias RxUser : std_logic_vector(USER_LEN-1 downto 0) is RxParam(USER_LEN downto 1) ;
    variable ID   : std_logic_vector(ID_LEN-1 downto 0) ;    -- 8
    variable Dest : std_logic_vector(DEST_LEN-1 downto 0) ;  -- 4
    variable User : std_logic_vector(USER_LEN-1 downto 0) ;  -- 4
  begin
    WaitForClock(StreamRxRec, 2) ; 
    SetBurstMode(StreamRxRec, STREAM_BURST_BYTE_MODE) ;
    
    ID   := to_slv(1, ID_LEN);
    Dest := to_slv(2, DEST_LEN) ; 
    User := to_slv(3, USER_LEN) ; 

--    log("Transmit 32 Bytes -- word aligned") ;
    CheckBurstIncrement(StreamRxRec, X"00010003", 16, ID & Dest & User & '0') ;

    
--    log("Transmit 30 Bytes -- unaligned") ;
    CheckBurst (StreamRxRec, 
      (X"00010203", X"04050607", X"08090A0B", X"0C0D0E0F", X"10111213", X"14151617", X"18191A1B", X"1C1D1E1F"), 
      (ID+1) & (Dest+1) & (User+1) & '0') ;

--    log("Transmit 34 Bytes -- unaligned") ;
    CheckBurstRandom(StreamRxRec, X"00010001", 8, (ID+2) & (Dest+2) & (User+2) & '0') ;
    
    ID   := to_slv(8, ID_LEN);
    Dest := to_slv(9, DEST_LEN) ; 
    User := to_slv(10, USER_LEN) ; 

    for i in 0 to 6 loop 
--      log("Transmit " & to_string(32+5*i) & " Bytes. Starting with " & to_string(i*32)) ;
      CheckBurstIncrement(StreamRxRec, to_slv(i*32, 32), 32 + 5*i, (ID+i/2) & (Dest+i/2) & (User+i/2) & '0') ;
    end loop ; 
     
    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(StreamRxRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process AxiReceiverProc ;

end AxiSendGetBurst2 ;

Configuration TbStream_AxiSendGetBurst2 of TbStream is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(AxiSendGetBurst2) ; 
    end for ; 
  end for ; 
end TbStream_AxiSendGetBurst2 ; 