// (c) Copyright 2016 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.

/***************************** Include Files *********************************/
#include "xldpc.h"

/************************** Function Implementation *************************/
int XLdpcCfgInitialize(XLdpc *InstancePtr, XLdpc_Config *ConfigPtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(ConfigPtr != NULL);

    InstancePtr->BaseAddress  = ConfigPtr->BaseAddress;
    InstancePtr->Standard     = ConfigPtr->Standard;
     // Initialize I/F configuration
    XLdpcSet_CORE_AXIS_WIDTH(ConfigPtr->BaseAddress,ConfigPtr->InitAXISWidth);
    InstancePtr->IsReady      = XIL_COMPONENT_IS_READY;

    return XST_SUCCESS;
}

void XLdpcAddLdpcParams(XLdpc *InstancePtr, u32 CodeId, u32 SCOffset, u32 LAOffset, u32 QCOffset, const XLdpcLdpcParameters* ParamsPtr) {
  Xil_AssertVoid(InstancePtr != NULL);
  Xil_AssertVoid(ParamsPtr   != NULL);
  Xil_AssertVoid(InstancePtr->IsReady  == XIL_COMPONENT_IS_READY);
  Xil_AssertVoid(InstancePtr->Standard == XLDPC_STANDARD_OTHER);

  u32 wdata = 0;
  if (CodeId < 128) {
    wdata = 0;
    wdata |= (XLDPC_LDPC_CODE_REG0_N_MASK & (ParamsPtr->N << XLDPC_LDPC_CODE_REG0_N_LSB));
    wdata |= (XLDPC_LDPC_CODE_REG0_K_MASK & (ParamsPtr->K << XLDPC_LDPC_CODE_REG0_K_LSB));
    XLdpcWrite_LDPC_CODE_REG0_Words(InstancePtr->BaseAddress,CodeId,&wdata,1);
    wdata = 0;
    wdata |= (XLDPC_LDPC_CODE_REG1_PSIZE_MASK       & (ParamsPtr->PSize      << XLDPC_LDPC_CODE_REG1_PSIZE_LSB));
    wdata |= (XLDPC_LDPC_CODE_REG1_NO_PACKING_MASK  & (ParamsPtr->NoPacking  << XLDPC_LDPC_CODE_REG1_NO_PACKING_LSB));
    wdata |= (XLDPC_LDPC_CODE_REG1_NM_MASK          & (ParamsPtr->NM         << XLDPC_LDPC_CODE_REG1_NM_LSB));
    XLdpcWrite_LDPC_CODE_REG1_Words(InstancePtr->BaseAddress,CodeId,&wdata,1);
    wdata = 0;
    wdata |= (XLDPC_LDPC_CODE_REG2_NLAYERS_MASK               & (ParamsPtr->NLayers          << XLDPC_LDPC_CODE_REG2_NLAYERS_LSB));
    wdata |= (XLDPC_LDPC_CODE_REG2_NMQC_MASK                  & (ParamsPtr->NMQC             << XLDPC_LDPC_CODE_REG2_NMQC_LSB));
    wdata |= (XLDPC_LDPC_CODE_REG2_NORM_TYPE_MASK             & (ParamsPtr->NormType         << XLDPC_LDPC_CODE_REG2_NORM_TYPE_LSB));
    wdata |= (XLDPC_LDPC_CODE_REG2_NO_FINAL_PARITY_CHECK_MASK & (ParamsPtr->NoFinalParity    << XLDPC_LDPC_CODE_REG2_NO_FINAL_PARITY_CHECK_LSB));
    wdata |= (XLDPC_LDPC_CODE_REG2_MAX_SCHEDULE_MASK          & (ParamsPtr->MaxSchedule      << XLDPC_LDPC_CODE_REG2_MAX_SCHEDULE_LSB));
    XLdpcWrite_LDPC_CODE_REG2_Words(InstancePtr->BaseAddress,CodeId,&wdata,1);
    wdata = 0;
    wdata |= (XLDPC_LDPC_CODE_REG3_SC_OFF_MASK & (SCOffset << XLDPC_LDPC_CODE_REG3_SC_OFF_LSB));
    wdata |= (XLDPC_LDPC_CODE_REG3_LA_OFF_MASK & (LAOffset << XLDPC_LDPC_CODE_REG3_LA_OFF_LSB));
    wdata |= (XLDPC_LDPC_CODE_REG3_QC_OFF_MASK & (QCOffset << XLDPC_LDPC_CODE_REG3_QC_OFF_LSB));
    XLdpcWrite_LDPC_CODE_REG3_Words(InstancePtr->BaseAddress,CodeId,&wdata,1);

    XLdpcWrite_LDPC_SC_TABLE_Words(InstancePtr->BaseAddress,SCOffset,  ParamsPtr->SCTable,(ParamsPtr->NLayers+3)>>2); // Scale is packed, 4 per reg
    XLdpcWrite_LDPC_LA_TABLE_Words(InstancePtr->BaseAddress,LAOffset*4,ParamsPtr->LATable,ParamsPtr->NLayers);        // Further 4x applied to offset in function
    XLdpcWrite_LDPC_QC_TABLE_Words(InstancePtr->BaseAddress,QCOffset*4,ParamsPtr->QCTable,ParamsPtr->NQC);

    // Store offsets
    InstancePtr->SCOffset[CodeId] = SCOffset;
    InstancePtr->LAOffset[CodeId] = LAOffset;
    InstancePtr->QCOffset[CodeId] = QCOffset;
  }
}

void XLdpcShareTableSize(const XLdpcLdpcParameters* ParamsPtr, u32* SCSizePtr, u32* LASizePtr, u32* QCSizePtr) {
  Xil_AssertVoid(ParamsPtr != NULL);
  if (SCSizePtr) {
    *SCSizePtr = (ParamsPtr->NLayers+3)>>2;
  }
  if (LASizePtr) {
    *LASizePtr = ((ParamsPtr->NLayers<<2)+15)>>4; // Multiple of 16
  }
  if (QCSizePtr) {
    *QCSizePtr = ((ParamsPtr->NQC<<2)+15)>>4;
  }
}

XLdpcInterruptClass XLdpcInterruptClassifier(XLdpc *InstancePtr) {
  XLdpcInterruptClass IntClass;

  IntClass.Intf       = 0;
  IntClass.ECCSBit    = 0;
  IntClass.ECCMBit    = 0;
  IntClass.RstReq     = 0;
  IntClass.ReprogReq  = 0;

  u32 isr     = XLdpcGet_CORE_ISR(InstancePtr->BaseAddress);
  u32 isr_ecc = XLdpcGet_CORE_ECC_ISR(InstancePtr->BaseAddress);

  if (isr) {
    IntClass.Intf   = 1;
    IntClass.RstReq = 1;
  }
  // Lower 11-bits indicate ECC error (single or multi-bit)
  u32 ecc_errbits  = isr_ecc & 0x0007FF;
  // Upper 11-bits indicate multi-bit
  u32 ecc_errmbits = (isr_ecc & 0x3FF800) >> 11;
  // XOR ecc error bits with multi-bit errors to determine any single bit
  if (ecc_errbits ^ ecc_errmbits) {
    IntClass.ECCSBit = 1;
  }
  if (ecc_errmbits) {
    IntClass.ECCMBit    = 1;
    IntClass.RstReq     = 1;
    IntClass.ReprogReq  = 1;
  }
  return IntClass;
}

/************************** Base API Function Implementation *************************/
void XLdpcSet_CORE_AXI_WR_PROTECT(UINTPTR BaseAddress, u32 Data) {
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_AXI_WR_PROTECT_ADDR, Data);
}

u32 XLdpcGet_CORE_AXI_WR_PROTECT(UINTPTR BaseAddress) {
  return XLdpcReadReg(BaseAddress, XLDPC_CORE_AXI_WR_PROTECT_ADDR);
}

void XLdpcSet_CORE_CODE_WR_PROTECT(UINTPTR BaseAddress, u32 Data) {
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_CODE_WR_PROTECT_ADDR, Data);
}

u32 XLdpcGet_CORE_CODE_WR_PROTECT(UINTPTR BaseAddress) {
  return XLdpcReadReg(BaseAddress, XLDPC_CORE_CODE_WR_PROTECT_ADDR);
}

u32 XLdpcGet_CORE_ACTIVE(UINTPTR BaseAddress) {
  return XLdpcReadReg(BaseAddress, XLDPC_CORE_ACTIVE_ADDR);
}

void XLdpcSet_CORE_AXIS_WIDTH_DIN_WORDS(UINTPTR BaseAddress, u32 Data) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_WIDTH_ADDR);
  rdata = rdata & ~XLDPC_CORE_AXIS_WIDTH_DIN_WORDS_MASK;
  u32 wdata = (rdata & ~XLDPC_CORE_AXIS_WIDTH_DIN_WORDS_MASK) | (XLDPC_CORE_AXIS_WIDTH_DIN_WORDS_MASK & (Data << XLDPC_CORE_AXIS_WIDTH_DIN_WORDS_LSB));
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_AXIS_WIDTH_ADDR, wdata);
}

u32 XLdpcGet_CORE_AXIS_WIDTH_DIN_WORDS(UINTPTR BaseAddress) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_WIDTH_ADDR);
  return (rdata & XLDPC_CORE_AXIS_WIDTH_DIN_WORDS_MASK) >> XLDPC_CORE_AXIS_WIDTH_DIN_WORDS_LSB;
}

void XLdpcSet_CORE_AXIS_WIDTH_DOUT_WORDS(UINTPTR BaseAddress, u32 Data) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_WIDTH_ADDR);
  rdata = rdata & ~XLDPC_CORE_AXIS_WIDTH_DOUT_WORDS_MASK;
  u32 wdata = (rdata & ~XLDPC_CORE_AXIS_WIDTH_DOUT_WORDS_MASK) | (XLDPC_CORE_AXIS_WIDTH_DOUT_WORDS_MASK & (Data << XLDPC_CORE_AXIS_WIDTH_DOUT_WORDS_LSB));
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_AXIS_WIDTH_ADDR, wdata);
}

u32 XLdpcGet_CORE_AXIS_WIDTH_DOUT_WORDS(UINTPTR BaseAddress) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_WIDTH_ADDR);
  return (rdata & XLDPC_CORE_AXIS_WIDTH_DOUT_WORDS_MASK) >> XLDPC_CORE_AXIS_WIDTH_DOUT_WORDS_LSB;
}

void XLdpcSet_CORE_AXIS_WIDTH(UINTPTR BaseAddress, u32 Data) {
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_AXIS_WIDTH_ADDR, Data);
}

u32 XLdpcGet_CORE_AXIS_WIDTH(UINTPTR BaseAddress) {
  return XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_WIDTH_ADDR);
}

void XLdpcSet_CORE_AXIS_ENABLE_CTRL(UINTPTR BaseAddress, u32 Data) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR);
  rdata = rdata & ~XLDPC_CORE_AXIS_ENABLE_CTRL_MASK;
  u32 wdata = (rdata & ~XLDPC_CORE_AXIS_ENABLE_CTRL_MASK) | (XLDPC_CORE_AXIS_ENABLE_CTRL_MASK & (Data << XLDPC_CORE_AXIS_ENABLE_CTRL_LSB));
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR, wdata);
}

u32 XLdpcGet_CORE_AXIS_ENABLE_CTRL(UINTPTR BaseAddress) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR);
  return (rdata & XLDPC_CORE_AXIS_ENABLE_CTRL_MASK) >> XLDPC_CORE_AXIS_ENABLE_CTRL_LSB;
}

void XLdpcSet_CORE_AXIS_ENABLE_DIN(UINTPTR BaseAddress, u32 Data) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR);
  rdata = rdata & ~XLDPC_CORE_AXIS_ENABLE_DIN_MASK;
  u32 wdata = (rdata & ~XLDPC_CORE_AXIS_ENABLE_DIN_MASK) | (XLDPC_CORE_AXIS_ENABLE_DIN_MASK & (Data << XLDPC_CORE_AXIS_ENABLE_DIN_LSB));
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR, wdata);
}

u32 XLdpcGet_CORE_AXIS_ENABLE_DIN(UINTPTR BaseAddress) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR);
  return (rdata & XLDPC_CORE_AXIS_ENABLE_DIN_MASK) >> XLDPC_CORE_AXIS_ENABLE_DIN_LSB;
}

void XLdpcSet_CORE_AXIS_ENABLE_DIN_WORDS(UINTPTR BaseAddress, u32 Data) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR);
  rdata = rdata & ~XLDPC_CORE_AXIS_ENABLE_DIN_WORDS_MASK;
  u32 wdata = (rdata & ~XLDPC_CORE_AXIS_ENABLE_DIN_WORDS_MASK) | (XLDPC_CORE_AXIS_ENABLE_DIN_WORDS_MASK & (Data << XLDPC_CORE_AXIS_ENABLE_DIN_WORDS_LSB));
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR, wdata);
}

u32 XLdpcGet_CORE_AXIS_ENABLE_DIN_WORDS(UINTPTR BaseAddress) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR);
  return (rdata & XLDPC_CORE_AXIS_ENABLE_DIN_WORDS_MASK) >> XLDPC_CORE_AXIS_ENABLE_DIN_WORDS_LSB;
}

void XLdpcSet_CORE_AXIS_ENABLE_STATUS(UINTPTR BaseAddress, u32 Data) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR);
  rdata = rdata & ~XLDPC_CORE_AXIS_ENABLE_STATUS_MASK;
  u32 wdata = (rdata & ~XLDPC_CORE_AXIS_ENABLE_STATUS_MASK) | (XLDPC_CORE_AXIS_ENABLE_STATUS_MASK & (Data << XLDPC_CORE_AXIS_ENABLE_STATUS_LSB));
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR, wdata);
}

u32 XLdpcGet_CORE_AXIS_ENABLE_STATUS(UINTPTR BaseAddress) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR);
  return (rdata & XLDPC_CORE_AXIS_ENABLE_STATUS_MASK) >> XLDPC_CORE_AXIS_ENABLE_STATUS_LSB;
}

void XLdpcSet_CORE_AXIS_ENABLE_DOUT(UINTPTR BaseAddress, u32 Data) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR);
  rdata = rdata & ~XLDPC_CORE_AXIS_ENABLE_DOUT_MASK;
  u32 wdata = (rdata & ~XLDPC_CORE_AXIS_ENABLE_DOUT_MASK) | (XLDPC_CORE_AXIS_ENABLE_DOUT_MASK & (Data << XLDPC_CORE_AXIS_ENABLE_DOUT_LSB));
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR, wdata);
}

u32 XLdpcGet_CORE_AXIS_ENABLE_DOUT(UINTPTR BaseAddress) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR);
  return (rdata & XLDPC_CORE_AXIS_ENABLE_DOUT_MASK) >> XLDPC_CORE_AXIS_ENABLE_DOUT_LSB;
}

void XLdpcSet_CORE_AXIS_ENABLE_DOUT_WORDS(UINTPTR BaseAddress, u32 Data) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR);
  rdata = rdata & ~XLDPC_CORE_AXIS_ENABLE_DOUT_WORDS_MASK;
  u32 wdata = (rdata & ~XLDPC_CORE_AXIS_ENABLE_DOUT_WORDS_MASK) | (XLDPC_CORE_AXIS_ENABLE_DOUT_WORDS_MASK & (Data << XLDPC_CORE_AXIS_ENABLE_DOUT_WORDS_LSB));
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR, wdata);
}

u32 XLdpcGet_CORE_AXIS_ENABLE_DOUT_WORDS(UINTPTR BaseAddress) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR);
  return (rdata & XLDPC_CORE_AXIS_ENABLE_DOUT_WORDS_MASK) >> XLDPC_CORE_AXIS_ENABLE_DOUT_WORDS_LSB;
}

void XLdpcSet_CORE_AXIS_ENABLE(UINTPTR BaseAddress, u32 Data) {
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR, Data);
}

u32 XLdpcGet_CORE_AXIS_ENABLE(UINTPTR BaseAddress) {
  return XLdpcReadReg(BaseAddress, XLDPC_CORE_AXIS_ENABLE_ADDR);
}

void XLdpcSet_CORE_ORDER(UINTPTR BaseAddress, u32 Data) {
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_ORDER_ADDR, Data);
}

u32 XLdpcGet_CORE_ORDER(UINTPTR BaseAddress) {
  return XLdpcReadReg(BaseAddress, XLDPC_CORE_ORDER_ADDR);
}

void XLdpcSet_CORE_ISR(UINTPTR BaseAddress, u32 Data) {
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_ISR_ADDR, Data);
}

u32 XLdpcGet_CORE_ISR(UINTPTR BaseAddress) {
  return XLdpcReadReg(BaseAddress, XLDPC_CORE_ISR_ADDR);
}

void XLdpcSet_CORE_IER(UINTPTR BaseAddress, u32 Data) {
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_IER_ADDR, Data);
}

void XLdpcSet_CORE_IDR(UINTPTR BaseAddress, u32 Data) {
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_IDR_ADDR, Data);
}

u32 XLdpcGet_CORE_IMR(UINTPTR BaseAddress) {
  return XLdpcReadReg(BaseAddress, XLDPC_CORE_IMR_ADDR);
}

void XLdpcSet_CORE_ECC_ISR(UINTPTR BaseAddress, u32 Data) {
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_ECC_ISR_ADDR, Data);
}

u32 XLdpcGet_CORE_ECC_ISR(UINTPTR BaseAddress) {
  return XLdpcReadReg(BaseAddress, XLDPC_CORE_ECC_ISR_ADDR);
}

void XLdpcSet_CORE_ECC_IER(UINTPTR BaseAddress, u32 Data) {
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_ECC_IER_ADDR, Data);
}

void XLdpcSet_CORE_ECC_IDR(UINTPTR BaseAddress, u32 Data) {
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_ECC_IDR_ADDR, Data);
}

u32 XLdpcGet_CORE_ECC_IMR(UINTPTR BaseAddress) {
  return XLdpcReadReg(BaseAddress, XLDPC_CORE_ECC_IMR_ADDR);
}

void XLdpcSet_CORE_BYPASS(UINTPTR BaseAddress, u32 Data) {
  XLdpcWriteReg(BaseAddress, XLDPC_CORE_BYPASS_ADDR, Data);
}

u32 XLdpcGet_CORE_BYPASS(UINTPTR BaseAddress) {
  return XLdpcReadReg(BaseAddress, XLDPC_CORE_BYPASS_ADDR);
}

u32 XLdpcGet_CORE_VERSION_PATCH(UINTPTR BaseAddress) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_VERSION_ADDR);
  return (rdata & XLDPC_CORE_VERSION_PATCH_MASK) >> XLDPC_CORE_VERSION_PATCH_LSB;
}

u32 XLdpcGet_CORE_VERSION_REVISION(UINTPTR BaseAddress) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_VERSION_ADDR);
  return (rdata & XLDPC_CORE_VERSION_REVISION_MASK) >> XLDPC_CORE_VERSION_REVISION_LSB;
}

u32 XLdpcGet_CORE_VERSION_MINOR(UINTPTR BaseAddress) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_VERSION_ADDR);
  return (rdata & XLDPC_CORE_VERSION_MINOR_MASK) >> XLDPC_CORE_VERSION_MINOR_LSB;
}

u32 XLdpcGet_CORE_VERSION_MAJOR(UINTPTR BaseAddress) {
  u32 rdata = XLdpcReadReg(BaseAddress, XLDPC_CORE_VERSION_ADDR);
  return (rdata & XLDPC_CORE_VERSION_MAJOR_MASK) >> XLDPC_CORE_VERSION_MAJOR_LSB;
}

u32 XLdpcGet_CORE_VERSION(UINTPTR BaseAddress) {
  return XLdpcReadReg(BaseAddress, XLDPC_CORE_VERSION_ADDR);
}

u32 XLdpcWrite_LDPC_CODE_REG0_N_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if ( MaxDataDepth > XLDPC_LDPC_CODE_REG0_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG0_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG0_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    u32 wdata = (rdata & ~XLDPC_LDPC_CODE_REG0_N_MASK) | (XLDPC_LDPC_CODE_REG0_N_MASK & (DataArrayPtr[idx] << XLDPC_LDPC_CODE_REG0_N_LSB));
    XLdpcWriteReg(BaseAddress, addr, wdata);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG0_N_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG0_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG0_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG0_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    DataArrayPtr[idx] = (rdata & XLDPC_LDPC_CODE_REG0_N_MASK) >> XLDPC_LDPC_CODE_REG0_N_LSB;
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG0_K_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if ( MaxDataDepth > XLDPC_LDPC_CODE_REG0_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG0_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG0_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    u32 wdata = (rdata & ~XLDPC_LDPC_CODE_REG0_K_MASK) | (XLDPC_LDPC_CODE_REG0_K_MASK & (DataArrayPtr[idx] << XLDPC_LDPC_CODE_REG0_K_LSB));
    XLdpcWriteReg(BaseAddress, addr, wdata);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG0_K_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG0_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG0_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG0_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    DataArrayPtr[idx] = (rdata & XLDPC_LDPC_CODE_REG0_K_MASK) >> XLDPC_LDPC_CODE_REG0_K_LSB;
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG0_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG0_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG0_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG0_STEP;
    XLdpcWriteReg(BaseAddress, addr, DataArrayPtr[idx]);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG0_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG0_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG0_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG0_STEP;
    DataArrayPtr[idx] = XLdpcReadReg(BaseAddress, addr);
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG1_PSIZE_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if ( MaxDataDepth > XLDPC_LDPC_CODE_REG1_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG1_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG1_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    u32 wdata = (rdata & ~XLDPC_LDPC_CODE_REG1_PSIZE_MASK) | (XLDPC_LDPC_CODE_REG1_PSIZE_MASK & (DataArrayPtr[idx] << XLDPC_LDPC_CODE_REG1_PSIZE_LSB));
    XLdpcWriteReg(BaseAddress, addr, wdata);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG1_PSIZE_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG1_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG1_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG1_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    DataArrayPtr[idx] = (rdata & XLDPC_LDPC_CODE_REG1_PSIZE_MASK) >> XLDPC_LDPC_CODE_REG1_PSIZE_LSB;
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG1_NO_PACKING_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if ( MaxDataDepth > XLDPC_LDPC_CODE_REG1_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG1_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG1_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    u32 wdata = (rdata & ~XLDPC_LDPC_CODE_REG1_NO_PACKING_MASK) | (XLDPC_LDPC_CODE_REG1_NO_PACKING_MASK & (DataArrayPtr[idx] << XLDPC_LDPC_CODE_REG1_NO_PACKING_LSB));
    XLdpcWriteReg(BaseAddress, addr, wdata);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG1_NO_PACKING_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG1_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG1_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG1_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    DataArrayPtr[idx] = (rdata & XLDPC_LDPC_CODE_REG1_NO_PACKING_MASK) >> XLDPC_LDPC_CODE_REG1_NO_PACKING_LSB;
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG1_NM_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if ( MaxDataDepth > XLDPC_LDPC_CODE_REG1_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG1_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG1_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    u32 wdata = (rdata & ~XLDPC_LDPC_CODE_REG1_NM_MASK) | (XLDPC_LDPC_CODE_REG1_NM_MASK & (DataArrayPtr[idx] << XLDPC_LDPC_CODE_REG1_NM_LSB));
    XLdpcWriteReg(BaseAddress, addr, wdata);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG1_NM_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG1_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG1_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG1_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    DataArrayPtr[idx] = (rdata & XLDPC_LDPC_CODE_REG1_NM_MASK) >> XLDPC_LDPC_CODE_REG1_NM_LSB;
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG1_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG1_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG1_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG1_STEP;
    XLdpcWriteReg(BaseAddress, addr, DataArrayPtr[idx]);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG1_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG1_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG1_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG1_STEP;
    DataArrayPtr[idx] = XLdpcReadReg(BaseAddress, addr);
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG2_NLAYERS_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if ( MaxDataDepth > XLDPC_LDPC_CODE_REG2_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG2_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG2_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    u32 wdata = (rdata & ~XLDPC_LDPC_CODE_REG2_NLAYERS_MASK) | (XLDPC_LDPC_CODE_REG2_NLAYERS_MASK & (DataArrayPtr[idx] << XLDPC_LDPC_CODE_REG2_NLAYERS_LSB));
    XLdpcWriteReg(BaseAddress, addr, wdata);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG2_NLAYERS_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG2_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG2_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG2_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    DataArrayPtr[idx] = (rdata & XLDPC_LDPC_CODE_REG2_NLAYERS_MASK) >> XLDPC_LDPC_CODE_REG2_NLAYERS_LSB;
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG2_NMQC_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if ( MaxDataDepth > XLDPC_LDPC_CODE_REG2_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG2_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG2_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    u32 wdata = (rdata & ~XLDPC_LDPC_CODE_REG2_NMQC_MASK) | (XLDPC_LDPC_CODE_REG2_NMQC_MASK & (DataArrayPtr[idx] << XLDPC_LDPC_CODE_REG2_NMQC_LSB));
    XLdpcWriteReg(BaseAddress, addr, wdata);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG2_NMQC_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG2_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG2_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG2_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    DataArrayPtr[idx] = (rdata & XLDPC_LDPC_CODE_REG2_NMQC_MASK) >> XLDPC_LDPC_CODE_REG2_NMQC_LSB;
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG2_NORM_TYPE_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if ( MaxDataDepth > XLDPC_LDPC_CODE_REG2_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG2_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG2_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    u32 wdata = (rdata & ~XLDPC_LDPC_CODE_REG2_NORM_TYPE_MASK) | (XLDPC_LDPC_CODE_REG2_NORM_TYPE_MASK & (DataArrayPtr[idx] << XLDPC_LDPC_CODE_REG2_NORM_TYPE_LSB));
    XLdpcWriteReg(BaseAddress, addr, wdata);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG2_NORM_TYPE_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG2_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG2_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG2_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    DataArrayPtr[idx] = (rdata & XLDPC_LDPC_CODE_REG2_NORM_TYPE_MASK) >> XLDPC_LDPC_CODE_REG2_NORM_TYPE_LSB;
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG2_NO_FINAL_PARITY_CHECK_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if ( MaxDataDepth > XLDPC_LDPC_CODE_REG2_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG2_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG2_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    u32 wdata = (rdata & ~XLDPC_LDPC_CODE_REG2_NO_FINAL_PARITY_CHECK_MASK) | (XLDPC_LDPC_CODE_REG2_NO_FINAL_PARITY_CHECK_MASK & (DataArrayPtr[idx] << XLDPC_LDPC_CODE_REG2_NO_FINAL_PARITY_CHECK_LSB));
    XLdpcWriteReg(BaseAddress, addr, wdata);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG2_NO_FINAL_PARITY_CHECK_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG2_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG2_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG2_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    DataArrayPtr[idx] = (rdata & XLDPC_LDPC_CODE_REG2_NO_FINAL_PARITY_CHECK_MASK) >> XLDPC_LDPC_CODE_REG2_NO_FINAL_PARITY_CHECK_LSB;
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG2_MAX_SCHEDULE_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if ( MaxDataDepth > XLDPC_LDPC_CODE_REG2_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG2_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG2_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    u32 wdata = (rdata & ~XLDPC_LDPC_CODE_REG2_MAX_SCHEDULE_MASK) | (XLDPC_LDPC_CODE_REG2_MAX_SCHEDULE_MASK & (DataArrayPtr[idx] << XLDPC_LDPC_CODE_REG2_MAX_SCHEDULE_LSB));
    XLdpcWriteReg(BaseAddress, addr, wdata);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG2_MAX_SCHEDULE_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG2_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG2_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG2_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    DataArrayPtr[idx] = (rdata & XLDPC_LDPC_CODE_REG2_MAX_SCHEDULE_MASK) >> XLDPC_LDPC_CODE_REG2_MAX_SCHEDULE_LSB;
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG2_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG2_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG2_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG2_STEP;
    XLdpcWriteReg(BaseAddress, addr, DataArrayPtr[idx]);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG2_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG2_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG2_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG2_STEP;
    DataArrayPtr[idx] = XLdpcReadReg(BaseAddress, addr);
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG3_SC_OFF_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if ( MaxDataDepth > XLDPC_LDPC_CODE_REG3_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG3_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG3_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    u32 wdata = (rdata & ~XLDPC_LDPC_CODE_REG3_SC_OFF_MASK) | (XLDPC_LDPC_CODE_REG3_SC_OFF_MASK & (DataArrayPtr[idx] << XLDPC_LDPC_CODE_REG3_SC_OFF_LSB));
    XLdpcWriteReg(BaseAddress, addr, wdata);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG3_SC_OFF_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG3_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG3_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG3_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    DataArrayPtr[idx] = (rdata & XLDPC_LDPC_CODE_REG3_SC_OFF_MASK) >> XLDPC_LDPC_CODE_REG3_SC_OFF_LSB;
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG3_LA_OFF_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if ( MaxDataDepth > XLDPC_LDPC_CODE_REG3_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG3_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG3_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    u32 wdata = (rdata & ~XLDPC_LDPC_CODE_REG3_LA_OFF_MASK) | (XLDPC_LDPC_CODE_REG3_LA_OFF_MASK & (DataArrayPtr[idx] << XLDPC_LDPC_CODE_REG3_LA_OFF_LSB));
    XLdpcWriteReg(BaseAddress, addr, wdata);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG3_LA_OFF_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG3_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG3_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG3_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    DataArrayPtr[idx] = (rdata & XLDPC_LDPC_CODE_REG3_LA_OFF_MASK) >> XLDPC_LDPC_CODE_REG3_LA_OFF_LSB;
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG3_QC_OFF_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if ( MaxDataDepth > XLDPC_LDPC_CODE_REG3_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG3_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG3_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    u32 wdata = (rdata & ~XLDPC_LDPC_CODE_REG3_QC_OFF_MASK) | (XLDPC_LDPC_CODE_REG3_QC_OFF_MASK & (DataArrayPtr[idx] << XLDPC_LDPC_CODE_REG3_QC_OFF_LSB));
    XLdpcWriteReg(BaseAddress, addr, wdata);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG3_QC_OFF_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = WordOffset + NumData;
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG3_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG3_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG3_STEP;
    u32 rdata = XLdpcReadReg(BaseAddress, addr);
    DataArrayPtr[idx] = (rdata & XLDPC_LDPC_CODE_REG3_QC_OFF_MASK) >> XLDPC_LDPC_CODE_REG3_QC_OFF_LSB;
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_CODE_REG3_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG3_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG3_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG3_STEP;
    XLdpcWriteReg(BaseAddress, addr, DataArrayPtr[idx]);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_CODE_REG3_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_CODE_REG3_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_CODE_REG3_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_CODE_REG3_STEP;
    DataArrayPtr[idx] = XLdpcReadReg(BaseAddress, addr);
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_SC_TABLE_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_SC_TABLE_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_SC_TABLE_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_SC_TABLE_STEP;
    XLdpcWriteReg(BaseAddress, addr, DataArrayPtr[idx]);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_SC_TABLE_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_SC_TABLE_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_SC_TABLE_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_SC_TABLE_STEP;
    DataArrayPtr[idx] = XLdpcReadReg(BaseAddress, addr);
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_LA_TABLE_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_LA_TABLE_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_LA_TABLE_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_LA_TABLE_STEP;
    XLdpcWriteReg(BaseAddress, addr, DataArrayPtr[idx]);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_LA_TABLE_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_LA_TABLE_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_LA_TABLE_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_LA_TABLE_STEP;
    DataArrayPtr[idx] = XLdpcReadReg(BaseAddress, addr);
  }
  return NumData;
}

u32 XLdpcWrite_LDPC_QC_TABLE_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_QC_TABLE_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_QC_TABLE_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_QC_TABLE_STEP;
    XLdpcWriteReg(BaseAddress, addr, DataArrayPtr[idx]);
  }
  return NumData;
}

u32 XLdpcRead_LDPC_QC_TABLE_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData) {
  u32 MaxDataDepth = (WordOffset + NumData);
  if (MaxDataDepth > XLDPC_LDPC_QC_TABLE_DEPTH) {
    return 0;
  }
  u32 idx;
  for(idx = 0; idx < NumData; idx++) {
    u32 addr =  XLDPC_LDPC_QC_TABLE_ADDR_BASE+(WordOffset + idx)*XLDPC_LDPC_QC_TABLE_STEP;
    DataArrayPtr[idx] = XLdpcReadReg(BaseAddress, addr);
  }
  return NumData;
}