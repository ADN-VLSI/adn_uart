interface uart_if;

  /////////////////////////////////////////////////////////
  // SIGNALS
  /////////////////////////////////////////////////////////

  tri1 line;
  logic tx_driver;

  assign line = tx_driver;

  /////////////////////////////////////////////////////////
  // CONFIGURATION
  /////////////////////////////////////////////////////////

  int  baud_rate = 9600;  // 19200 115200
  bit  parity_en = 0;     // 0:disabled 1:enabled
  bit  parity_type = 0;   // 0:even 1:odd
  bit  extra_stop = 0;    // 0:disabled 1:enabled
  int  data_bits = 8;     // 5, 6, 7, 8

  /////////////////////////////////////////////////////////
  // METHOD
  /////////////////////////////////////////////////////////

  task automatic send(
    input int data, 
    input int BAUD_RATE = baud_rate, 
    input bit PARITY_EN = parity_en, 
    input bit PARITY_TYPE = parity_type,     // 0 -> EVEN and 1 -> ODD
    input bit EXTRA_STOP = extra_stop, 
    input int DATA_BITS = data_bits
    );

    time BITS_TIME;
    bit parity;
    int i;

    BITS_TIME = 1s / BAUD_RATE;

    // Calculate parity
    parity = 0;
    for (i = 0; i < DATA_BITS; i++) begin
        parity = parity ^ data[i];
    if (PARITY_TYPE)                    // ODD parity
        parity = ~parity;
    end

    // IDLE
    tx_driver = 1'b1;        
    #BITS_TIME

    // START BIT
    tx_driver = 1'b0;        
    #BITS_TIME

    // Data bits (LSB first)
    for(i = 0; i < DATA_BITS; i++) begin
        tx_driver = data[i];
        #BITS_TIME;
    end

    // Parity bit enable or not
    if (PARITY_EN) begin
        tx_driver = parity;
        #BITS_TIME;
    end

    // Stop bit
    tx_driver = 1'b1;
    #BITS_TIME;

    // Second stop bit (Optional)
    if (EXTRA_STOP) begin
        tx_driver = 1'b1;
        #BITS_TIME;
    end

  endtask

  task automatic recv(
    output int data, 
    output bit parity, 
    input int BAUD_RATE = baud_rate, 
    input bit PARITY_EN = parity_en, 
    input bit PARITY_TYPE = parity_type, 
    input bit EXTRA_STOP = extra_stop, 
    input int DATA_BITS = data_bits
    );

    time BITS_TIME;
    int i;

    BITS_TIME = 1s / BAUD_RATE;

    data = 0;
    parity = 0;

    // Wait for start bit
    @(negedge tx_driver);

    // Move to center of first data bit
    #(BITS_TIME + BITS_TIME / 2);

    // Receive data bits (LSB First)
    for (i = 0; i < DATA_BITS; i++) begin
        data[i] = tx_driver;
        #BITS_TIME;
    end

    // Receive Parity
    if (PARITY_EN) begin
        parity = tx_driver;
        #BITS_TIME;
    end

    // Consume stop bit
    #BITS_TIME;

    // Consume second stop bit (Optional: if used)
    if (EXTRA_STOP)
        #BITS_TIME;
    
  endtask

endinterface
