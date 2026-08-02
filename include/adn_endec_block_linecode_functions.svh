function automatic logic is_valid_k(input logic [7:0] data);
  case (data)
    8'h1C, 8'h3C, 8'h5C, 8'h7C, 8'h9C, 8'hBC, 8'hDC, 8'hFC, 8'hF7, 8'hFB, 8'hFD, 8'hFE: return 1'b1;
    default: return 1'b0;
  endcase
endfunction

function automatic integer count_ones6(input logic [5:0] code);
  return code[0] + code[1] + code[2] + code[3] + code[4] + code[5];
endfunction

function automatic integer count_ones4(input logic [3:0] code);
  return code[0] + code[1] + code[2] + code[3];
endfunction

function automatic logic rd_after_6b(input logic rd_in, input logic [5:0] code);
  integer ones;
  ones = count_ones6(code);
  if (ones > 3) begin
    return 1'b1;
  end else if (ones < 3) begin
    return 1'b0;
  end else begin
    return rd_in;
  end
endfunction

function automatic logic rd_after_4b(input logic rd_in, input logic [3:0] code);
  integer ones;
  ones = count_ones4(code);
  if (ones > 2) begin
    return 1'b1;
  end else if (ones < 2) begin
    return 1'b0;
  end else begin
    return rd_in;
  end
endfunction

function automatic logic use_alt7(input logic [4:0] x, input logic rd_in);
  if (rd_in == 1'b0) begin
    case (x)
      5'd17, 5'd18, 5'd20: return 1'b1;
      default: return 1'b0;
    endcase
  end else begin
    case (x)
      5'd11, 5'd13, 5'd14: return 1'b1;
      default: return 1'b0;
    endcase
  end
endfunction

function automatic logic [5:0] encode_5b6b(input logic [4:0] x, input logic use_k28,
                                           input logic rd_in);
  case (x)
    5'd0: return rd_in ? 6'b011000 : 6'b100111;
    5'd1: return rd_in ? 6'b100010 : 6'b011101;
    5'd2: return rd_in ? 6'b010010 : 6'b101101;
    5'd3: return 6'b110001;
    5'd4: return rd_in ? 6'b001010 : 6'b110101;
    5'd5: return 6'b101001;
    5'd6: return 6'b011001;
    5'd7: return rd_in ? 6'b000111 : 6'b111000;
    5'd8: return rd_in ? 6'b000110 : 6'b111001;
    5'd9: return 6'b100101;
    5'd10: return 6'b010101;
    5'd11: return 6'b110100;
    5'd12: return 6'b001101;
    5'd13: return 6'b101100;
    5'd14: return 6'b011100;
    5'd15: return rd_in ? 6'b101000 : 6'b010111;
    5'd16: return rd_in ? 6'b100100 : 6'b011011;
    5'd17: return 6'b100011;
    5'd18: return 6'b010011;
    5'd19: return 6'b110010;
    5'd20: return 6'b001011;
    5'd21: return 6'b101010;
    5'd22: return 6'b011010;
    5'd23: return rd_in ? 6'b000101 : 6'b111010;
    5'd24: return rd_in ? 6'b001100 : 6'b110011;
    5'd25: return 6'b100110;
    5'd26: return 6'b010110;
    5'd27: return rd_in ? 6'b001001 : 6'b110110;
    5'd28: return use_k28 ? (rd_in ? 6'b110000 : 6'b001111) : 6'b001110;
    5'd29: return rd_in ? 6'b010001 : 6'b101110;
    5'd30: return rd_in ? 6'b100001 : 6'b011110;
    5'd31: return rd_in ? 6'b010100 : 6'b101011;
    default: return 6'b000000;
  endcase
endfunction

function automatic logic [3:0] encode_3b4b(input logic [2:0] y, input logic use_k_code,
                                           input logic rd_in, input logic alt7);
  case (y)
    3'd0: return rd_in ? 4'b0100 : 4'b1011;
    3'd1: return use_k_code ? (rd_in ? 4'b1001 : 4'b0110) : 4'b1001;
    3'd2: return use_k_code ? (rd_in ? 4'b0101 : 4'b1010) : 4'b0101;
    3'd3: return rd_in ? 4'b0011 : 4'b1100;
    3'd4: return rd_in ? 4'b0010 : 4'b1101;
    3'd5: return use_k_code ? (rd_in ? 4'b1010 : 4'b0101) : 4'b1010;
    3'd6: return use_k_code ? (rd_in ? 4'b0110 : 4'b1001) : 4'b0110;
    3'd7: return (use_k_code || alt7) ? (rd_in ? 4'b1000 : 4'b0111) : (rd_in ? 4'b0001 : 4'b1110);
    default: return 4'b0000;
  endcase
endfunction

task automatic encode_symbol(input logic [7:0] data, input logic is_k, input logic rd_in,
                             output logic valid, output logic [9:0] code, output logic rd_out);
  logic [4:0] x;
  logic [2:0] y;
  logic [5:0] sixb;
  logic [3:0] fourb;
  logic       rd_mid;
  logic       use_k28_code;
  logic       use_k7_code;
  logic       alt7;
  valid = 1'b0;
  code = 10'b0000000000;
  rd_out = rd_in;
  x = data[4:0];
  y = data[7:5];
  use_k28_code = is_k && (x == 5'd28);
  use_k7_code = is_k && (y == 3'd7) &&
                  ((x == 5'd23) || (x == 5'd27) || (x == 5'd29) || (x == 5'd30));

  if ((!is_k || is_valid_k(data)) && (!is_k || use_k28_code || use_k7_code)) begin
    sixb   = encode_5b6b(x, use_k28_code, rd_in);
    rd_mid = rd_after_6b(rd_in, sixb);
    alt7   = (!is_k && (y == 3'd7) && use_alt7(x, rd_mid));
    fourb  = encode_3b4b(y, is_k, rd_mid, alt7);
    code   = {fourb, sixb};
    rd_out = rd_after_4b(rd_mid, fourb);
    valid  = 1'b1;
  end
endtask

function valid_sync_header(input [1:0] sync_header);
  valid_sync_header = (sync_header == 2'b01) || (sync_header == 2'b10);
endfunction

function valid_sync_header4(input [3:0] sync_header);
  valid_sync_header4 = (sync_header != 4'b0000) && (sync_header != 4'b1111);
endfunction

task automatic scramble_64b66b_payload(input [63:0] payload_in, input [57:0] state_in,
                                       output [63:0] payload_out, output [57:0] state_out);
  reg     [57:0] history;
  reg            scrambled_bit;
  integer        bit_idx;
  begin
    history = state_in;
    payload_out = 64'b0;

    for (bit_idx = 0; bit_idx < 64; bit_idx = bit_idx + 1) begin
      scrambled_bit = payload_in[bit_idx] ^ history[19] ^ history[0];
      payload_out[bit_idx] = scrambled_bit;
      history = {scrambled_bit, history[57:1]};
    end

    state_out = history;
  end
endtask

task automatic descramble_64b66b_payload(input [63:0] payload_in, input [57:0] state_in,
                                         output [63:0] payload_out, output [57:0] state_out);
  reg     [57:0] history;
  reg            descrambled_bit;
  integer        bit_idx;
  begin
    history = state_in;
    payload_out = 64'b0;

    for (bit_idx = 0; bit_idx < 64; bit_idx = bit_idx + 1) begin
      descrambled_bit = payload_in[bit_idx] ^ history[19] ^ history[0];
      payload_out[bit_idx] = descrambled_bit;
      history = {payload_in[bit_idx], history[57:1]};
    end

    state_out = history;
  end
endtask

task automatic transform_128b130b_payload(input [127:0] payload_in, input [22:0] state_in,
                                          output [127:0] payload_out, output [22:0] state_out);
  reg     [22:0] lfsr;
  reg            scrambler_bit;
  integer        bit_idx;
  begin
    lfsr = state_in;
    payload_out = 128'b0;

    for (bit_idx = 0; bit_idx < 128; bit_idx = bit_idx + 1) begin
      scrambler_bit = lfsr[22] ^ lfsr[20] ^ lfsr[15] ^ lfsr[7] ^ lfsr[4] ^ lfsr[1];
      payload_out[bit_idx] = payload_in[bit_idx] ^ scrambler_bit;
      lfsr = {lfsr[21:0], scrambler_bit};
    end

    state_out = lfsr;
  end
endtask

task automatic transform_128b132b_payload(input [127:0] payload_in, input [22:0] state_in,
                                          output [127:0] payload_out, output [22:0] state_out);
  begin
    transform_128b130b_payload(payload_in, state_in, payload_out, state_out);
  end
endtask

function valid_sync_bit(input sync_bit);
  valid_sync_bit = (sync_bit == 1'b0) || (sync_bit == 1'b1);
endfunction

task automatic transform_256b257b_payload(input [255:0] payload_in, input [22:0] state_in,
                                          output [255:0] payload_out, output [22:0] state_out);
  reg     [22:0] lfsr;
  reg            scrambler_bit;
  integer        bit_idx;
  begin
    lfsr = state_in;
    payload_out = 256'b0;

    for (bit_idx = 0; bit_idx < 256; bit_idx = bit_idx + 1) begin
      scrambler_bit = lfsr[22] ^ lfsr[20] ^ lfsr[15] ^ lfsr[7] ^ lfsr[4] ^ lfsr[1];
      payload_out[bit_idx] = payload_in[bit_idx] ^ scrambler_bit;
      lfsr = {lfsr[21:0], scrambler_bit};
    end

    state_out = lfsr;
  end
endtask

task automatic encode_4b5b_symbol(input [3:0] data_in, output valid, output [4:0] code_out);
  begin
    valid = 1'b1;

    case (data_in)
      4'h0: code_out = 5'b11110;
      4'h1: code_out = 5'b01001;
      4'h2: code_out = 5'b10100;
      4'h3: code_out = 5'b10101;
      4'h4: code_out = 5'b01010;
      4'h5: code_out = 5'b01011;
      4'h6: code_out = 5'b01110;
      4'h7: code_out = 5'b01111;
      4'h8: code_out = 5'b10010;
      4'h9: code_out = 5'b10011;
      4'hA: code_out = 5'b10110;
      4'hB: code_out = 5'b10111;
      4'hC: code_out = 5'b11010;
      4'hD: code_out = 5'b11011;
      4'hE: code_out = 5'b11100;
      4'hF: code_out = 5'b11101;
      default: begin
        valid = 1'b0;
        code_out = 5'b00000;
      end
    endcase
  end
endtask

task automatic decode_5b4b_symbol(input [4:0] code_in, output valid, output [3:0] data_out);
  begin
    valid = 1'b1;

    case (code_in)
      5'b11110: data_out = 4'h0;
      5'b01001: data_out = 4'h1;
      5'b10100: data_out = 4'h2;
      5'b10101: data_out = 4'h3;
      5'b01010: data_out = 4'h4;
      5'b01011: data_out = 4'h5;
      5'b01110: data_out = 4'h6;
      5'b01111: data_out = 4'h7;
      5'b10010: data_out = 4'h8;
      5'b10011: data_out = 4'h9;
      5'b10110: data_out = 4'hA;
      5'b10111: data_out = 4'hB;
      5'b11010: data_out = 4'hC;
      5'b11011: data_out = 4'hD;
      5'b11100: data_out = 4'hE;
      5'b11101: data_out = 4'hF;
      default: begin
        valid = 1'b0;
        data_out = 4'h0;
      end
    endcase
  end
endtask
