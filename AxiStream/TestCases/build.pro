#  File Name:         testbench.pro
#  Revision:          STANDARD VERSION
#
#  Maintainer:        Jim Lewis      email:  jim@synthworks.com
#  Contributor(s):
#     Jim Lewis      jim@synthworks.com
#
#
#  Description:
#        Script to run one Axi Stream test  
#
#  Developed for:
#        SynthWorks Design Inc.
#        VHDL Training Classes
#        11898 SW 128th Ave.  Tigard, Or  97223
#        http://www.SynthWorks.com
#
#  Revision History:
#    Date      Version    Description
#     1/2022   2022.01    Added Tests
#     9/2021   2021.09    RunTest replacing analyze + simulate
#     5/2021   2021.05    Start of Refactoring TestCases
#     1/2020   2020.01    Updated Licenses to Apache
#     1/2019   2019.01    Compile Script for OSVVM
#
#
#  This file is part of OSVVM.
#  
#  Copyright (c) 2019 - 2022 by SynthWorks Design Inc.  
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      https://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#  

##
## Runs in conjunction with either 
## Testbench/Testbench.pro or TestbenchVTI/TestbenchVTI.pro
## Continuing with library set previously by the above
##

## =============================================
## Run Demo
RunTest  TbStream_SendGetDemo1.vhd           ; # Demo of Send, Get, and Check of words and bursts
RunTest  TbStream_SendGetPacketBurst1.vhd    ; # Prototype of burst packetization with FIFO in Byte and then Word mode
RunTest  TbStream_SendGetRandom1.vhd         ; # Uses Basic Randomization Features
RunTest  TbStream_AxiSendGetRandom1.vhd      ; # Uses Randomization Features specific to AxiStream
RunTest  TbStream_SendGetRandom2.vhd         ; # Demo of Send, Get, and Check of packets with Valid/Ready randomization
RunTest  TbStream_AxiSendGetRandomParam2.vhd        ; # SendGetRandom2 + Change parameters
RunTest  TbStream_AxiSendGetRandomParamAsync2.vhd   ; # AxiSendGetRandomParam2 + use SendBurstVectorAsync

## =============================================
## MIT Record Checks Single Transfer Tests - only test once for all 
RunTest  TbStream_MultipleDriversTransmitter1.vhd
RunTest  TbStream_MultipleDriversReceiver1.vhd

## =============================================
## MIT Checks that apply to all streaming models
## MIT Blocking, Single Transfers
RunTest  TbStream_SendGet1.vhd
RunTest  TbStream_ByteHandling1.vhd

## MIT Asynchronous, Single Transfers
RunTest  TbStream_SendGetAsync1.vhd
RunTest  TbStream_ByteHandlingAsync1.vhd

## MIT Blocking Burst Transfers
RunTest  TbStream_SendGetBurst1.vhd
RunTest  TbStream_SendGetBurstByte1.vhd
RunTest  TbStream_ByteHandlingBurst1.vhd
RunTest  TbStream_ByteHandlingBurstByte1.vhd

## MIT Blocking Burst that use BurstFifo also as scoreboard
RunTest  TbStream_SendCheckBurst1.vhd
RunTest  TbStream_SendCheckBurstByte1.vhd

RunTest  TbStream_SendCheckBurstPattern1.vhd
RunTest  TbStream_SendCheckBurstPattern2.vhd
RunTest  TbStream_SendCheckBurstBytePattern1.vhd
RunTest  TbStream_SendCheckBurstAsyncPattern1.vhd
RunTest  TbStream_SendCheckBurstAsyncPattern2.vhd
RunTest  TbStream_SendCheckBurstByteAsyncPattern1.vhd

## MIT Asynchronous Burst Transfers
RunTest  TbStream_SendGetBurstAsync1.vhd
RunTest  TbStream_SendGetBurstByteAsync1.vhd
RunTest  TbStream_ByteHandlingBurstAsync1.vhd
RunTest  TbStream_ByteHandlingBurstByteAsync1.vhd

## MIT Asynchronous Burst that use BurstFifo also as scoreboard
RunTest  TbStream_SendCheckBurstAsync1.vhd
RunTest  TbStream_SendCheckBurstByteAsync1.vhd

## =============================================
## MIT Record Checks Burst Transfer Tests - only test once for all 
RunTest  TbStream_ReleaseAcquireTransmitter1.vhd
RunTest  TbStream_ReleaseAcquireReceiver1.vhd


## =============================================
## AxiStream Specific Tests
## AxiStream Blocking, Single Transfers
RunTest  TbStream_AxiSendGet2.vhd
RunTest  TbStream_AxiSetOptions1.vhd
RunTest  TbStream_AxiTxValidDelay1.vhd
RunTest  TbStream_AxiTiming1.vhd
RunTest  TbStream_AxiTiming2.vhd
RunTest  TbStream_AxiSetOptions2.vhd

## AxiStream Asynchronous, Single Transfers
RunTest  TbStream_AxiSendGetAsync2.vhd
RunTest  TbStream_AxiSetOptionsAsync1.vhd
RunTest  TbStream_AxiSetOptionsAsync2.vhd


## AxiStream - Exercise RECEIVE_READY_WAIT_FOR_GET in both single and burst transfers 
RunTest TbStream_WaitForGet1.vhd
RunTest TbStream_WaitForGetAsync1.vhd

## AxiStream Blocking Burst Transfers
RunTest  TbStream_AxiSendGetBurst2.vhd
RunTest  TbStream_AxiLastParam1.vhd
RunTest  TbStream_AxiLastOption1.vhd
RunTest  TbStream_AxiSetOptionsBurst1.vhd
RunTest  TbStream_AxiTxValidDelayBurst1.vhd
RunTest  TbStream_AxiTimingBurst2.vhd
RunTest  TbStream_AxiSetOptionsBurst2.vhd
RunTest  TbStream_AxiSetOptionsBurstByte2.vhd
RunTest  TbStream_AxiSetOptionsBurst3.vhd
RunTest  TbStream_AxiBurstNoLast1.vhd

RunTest  TbStream_AxiSetOptionsBurstCheck3.vhd

RunTest  TbStream_AxiSendCheckBurstPattern1.vhd
RunTest  TbStream_AxiSendCheckBurstPattern2.vhd
RunTest  TbStream_AxiSendCheckBurstAsyncPattern1.vhd
RunTest  TbStream_AxiSendCheckBurstAsyncPattern2.vhd

## AxiStream Asynchronous Burst Transfers
RunTest  TbStream_AxiSendGetBurstAsync2.vhd
RunTest  TbStream_AxiLastParamAsync1.vhd
RunTest  TbStream_AxiLastOptionAsync1.vhd
RunTest  TbStream_AxiSetOptionsBurstAsync1.vhd
RunTest  TbStream_AxiSetOptionsBurstAsync2.vhd
RunTest  TbStream_AxiSetOptionsBurstByteAsync2.vhd
RunTest  TbStream_AxiSetOptionsBurstAsync3.vhd
RunTest  TbStream_AxiBurstAsyncNoLast1.vhd

RunTest  TbStream_AxiSetOptionsBurstCheckAsync3.vhd
