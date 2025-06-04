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

/** \mainpage
 * LDPC Encoder/Decoder standalone low-level driver software API summary 
 * 
 * \section sec_init Initialization and Configuration
 * The XLdpc_Config structure is used by the driver to configure the interface parameters defined for each 
 * LDPC Encoder/Decoder device. The configuration structure is created by the tool-chain based on HW build properties.
 *
 * To support multiple runtime loading and initialization strategies employed by various operating systems, the driver 
 * instance can be initialized in one of two ways:
 * - XLdpcInitialize(InstancePtr, DeviceId)  - The driver looks up its own configuration structure created by the tool-chain 
 *                                             based on an ID provided by the tool-chain.
 * - XLdpcCfgInitialize(InstancePtr, CfgPtr) - Uses a configuration structure provided by the caller.
 *
 * \section sec_data Data Structures
 * One or more device specific headers are produced during the generation of the board support package, defining further 
 * device specific configuration parameters. A header is generated per LDPC code specified on the corresponding IP GUI;
 * x<ipinst_name >_<code_id>_params.h. Each header defines an XLdpcLdpcParameters structure populated with the configuration 
 * data required for the corresponding LDPC code.
 *
 * \section sec_api API
 * The driver provides the following functions:
 * - XLdpcAddLdpcParams(InstancePtr, CodeId, SCOffset, LAOffset, QCOffset, ParamsPtr) - Add LDPC parameters to a device
 * - XLdpcShareTableSize(ParamsPtr, SCSizePtr, LASizePtr, QCSizePtr)                  - Calculate share table size for a LDPC code
 * - XLdpcInterruptClassifier(InstancePtr)                                            - Classify interrupts
 *
 * In addition, the driver provides set and get functions for all the individual registers defined for the LDPC Encoder/Decoder.
 *
 * \section sec_ex Example
 * The processor based example design output by the LDPC Encoder/Decoder IP instance also includes an example application 
 * demonstrating a basic use case of the software driver.
 */

#ifndef XLDPC_H
#define XLDPC_H

#ifdef __cplusplus
extern "C" {
#endif

// Include Files
#include "xil_types.h"
#include "xil_assert.h"
#include "xstatus.h"
#include "xil_io.h"

#include "xldpc_hw.h"

// Standard constants
#define XLDPC_STANDARD_OTHER 0
#define XLDPC_STANDARD_5G    1

// Type Definitions

/** \brief Device configuration
 *
 * Contains configuration information for the device.
 */
typedef struct {
    u16     DeviceId;
    UINTPTR BaseAddress;
    u32     Standard;
    u32     InitAXISWidth;
} XLdpc_Config;

/** \brief LDPC Encoder/Decoder driver instance
 *
 * Contains state information for each device.
 */
typedef struct {
    UINTPTR BaseAddress;
    u32 IsReady;
    u32 Standard;
    u32 SCOffset[128]; /**< Lookup to SC table offsets for each code ID, updated by XLdpcAddLdpcParams */
    u32 LAOffset[128]; /**< Lookup to LA table offsets for each code ID, updated by XLdpcAddLdpcParams */
    u32 QCOffset[128]; /**< Lookup to QC table offsets for each code ID, updated by XLdpcAddLdpcParams */
} XLdpc;

/** \brief Struct defining LDPC code parameters
 *
 * Member values are defined in device specific header x<ipinst_name >_<code_id>_params.h. as per IP GUI configuration
 */
typedef struct {
  u32  N;
  u32  K;
  u32  PSize;
  u32  NLayers;
  u32  NQC;
  u32  NMQC;
  u32  NM;
  u32  NormType;
  u32  NoPacking;
  u32  NoFinalParity;
  u32  MaxSchedule;
  u32* SCTable;
  u32* LATable;
  u32* QCTable;
} XLdpcLdpcParameters;

/** \brief Interrupt class
 *
 * Members define interrupt class and action required
 */
typedef struct {
  u8 Intf;         /**< Triggered due to interface or control error (ISR) */
  u8 ECCSBit;      /**< Triggered due to single-bit ECC error (ECC_ISR)   */
  u8 ECCMBit;      /**< Triggered due to multi-bit ECC error (ECC_ISR)    */
  u8 RstReq;       /**< Device requires reset                             */
  u8 ReprogReq;    /**< Device requires LDPC codes reprogrammed           */
} XLdpcInterruptClass;

// API Function Prototypes

/** \brief Device initialization
 *
 * The driver looks up its own configuration structure created by the tool-chain based on an ID provided by the tool-chain.
 *
 * @param   InstancePtr Pointer device instance struct
 * @param   DeviceId    Tool-chain generated device ID to initialize, see xparameters.h
 *
 * @returns Exit code   Status
 */
int XLdpcInitialize(XLdpc *InstancePtr, u16 DeviceId);

/** \brief Configuration lookup
 *
 * Returns the configuration struct for a given device ID
 *
 * @param   DeviceId            Tool-chain generated device ID, see xparameters.h
 *
 * @returns LDPC configuration  Configuration struct for the 
 */
XLdpc_Config* XLdpcLookupConfig(u16 DeviceId);

/**\brief Device initialization
 *
 * Uses a configuration structure provided by the caller
 *
 * @param   InstancePtr Pointer device instance struct
 * @param   ConfigPtr   Pointer to configuraiton struct
 *
 * @returns Exit code   Status
 */
int XLdpcCfgInitialize(XLdpc *InstancePtr, XLdpc_Config *ConfigPtr);

/**\brief Add LDPC parameters to a device
 *
 * Updates LDPC code parameter registers and share tables using the specified CodeId and offsets with the specified parameters. 
 * The offsets arrays in the given XLdpc instance structure are updated with the supplied offsets for specified CodeId.  
 *
 * NOTE: When the device/IP has been configured to support the 5G NR standard the IP directly supports the 5G NR codes
 * and it is not necessary to add the codes at run-time. This function will generate an assertion if used on a instance
 * configured to support the 5G NR standard.
 *
 * @param InstancePtr Pointer to device instance struct
 * @param CodeId      Code number to be used for the specified LDPC code
 * @param SCOffset    Scale table offset to use for specified LDPC code
 * @param LAOffset    LA table offset to use for specified LDPC code
 * @param QSCOffset   QC table offset to use for specified LDPC code
 * @param ParamsPtr   Pointer to parameters struct for the LDPC code to be added to the device
 *
 */
void XLdpcAddLdpcParams(XLdpc *InstancePtr, u32 CodeId, u32 SCOffset, u32 LAOffset, u32 QCOffset, const XLdpcLdpcParameters* ParamsPtr);

/**\brief Calculate share table size for a LDPC code
 * 
 * Populates SCSizePtr, LASizePtr and QCSizePtr variables with the effective table size occupied by the specified 
 * LDPC code. These values can be used to increment the table offsets.
 *
 * @param ParamsPtr   Pointer to parameters struct for the LDPC code being queried
 * @param SCSizePtr   Pointer to variable to populate with the effective scale table size for the specified LDPC code
 * @param LASizePtr   Pointer to variable to populate with the effective LA table size for the specified LDPC code
 * @param QCSizePtr   Pointer to variable to populate with the effective QC table size for the specified LDPC code
 *
 */
void XLdpcShareTableSize(const XLdpcLdpcParameters* ParamsPtr, u32* SCSizePtr, u32* LASizePtr, u32* QCSizePtr);

/**\brief Classify interrupts
 * 
 * Queries interrupt status registers and classifies interrupt and reports recovery action
 * 
 * @param   InstancePtr       Pointer to device instance struct
 *
 * @returns Interrupt Class   Struct defining interrupt class and recover action
 */
XLdpcInterruptClass XLdpcInterruptClassifier(XLdpc *InstancePtr);

// Base API Function Prototypes
/**
 * CORE_AXI_WR_PROTECT access functions
 */
void XLdpcSet_CORE_AXI_WR_PROTECT(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_AXI_WR_PROTECT(UINTPTR BaseAddress);

/**
 * CORE_CODE_WR_PROTECT access functions
 */
void XLdpcSet_CORE_CODE_WR_PROTECT(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_CODE_WR_PROTECT(UINTPTR BaseAddress);

/**
 * CORE_ACTIVE access functions
 */
u32 XLdpcGet_CORE_ACTIVE(UINTPTR BaseAddress);

/**
 * CORE_AXIS_WIDTH access functions
 */
void XLdpcSet_CORE_AXIS_WIDTH_DIN_WORDS(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_AXIS_WIDTH_DIN_WORDS(UINTPTR BaseAddress);
void XLdpcSet_CORE_AXIS_WIDTH_DOUT_WORDS(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_AXIS_WIDTH_DOUT_WORDS(UINTPTR BaseAddress);
void XLdpcSet_CORE_AXIS_WIDTH(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_AXIS_WIDTH(UINTPTR BaseAddress);

/**
 * CORE_AXIS_ENABLE access functions
 */
void XLdpcSet_CORE_AXIS_ENABLE_CTRL(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_AXIS_ENABLE_CTRL(UINTPTR BaseAddress);
void XLdpcSet_CORE_AXIS_ENABLE_DIN(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_AXIS_ENABLE_DIN(UINTPTR BaseAddress);
void XLdpcSet_CORE_AXIS_ENABLE_DIN_WORDS(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_AXIS_ENABLE_DIN_WORDS(UINTPTR BaseAddress);
void XLdpcSet_CORE_AXIS_ENABLE_STATUS(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_AXIS_ENABLE_STATUS(UINTPTR BaseAddress);
void XLdpcSet_CORE_AXIS_ENABLE_DOUT(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_AXIS_ENABLE_DOUT(UINTPTR BaseAddress);
void XLdpcSet_CORE_AXIS_ENABLE_DOUT_WORDS(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_AXIS_ENABLE_DOUT_WORDS(UINTPTR BaseAddress);
void XLdpcSet_CORE_AXIS_ENABLE(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_AXIS_ENABLE(UINTPTR BaseAddress);

/**
 * CORE_ORDER access functions
 */
void XLdpcSet_CORE_ORDER(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_ORDER(UINTPTR BaseAddress);

/**
 * CORE_ISR access functions
 */
void XLdpcSet_CORE_ISR(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_ISR(UINTPTR BaseAddress);

/**
 * CORE_IER access functions
 */
void XLdpcSet_CORE_IER(UINTPTR BaseAddress, u32 Data);

/**
 * CORE_IDR access functions
 */
void XLdpcSet_CORE_IDR(UINTPTR BaseAddress, u32 Data);

/**
 * CORE_IMR access functions
 */
u32 XLdpcGet_CORE_IMR(UINTPTR BaseAddress);

/**
 * CORE_ECC_ISR access functions
 */
void XLdpcSet_CORE_ECC_ISR(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_ECC_ISR(UINTPTR BaseAddress);

/**
 * CORE_ECC_IER access functions
 */
void XLdpcSet_CORE_ECC_IER(UINTPTR BaseAddress, u32 Data);

/**
 * CORE_ECC_IDR access functions
 */
void XLdpcSet_CORE_ECC_IDR(UINTPTR BaseAddress, u32 Data);

/**
 * CORE_ECC_IMR access functions
 */
u32 XLdpcGet_CORE_ECC_IMR(UINTPTR BaseAddress);

/**
 * CORE_BYPASS access functions
 */
void XLdpcSet_CORE_BYPASS(UINTPTR BaseAddress, u32 Data);
u32 XLdpcGet_CORE_BYPASS(UINTPTR BaseAddress);

/**
 * CORE_VERSION access functions
 */
u32 XLdpcGet_CORE_VERSION_PATCH(UINTPTR BaseAddress);
u32 XLdpcGet_CORE_VERSION_REVISION(UINTPTR BaseAddress);
u32 XLdpcGet_CORE_VERSION_MINOR(UINTPTR BaseAddress);
u32 XLdpcGet_CORE_VERSION_MAJOR(UINTPTR BaseAddress);
u32 XLdpcGet_CORE_VERSION(UINTPTR BaseAddress);

/**
 * LDPC_CODE_REG0 access functions
 */
u32 XLdpcWrite_LDPC_CODE_REG0_N_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG0_N_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);
u32 XLdpcWrite_LDPC_CODE_REG0_K_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG0_K_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);
u32 XLdpcWrite_LDPC_CODE_REG0_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG0_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);

/**
 * LDPC_CODE_REG1 access functions
 */
u32 XLdpcWrite_LDPC_CODE_REG1_PSIZE_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG1_PSIZE_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);
u32 XLdpcWrite_LDPC_CODE_REG1_NO_PACKING_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG1_NO_PACKING_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);
u32 XLdpcWrite_LDPC_CODE_REG1_NM_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG1_NM_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);
u32 XLdpcWrite_LDPC_CODE_REG1_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG1_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);

/**
 * LDPC_CODE_REG2 access functions
 */
u32 XLdpcWrite_LDPC_CODE_REG2_NLAYERS_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG2_NLAYERS_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);
u32 XLdpcWrite_LDPC_CODE_REG2_NMQC_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG2_NMQC_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);
u32 XLdpcWrite_LDPC_CODE_REG2_NORM_TYPE_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG2_NORM_TYPE_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);
u32 XLdpcWrite_LDPC_CODE_REG2_NO_FINAL_PARITY_CHECK_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG2_NO_FINAL_PARITY_CHECK_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);
u32 XLdpcWrite_LDPC_CODE_REG2_MAX_SCHEDULE_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG2_MAX_SCHEDULE_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);
u32 XLdpcWrite_LDPC_CODE_REG2_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG2_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);

/**
 * LDPC_CODE_REG3 access functions
 */
u32 XLdpcWrite_LDPC_CODE_REG3_SC_OFF_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG3_SC_OFF_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);
u32 XLdpcWrite_LDPC_CODE_REG3_LA_OFF_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG3_LA_OFF_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);
u32 XLdpcWrite_LDPC_CODE_REG3_QC_OFF_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG3_QC_OFF_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);
u32 XLdpcWrite_LDPC_CODE_REG3_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_CODE_REG3_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);

/**
 * LDPC_SC_TABLE access functions
 */
u32 XLdpcWrite_LDPC_SC_TABLE_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_SC_TABLE_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);

/**
 * LDPC_LA_TABLE access functions
 */
u32 XLdpcWrite_LDPC_LA_TABLE_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_LA_TABLE_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);

/**
 * LDPC_QC_TABLE access functions
 */
u32 XLdpcWrite_LDPC_QC_TABLE_Words(UINTPTR BaseAddress, u32 WordOffset, const u32 *DataArrayPtr, u32 NumData);
u32 XLdpcRead_LDPC_QC_TABLE_Words(UINTPTR BaseAddress, u32 WordOffset, u32 *DataArrayPtr, u32 NumData);

// Macros (Inline Functions) Definitions
#define XLdpcWriteReg(BaseAddress, RegOffset, Data) \
    Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))
#define XLdpcReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))

#ifdef __cplusplus
}
#endif

#endif
