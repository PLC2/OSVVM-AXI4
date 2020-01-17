#  File Name:         testbench.pro
#  Revision:          STANDARD VERSION
#
#  Maintainer:        Jim Lewis      email:  jim@synthworks.com
#  Contributor(s):
#     Jim Lewis      jim@synthworks.com
#
#
#  Description:
#        Script to compile the Axi4 Lite testbench  
#
#  Developed for:
#        SynthWorks Design Inc.
#        VHDL Training Classes
#        11898 SW 128th Ave.  Tigard, Or  97223
#        http://www.SynthWorks.com
#
#  Revision History:
#    Date      Version    Description
#     1/2019   2019.01    Compile Script for OSVVM
#     1/2020   2020.01    Updated Licenses to Apache
#
#
#  This file is part of OSVVM.
#  
#  Copyright (c) 2019 - 2020 by SynthWorks Design Inc.  
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
library osvvm_TbAxi4Lite
analyze TestCtrl_e.vhd
analyze TbAxi4Lite_map_records.vhd
analyze TbAxi4Lite_BasicReadWrite.vhd
analyze TbAxi4Lite_MasterReadWriteAsync1.vhd
analyze TbAxi4Lite_MasterReadWriteAsync2.vhd
analyze TbAxi4Lite_MasterReadWriteAsync3.vhd
analyze TbAxi4Lite_RandomReadWrite.vhd
analyze TbAxi4Lite_RandomReadWriteByte.vhd
analyze TbAxi4Lite_TimeOut.vhd
analyze TbAxi4Lite_WriteOptions.vhd

simulate TbAxi4Lite_BasicReadWrite
# simulate TbAxi4Lite_MasterReadWriteAsync1    
# simulate TbAxi4Lite_MasterReadWriteAsync2    
# simulate TbAxi4Lite_MasterReadWriteAsync3    
# simulate TbAxi4Lite_RandomReadWrite    
# simulate TbAxi4Lite_RandomReadWriteByte    
# simulate TbAxi4Lite_TimeOut    
# simulate TbAxi4Lite_WriteOptions 
