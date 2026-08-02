# adn_endec_encoder_manchester (module)

### Author : Foez Ahmed (foez.official@gmail.com)

## TOP IO
<img src="./adn_endec_encoder_manchester_top.svg">

## Parameters
|Name|Type|Dimension|Default Value|Description|
|-|-|-|-|-|
|DATA_W|integer||8|Width of the input data bus|
|INVERT_POLARITY|integer||0|Toggle to invert Manchester transition logic|

## Ports
|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|data_in|input|logic [DATA_W-1:0]||Parallel input data to be encoded|
|code_out|output|logic [(2*DATA_W)-1:0]||Serialized Manchester-encoded output|
## Description


### Purpose
This module implements a Manchester encoder that converts parallel input data into a serial Manchester-encoded bitstream. It maps each input bit to a two-bit code, where logic '0' and '1' are represented by specific transitions based on the configured polarity.

### Usage
To use this module, instantiate it in your design by specifying the `DATA_W` parameter to match your input data width. The `INVERT_POLARITY` parameter can be set to `1` to swap the transition logic if required by your physical layer protocol. The module performs combinatorial encoding, mapping each input bit to a 2-bit sequence at the output.

| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 1.0      | 2026-07-29 | Foez Ahmed      | Stable release                                         |

This file is part of ADN-VLSI/adn_endec
<br>**Copyright (c) 2026 ADN Semiconductors**
<br>**Licensed under the MIT License**
<br>**See LICENSE file in the project root for full license information**

