`timescale 1ns / 1ps

module risc_tb;

  reg clk;

  risc uut (
    .clk(clk)
  );

  initial begin
    clk = 0;
    forever #10 clk = ~clk;  
  end

  integer i,f,k;
  initial begin
    #1;
    
    uut.dp.pc= 1'b0;
    uut.dp.au.result=16'd0;
    for (i = 0; i < 32; i = i + 1) begin
      uut.dp.reg_file.registers[i] = 16'h0000;
    end

    for (i = 0; i < 65536; i = i + 1) begin
      uut.dp.dm.memory[i] = 16'h0000;
   end

    $display("Registers and Data Memory initialized to zero.");

   #1000;

  $display("\n===== Final Register Values =====");
  for (i = 0; i < 32; i = i + 1) begin
    $display("R[%0d] = %h", i, uut.dp.reg_file.registers[i]);
  end

  $display("\n===== Final First 32 Data Memory Values  =====");
  for (i = 0; i < 32; i = i + 1) begin
    $display("Mem[%0d] = %h", i, uut.dp.dm.memory[i]);
  end
  
    f = $fopen("C:/Users/Pranav/Desktop/registers.txt", "w");
    for (i = 0; i < 32; i = i + 1)
        $fdisplay(f, "R[%0d] = %h", i, uut.dp.reg_file.registers[i]); 
    $fclose(f);
    
    f = $fopen("C:/Users/Pranav/Desktop/memory.txt", "w");
    for (i = 0; i < 256; i = i + 1) begin
        for (k = 0; k < 256; k = k + 1) begin
            $fwrite(f, "%h ", uut.dp.dm.memory[i * 256 + k]);
        end
        $fwrite(f, "\n"); 
    end
    $fclose(f);
    
    $finish;
end
  

endmodule
