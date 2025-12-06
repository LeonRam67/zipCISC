module progRAM(
    input rst,
    input clk,		       // reloj maestro
    input [7:0]pc,      // direccion para leer en la ram
    input RX,
    output TX,
    output reg [31:0]ins,  // bus de salida de datos
    output progfinished
);
// parametros de operacion
//##########################################################
parameter SYSfreq = 50000000 ;                // frecuencia base
parameter UARTfreq = 115200 ;                  // frecuencia deseada
parameter size = 256 ;                         // tamaño de memoria
parameter addrstart = 16 ;                    // inicio del programa
//##########################################################
parameter RXfreq =  ( SYSfreq / UARTfreq ) / 32 ;
// memoria RAM
(* ram_style = "block" *) reg [31:0]memory [(size-1):0] ;













//__________________________________________________________
// generado de reloj a 115200x16hz
reg [15:0] RXcounter = 0 ;
reg RXclk;
// divisor de reloj para RX
always@( posedge clk )
begin
if (rst) 
begin
    RXcounter <= 0;
    RXclk <= 1'b0;
end 
else 
    begin
   if( RXcounter == RXfreq - 1)
    begin
        RXclk <= ~RXclk;
        RXcounter <= 0 ;
    end
    else
    begin
        RXcounter <= RXcounter + 1 ;
    end
    end
end
//__________________________________________________________
// logica de conteo de pulsos
reg[7:0] pulsecount = 0 ;
reg started = 0 ;
reg finished = 0 ;
always@ ( posedge RXclk)
begin
    if ( pulsecount < 159 && started )
        pulsecount <= pulsecount + 1 ;
    else
        pulsecount <= 0 ;
end
//__________________________________________________________
// logica de startbit
always@ ( posedge RXclk)
begin
    if ( started == 1'b0 && RX == 1'b0 )
        started<= 1'b1 ;
    else
        if ( pulsecount == 159 )
        started <= 1'b0 ;
    if ( pulsecount == 151 && started == 1'b1 )
        finished <= 1'b1 ;
    else
        finished <= 1'b0 ;
end
//__________________________________________________________
// recoleccion de datos
reg [7:0]temporaldata ;
always@( posedge RXclk )
begin
   case (pulsecount)
   23: temporaldata[0] <= RX ; // data0
   39: temporaldata[1] <= RX ; // data1
   55: temporaldata[2] <= RX ; // data2
   71: temporaldata[3] <= RX ; // data3
   87: temporaldata[4] <= RX ; // data4
   103: temporaldata[5] <= RX ; // data5
   119: temporaldata[6] <= RX ; // data6
   135: temporaldata[7] <= RX ; // data7
   default : temporaldata <= temporaldata ;
   endcase
end
//__________________________________________________________
// alineacion de datos a 32 bits
reg [1:0]endiancounter = 0 ;
reg [31:0]datainput = 32'b0 ;
always@( posedge RXclk )
begin
   if ( rst == 1'b1 )
   begin
       endiancounter <= 0 ;
       datainput <= 32'b0 ;
   end
   else 
   begin
       if ( finished == 1'b1 )
           endiancounter <= endiancounter + 1 ;
           
       case ( endiancounter )
       0: datainput[7:0] <= temporaldata ; // endian0
       1: datainput[15:8] <= temporaldata ; // endian1
       2: datainput[23:16] <= temporaldata ; // endian2
       3: datainput[31:24] <= temporaldata ; // endian3
       default : datainput <= 32'b0 ;
   endcase
   end
end

//__________________________________________________________
// bandera de termino de alineacion y captura
reg wordcompleted = 1'b0 ;
reg wordcomptemp = 1'b0 ;
always@( posedge clk )
begin
   if ( endiancounter == 3 && pulsecount == 143 )
   begin
       wordcomptemp <= 1'b1 ;
       wordcompleted <= 1'b1 ;
       if ( wordcomptemp == 1'b1  )
           wordcompleted <= 1'b0 ;
   end
   else
   begin
           wordcompleted <= 1'b0 ;
           wordcomptemp <= 1'b0 ;
   end
end
//__________________________________________________________
// ciclo de escritura
reg [31:0]indexcount = addrstart ;
reg transmitionfinished = 1'b0;
always@( posedge clk )
begin
if ( rst == 1'b1 || datainput == 32'h0000AAAA )
begin
   indexcount <= addrstart ;
   transmitionfinished <= 1'b0 ;
end
else
    if ( wordcompleted == 1'b1 )
    begin
        if ( datainput == 32'h00005555 )
            transmitionfinished <= 1'b1 ;
        else
            if ( transmitionfinished == 1'b0  )
            begin
                indexcount <= indexcount + 1 ;
                memory[indexcount] <= datainput ; 
            end
    end 
        else
        indexcount <= indexcount ;
end 
assign progfinished = transmitionfinished ;
//__________________________________________________________
// inicializacion de la memoria 
initial begin
    memory[0] = 32'b00000000000000000000000000000000;
    memory[1] = 32'b10000000000000001000000000000000;
    memory[2] = 32'b00000000000000000000000000000000;
    memory[3] = 32'b10000000010000000000000000000000;
    memory[4] = 32'b10101011000100000000000000001011;
    memory[5] = 32'b10101010100111111111111111111101;
    memory[6] = 32'b00000000000000000000000000000000;
    memory[7] = 32'b00000000000000000000000000000000;
    memory[8] = 32'b00000000000000000000000000000000;
    memory[9] = 32'b00000000000000000000000000000000;
    memory[10] = 32'b00000000000000000000000000000000;
    memory[11] = 32'b00000000000000000000000000000000;
    memory[12] = 32'b00000000000000000000000000000000;
    memory[13] = 32'b00000000000000000000000000000000;
    memory[14] = 32'b00000000000000000000000000000000;
    memory[15] = 32'b00000000000000000000000000000000;
end
//__________________________________________________________
// ciclo de lectura
always@( posedge clk ) ins <= memory[pc] ;
endmodule
