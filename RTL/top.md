
# Entity: dlp_top 
- **File**: top.v

## Diagram
![Diagram](dlp_top.svg "Diagram")
## Ports

| Port name | Direction | Type   | Description |
| --------- | --------- | ------ | ----------- |
| clk       | input     |        |             |
| rst_n     | input     |        |             |
| mem_addr  | output    | [15:0] |             |
| mem_ba    | output    | [2:0]  |             |
| mem_cas_n | output    |        |             |
| mem_cke   | output    |        |             |
| mem_clk   | inout     |        |             |
| mem_clk_n | inout     |        |             |
| mem_cs_n  | output    |        |             |
| mem_dm    | output    | [1:0]  |             |
| mem_dq    | inout     | [15:0] |             |
| mem_dqs   | inout     | [1:0]  |             |
| mem_odt   | output    | [0:0]  |             |
| mem_ras_n | output    |        |             |
| mem_we_n  | output    |        |             |

## Signals

| Name             | Type        | Description |
| ---------------- | ----------- | ----------- |
| ctrl_ven=1       | wire        |             |
| ctrl_hsync_pol=0 | wire        |             |
| ctrl_vsync_pol=0 | wire        |             |
| ctrl_blank_pol=0 | wire        |             |
| ctrl_daten_pol=0 | wire        |             |
| Thsync=8         | wire [ 7:0] |             |
| Thgdel=12        | wire [ 7:0] |             |
| Thgate=100       | wire [15:0] |             |
| Thlen=130        | wire [15:0] |             |
| Tvsync=1         | wire [ 7:0] |             |
| Tvgdel=2         | wire [ 7:0] |             |
| Tvgate=16        | wire [15:0] |             |
| Tvlen=22         | wire [15:0] |             |
| eoh              | wire        |             |
| eov              | wire        |             |
| load_ready       | wire        |             |
| load_data        | wire [23:0] |             |
| load_valid       | wire        |             |
| pclk             | wire        |             |
| hsync            | wire        |             |
| vsync            | wire        |             |
| blank            | wire        |             |
| daten            | wire        |             |
| pdata            | wire [23:0] |             |
| shift_taps       | wire [31:0] |             |
| local_wr_req     | wire        |             |
| local_wr_data    | wire [23:0] |             |
| local_wr_valid   | wire        |             |
| local_wr_ready   | wire        |             |
| local_rd_req     | wire        |             |
| local_rd_ready   | wire        |             |
| local_rd_data    | wire [23:0] |             |
| local_rd_valid   | wire        |             |

## Instantiations

- INST_VIDEO: video_pixel_gen
- INST_SHIFT: shift_register
- INST_DDR2: ddr2_controller
