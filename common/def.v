`define DEFMACRO


/******************************************************/
`define N_IN  4    // 入力層のニューロン数
`define N_H   30     // 隠れ層のニューロン数
`define N_OUT 2    // 出力層のニューロン数
/******************************************************/

`define N_SHIFT 1    // 学習率　2のマイナス(N_SHIFT)乗

`timescale 1ns/1ps
`define CLOCK_PERIOD 100

`define W_DATA      8
`define W_WEIGHT    8
`define W_NEURON    12
`define W_ADDR      10

`define R_DATA   `W_DATA-1:0
`define R_WEIGHT `W_WEIGHT-1:0
`define R_NEURON `W_NEURON-1:0
`define R_ADDR   `W_ADDR-1:0



`define N_WH `N_IN * `N_H
`define N_WO `N_H * `N_OUT

// SRAMのアドレス定義
`define ADDR_WH_START     17'h0  // 入力-隠れ層の重み開始アドレス
`define ADDR_WO_START     `ADDR_WH_START + `N_WH  // 隠れ-出力層の重み開始アドレス
`define ADDR_INPUT_START  `ADDR_WO_START + `N_WO    // 入力データ開始アドレス
`define ADDR_LABEL_START  `ADDR_INPUT_START + `N_IN    // 入力データ開始アドレス
`define ADDR_OUTPUT_START `ADDR_LABEL_START + `N_OUT  // 出力結果の開始アドレス

`define ADDR_WH_END     `ADDR_WO_START - 1  // 入力-隠れ重み終了アドレス
`define ADDR_WO_END     `ADDR_INPUT_START - 1  // 隠れ-出力層の重み終了アドレス
`define ADDR_INPUT_END  `ADDR_LABEL_START - 1  // 入力データ終了アドレス
`define ADDR_LABEL_END  `ADDR_OUTPUT_START - 1  // 入力データ終了アドレス
`define ADDR_OUTPUT_END `ADDR_OUTPUT_START + `N_OUT - 1 // 出力結果の終了アドレス
