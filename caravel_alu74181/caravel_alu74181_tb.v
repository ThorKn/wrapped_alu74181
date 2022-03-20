// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps

module alu74181_tb;
	reg clock;
	reg RSTB;
	reg CSB;
	reg power1, power2;
	reg power3, power4;

	wire gpio;
	wire [37:0] mprj_io;
	reg M, C;
	reg [3:0] A, B, S;
	wire [7:0]  mprj_io_out;

	assign mprj_io_out = mprj_io[29:22];
	assign mprj_io[21:8] = {M, C, S, B, A};
	assign mprj_io[3] = (CSB == 1'b1) ? 1'b1 : 1'bz;

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #12.5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	initial begin
		$dumpfile("caravel_alu74181.vcd");
		$dumpvars(0, alu74181_tb);

		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (25) begin
		repeat (1000) @(posedge clock);
			// $display("+1000 cycles");
		end
		$display("%c[1;31m",27);
		`ifdef GL
			$display ("ALU 74181 Tests: Failed (GL), Timeout");
		`else
			$display ("ALU 74181 Tests: Failed (RTL), Timeout");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	initial begin
		// Testcase: Addition without carry
		M <= 1'b0;
		C <= 1'b1;
		S <= 4'b1001;
		B <= 4'b0000;
		A <= 4'b0001;
		wait(mprj_io_out == 8'b10000001);
		#1000

		$display("%c[1;25m",27);
		`ifdef GL
	    	$display("ALU 74181 Tests: Passed (GL)");
		`else
		    $display("ALU 74181 Tests: Passed (RTL)");
		`endif
		$display("%c[0m",27);
    $finish;
	end

	initial begin
		RSTB <= 1'b0;
		CSB  <= 1'b1;		// Force CSB high
		#2000;
		RSTB <= 1'b1;	  // Release reset
		#300000;
		CSB = 1'b0;		  // CSB can be released
	end

	// Power-up sequence
	initial begin
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;
		#100;
		power1 <= 1'b1;
		#100;
		power2 <= 1'b1;
		#100;
		power3 <= 1'b1;
		#100;
		power4 <= 1'b1;
	end

	// Observe changes in mprj_io 'state' (first 8 bits)
	always @(mprj_io) begin
		#1 $display("MPRJ-IO state = %b ", mprj_io[7:0]);
	end

	// Observe changes in mprj_io_out (8 bit)
	always @(mprj_io_out) begin
		#1 $display("MPRJ-IO-OUT state = %b ", mprj_io_out[7:0]);
	end

	// Observe changes in mprj_io_in (14 bit)
	always @(mprj_io[21:8]) begin
		$display("MPRJ-IO-IN = %b ", mprj_io[21:8]);
	end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD3V3;
	wire VDD1V8;
	wire VSS;

	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	caravel uut (
		.vddio	  (VDD3V3),
		.vddio_2  (VDD3V3),
		.vssio	  (VSS),
		.vssio_2  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (VDD3V3),
		.vdda1_2  (VDD3V3),
		.vdda2    (VDD3V3),
		.vssa1	  (VSS),
		.vssa1_2  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (VDD1V8),
		.vccd2	  (VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock    (clock),
		.gpio     (gpio),
		.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("caravel_alu74181.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

endmodule
`default_nettype wire
