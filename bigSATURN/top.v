`timescale 1us / 1ns

module top(
    input corerst,
    input memrst,
    input clk,
    input RX,
    output TX,
    input RXuser,
    output TXuser,
    output ready,
    inout [14:0]GPIOA ,
    inout [14:0]GPIOB 
    );
// conexiones entre la CPU y memoria de programa
wire [31:0]ins ; 
wire [31:0]pc ;
wire progfinished ;
// conexiones entre CPU y memoria de datos
wire RXfinished ;
wire TXfinished ;
wire timerfinished ;
wire [31:0]read ;
wire [31:0]write ;
wire [31:0]addrw ;
wire [31:0]addrr ;
wire we ;
wire busy ;
// concatenacion
wire [3:0]sysf = {timerfinished,TXfinished,RXfinished,progfinished} ;
// no conexiones
wire [15:0]extf = 16'b0 ; 
// conexion con el exterior
wire [14:0]gpioAconfig ;
wire [14:0]gpioBconfig ;
wire [14:0]gpioAread ;
wire [14:0]gpioBread ;
wire [14:0]gpioAwrite ;
wire [14:0]gpioBwrite ;

assign ready = progfinished ;

genvar i;
generate
    for (i = 0; i < 15; i = i + 1) begin : GEN_GPIOA
        assign GPIOA[i] = gpioAconfig[i] ? gpioAwrite[i] : 1'bZ;
        assign gpioAread[i] = GPIOA[i];
    end
endgenerate

generate
    for (i = 0; i < 15; i = i + 1) begin : GEN_GPIOB
        assign GPIOB[i] = gpioBconfig[i] ? gpioBwrite[i] : 1'bZ;
        assign gpioBread[i] = GPIOB[i];
    end
endgenerate

// instancia de la CPU
littleSATURN coreMOD(
    .extf(extf),
    .sysf(sysf),
    .rst(corerst), 
    .clk(clk),
	.ins(ins),
	.pc(pc),
	.busy(busy),
	.read(read),
	.write(write),
	.addrw(addrw),
	.addrr(addrr),
	.we(we));
// instancia de la ROM
progRAM pramMOD(
    .rst(memrst),
    .clk(clk),		       
    .pc(pc),     
    .RX(RX),
    .TX(TX),
    .ins(ins),  
    .progfinished(progfinished));
// instancia de la RAM
memorymap dramMOD(
    .clk(clk),
    .rst(corerst),
    .we(we),
    .addrw(addrw),
    .addrr(addrr),
    .write(write),
    .read(read),
    .busy(busy),
    .RX(RXuser),
    .TX(TXuser),
    .RXfinished(RXfinished),
    .TXfinished(TXfinished),
    .gpioAconfig(gpioAconfig),
    .gpioBconfig(gpioBconfig),
    .gpioAwrite(gpioAwrite),
    .gpioBwrite(gpioBwrite),
    .gpioAread(gpioAread),
    .gpioBread(gpioBread),
    .timerfinished(timerfinished));    
    
endmodule
