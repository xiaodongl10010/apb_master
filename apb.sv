interface apb_if (input logic clk, input logic rst_n);
  // APB3 信号定义
  logic [31:0] paddr;
  logic        psel;
  logic        penable;
  logic        pwrite;
  logic [31:0] pwdata;
  logic [31:0] prdata;
  logic        pready;
  logic        pslverr;

  // Master 时序控制的 Clocking Block
  clocking cb @(posedge clk);
    default input #1ns output #1ns;
    output paddr, psel, penable, pwrite, pwdata;
    input  prdata, pready, pslverr;
  endclocking

  // --- Task: APB Write ---
  task automatic apb_write(input logic [31:0] addr, input logic [31:0] data);
    // Setup Phase
    @ (cb);
    cb.psel    <= 1'b1;
    cb.pwrite  <= 1'b1;
    cb.paddr   <= addr;
    cb.pwdata  <= data;
    cb.penable <= 1'b0;

    // Access Phase
    @ (cb);
    cb.penable <= 1'b1;

    // Wait for PREADY
    wait (cb.pready === 1'b1);
    
    // End of Transaction
    @ (cb);
    cb.psel    <= 1'b0;
    cb.penable <= 1'b0;
  endtask

  // --- Task: APB Read ---
  task automatic apb_read(input logic [31:0] addr, output logic [31:0] data);
    // Setup Phase
    @ (cb);
    cb.psel    <= 1'b1;
    cb.pwrite  <= 1'b0;
    cb.paddr   <= addr;
    cb.penable <= 1'b0;

    // Access Phase
    @ (cb);
    cb.penable <= 1'b1;

    // Wait for PREADY
    wait (cb.pready === 1'b1);
    data = cb.prdata; // 采样返回数据

    // End of Transaction
    @ (cb);
    cb.psel    <= 1'b0;
    cb.penable <= 1'b0;
  endtask

endinterface 


module tb_top;
    reg clk = 0;
    reg rst_n;
    always #5 clk = ~clk;

    // 实例化接口
    apb_if my_if(clk, rst_n);

    // 简单的测试激励
    initial begin
        logic [31:0] read_val;
        rst_n = 0;
        #20 rst_n = 1;

        // 调用接口内部的 task
        my_if.apb_write(32'hA000, 32'hDEADBEEF);
        my_if.apb_read(32'hA000, read_val);
        
        $display("Read back value: %h", read_val);
        #100 $finish;
    end
endmodule