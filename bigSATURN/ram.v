`timescale 1us / 1ns


module memorymap(
    input clk,				// reloj maestro
    input rst,              // reset maestro
    input we,				// habilitador de escritura
    input [31:0]addrw,		// direccion para escribir en la ram
    input [31:0]addrr,		// direccion para leer en la ram
    input [31:0]write,		// bus de entrada de datos
    output [31:0]read,		// bus de salida de datos
    output busy,            // bandera que genera stall
    input RX,
    output TX,
    output RXfinished ,
    output TXfinished ,
    output reg [14:0]gpioAconfig,
    output reg [14:0]gpioBconfig,
    output reg [14:0]gpioAwrite,
    output reg [14:0]gpioBwrite,
    input [14:0]gpioAread,
    input [14:0]gpioBread,
    output timerfinished 
);
// parametros de operacion
//##########################################################
	parameter SYSfreq = 50000000 ;                // frecuencia base
	parameter UARTfreq = 115200 ;                  // frecuencia deseada
    parameter ASYNCRAMsize = 256 ;                 // tamaño de memoria asincrona
    parameter SYNCRAMsize = 4096 ;                 // tamaño de memoria sincrona
    parameter MMIOSELLSB = 12 ;                    // inicio de selector MMIO
//##########################################################

























// ram asincrona
reg [31:0]asyncram [( ASYNCRAMsize - 1 ):0] ;
// ram sincrona
(* ram_style = "block" *) reg [31:0]syncram [( SYNCRAMsize - 1 ):0] ;
// registros de GPIO
reg [14:0]gpioAmask ;
reg [14:0]gpioBmask ;
reg [31:0]gpioAcontent ;
reg [31:0]gpioBcontent ;
// registros de UART
reg [7:0]TXreg ;
reg [7:0]RXreg ;
reg [7:0]UARTflags = 8'b0 ;
// registro de TIMERS
reg [15:0]timerconfig ;
//________________________decodificador de direcciones_________________________
wire [15:0]deviceselw = 1'b1 << addrw[ MMIOSELLSB + 3 : MMIOSELLSB ] ; 
wire [15:0]deviceselr = 1'b1 << addrr[ MMIOSELLSB + 3 : MMIOSELLSB ] ; 
//____________________________ram de alta velocidad____________________________
// comportamiento de escritura
always@( posedge clk )
begin
   if ( we == 1 && deviceselw[0] == 1'b1 )
      asyncram [addrw[ $clog2(ASYNCRAMsize) - 1 : 0 ] ] <= write ;
end
// comportamiento de la lectura
wire [31:0]asyncramout = asyncram [ addrr[ $clog2(ASYNCRAMsize) - 1 : 0 ] ] ;
//____________________________ram de baja velocidad____________________________
reg [31:0]syncramout ;
reg [31:0]accessreminder ;
reg rambusytemp = 1'b0 ;
always@( posedge clk )
begin
    // ciclo de escritura
    if ( we == 1 && deviceselw[1] == 1'b1 )
        syncram [ addrw[ $clog2(SYNCRAMsize) - 1 : 0 ] ] <= write ;
    //  ciclo de lectura
    syncramout <= syncram [ addrr[ $clog2(SYNCRAMsize) - 1 : 0 ] ] ; 
    // envio de señal busy en cambio de consulta
    accessreminder <= addrr ;
    if (accessreminder != addrr && deviceselr[1] == 1'b1 )
        rambusytemp <= 1'b0 ;
    else
        rambusytemp <= 1'b1 ; 
end
wire rambusy = rambusytemp & deviceselr[1] ;
assign busy = rambusy ;
//_________________________________modulo gpio_________________________________
reg [31:0]gpioout ;
reg [14:0]gpioAtemp1, gpioBtemp1 ;

always@ ( posedge clk )
begin
    if (rst) begin
        gpioAconfig <= 15'b0;
        gpioBconfig <= 15'b0;
        gpioAmask <= 15'b0;
        gpioBmask <= 15'b0;
        gpioAwrite <= 15'b0;
        gpioBwrite <= 15'b0;

    end
    else     
    // registros de configuracion de puertos GPIO
    if ( we == 1 && deviceselw[2] == 1'b1 )
        case ( addrw[2:0] )
            3'b000 : gpioAconfig <= write[14:0] ; 
            3'b001 : gpioAmask <= write[14:0] ; 
            3'b010 : gpioBconfig <= write[14:0] ; 
            3'b011 : gpioBmask <= write[14:0] ;
            3'b100 : gpioAwrite <= write[14:0] ;
            3'b110 : gpioBwrite <= write[14:0] ;
            default : ;
        endcase
    // sincronizacion puertos GPIO
    gpioAtemp1 <= gpioAread ;  
    gpioBtemp1 <= gpioBread ;

    // lectura de puertos GPIO
    gpioAcontent <= gpioAtemp1 & gpioAmask ;
    gpioBcontent <= gpioBtemp1 & gpioBmask ;
end

// asignacion de selector de puerto
always @ ( * )
begin
    case ( addrr[2:0] )
        3'b100 : gpioout = { 17'b0, gpioAwrite } ;
        3'b101 : gpioout = { 17'b0, gpioAcontent } ;
        3'b110 : gpioout = { 17'b0, gpioBwrite } ;
        3'b111 : gpioout = { 17'b0, gpioBcontent } ;
        default: gpioout = 32'b0 ;
    endcase
end
//_________________________________modulo UART_________________________________
// generado de reloj a 115200x16hz
parameter RXfreq =  ( SYSfreq / UARTfreq ) / 32 ;
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
// logica de conteo de pulsos
reg[7:0] pulsecount = 0 ;
reg RXbegin = 0 ;
reg RXfinish = 1'b0 ;
always@ ( posedge RXclk)
begin
    if ( pulsecount < 159 && RXbegin )
        pulsecount <= pulsecount + 1 ;
    else
        pulsecount <= 0 ;
end
// logica de startbit
always@ ( posedge RXclk)
begin
    if ( RXbegin == 1'b0 && RX == 1'b0 )
        RXbegin <= 1'b1 ;
    else
        if ( pulsecount == 159 )
        RXbegin <= 1'b0 ;
    if ( pulsecount == 151 && RXbegin == 1'b1 )
        RXfinish <= 1'b1 ;
    else
        RXfinish <= 1'b0 ;
end
// recoleccion de datos
reg [7:0]temporaldata ;
always@( posedge RXclk )
begin
   case (pulsecount)
   23:  temporaldata[0] <= RX ; // data0
   39:  temporaldata[1] <= RX ; // data1
   55:  temporaldata[2] <= RX ; // data2
   71:  temporaldata[3] <= RX ; // data3
   87:  temporaldata[4] <= RX ; // data4
   103: temporaldata[5] <= RX ; // data5
   119: temporaldata[6] <= RX ; // data6
   135: temporaldata[7] <= RX ; // data7
   default : temporaldata <= temporaldata ;
   endcase
end
//obtencion de datos
always@( posedge RXclk )
begin
   if ( rst == 1'b1 )
       RXreg <= 8'b0 ;
   else 
        if ( RXfinish == 1'b1 )
            RXreg <= temporaldata ;    
        else
            RXreg <= RXreg ;
end
// envio de datos TX
reg TXfinish = 1'b0 ;
reg TXbegin = 1'b0 ;
reg [7:0]TXcounter ;
always@( posedge clk )
begin
    if ( we == 1 && deviceselw[3] == 1'b1 && addrw[1:0] == 2'b00 )
    begin
        TXreg <= write[7:0] ;
        TXbegin <= 1'b1 ;
        TXfinish <= 1'b0 ;
    end     
    if (TXcounter == 177 )
    begin
        TXbegin <= 1'b0 ;
        TXfinish <= 1'b0 ;
    end
    if (TXcounter == 176 )
        TXfinish <= 1'b1 ; 
end
// envio de datos
reg TXtemp = 1'b1 ;
always@( posedge RXclk )
begin
    if ( rst == 1'b1)
    begin
        TXcounter <= 8'b0 ;
        TXtemp <= 1'b1 ;
    end
    else
        if ( TXbegin == 1'b1 )
            TXcounter <= TXcounter + 1 ;
        else
            TXcounter <= 8'b0 ;
    case ( TXcounter )
    0:      TXtemp <= 1'b1 ;        
    15:     TXtemp <= 1'b0 ;
    31:     TXtemp <= TXreg[0] ;
    47:     TXtemp <= TXreg[1] ;
    63:     TXtemp <= TXreg[2] ;
    79:     TXtemp <= TXreg[3] ;
    95:     TXtemp <= TXreg[4] ;
    111:    TXtemp <= TXreg[5] ;
    127:    TXtemp <= TXreg[6] ;
    143:    TXtemp <= TXreg[7] ;
    159:    TXtemp <= 1'b1 ;
    default : TXtemp <= TXtemp ;
    endcase 
end
assign TX = TXtemp;
// manejo de banderas 
reg [7:0] UARTflagtemp;
reg TXflagsticky ;
reg RXflagsticky ;
wire TXrise= TXfinish & ~TXflagsticky ;
wire RXrise= RXfinish & ~RXflagsticky ;
always@( posedge clk )
begin
    // toma de banderas sticky
    TXflagsticky <= TXfinish ;
    RXflagsticky <= RXfinish ;
    // estritura en el registro
    if ( we == 1 && deviceselw[3] == 1'b1 && addrw[1:0] == 2'b10 )
        UARTflags <= write[7:0] ;  
    else
    begin
        UARTflags[7:2] <= 6'b0 ;
        if (TXrise) UARTflags[0] <= 1'b1 ;
        if (RXrise) UARTflags[1] <= 1'b1 ;
    end
end
assign TXfinished = UARTflags[0] ;
assign RXfinished = UARTflags[1] ; 
// manejo de registro hacia el bus de datos
reg [31:0]uartout ;
always@( * )
begin
    case ( addrr[1:0] )
        2'b00 : uartout = TXreg ;
        2'b01 : uartout = RXreg ;
        2'b10 : uartout = UARTflags ;
        default: uartout = 32'b0;
    endcase
end
//____________________________________timers___________________________________
reg wetemp ; 
reg [31:0]timercounter = 16'b0 ;
reg [31:0]countconfig = 32'b0 ;
reg [13:0]times = 14'b0 ;
wire timerstart = ( times != 0 ) ? 1'b1 : 1'b0 ;
parameter us = SYSfreq / 1000000 ;  
parameter ms = SYSfreq / 1000 ;
parameter s = SYSfreq ;
// escritura en el registro
always@( posedge clk )
begin
    // configuracion
    if ( we == 1 && deviceselw[4] == 1'b1 && addrw[0] == 1'b0 )
    begin
        timerconfig <= write[15:0] ;
        wetemp <= we ;
    end  
    else
        wetemp <= 1'b0 ; 
end
// configuracion y ciclo de conteo
always@( posedge clk )
begin
    
    // unidad de conteo
    case ( timerconfig[1:0] )
        default : countconfig <= 1 ;
        2'b01: countconfig <= us ;
        2'b10: countconfig <= ms ;
        2'b11: countconfig <= s ;
    endcase
    // carga de valor a contar
    if ( timercounter == 0 && wetemp == 1'b1 )
        times <= timerconfig[15:2] ;
    // logica de conteo
    if ( rst == 1'b1 )
    begin
        timercounter <= 0 ;
        times <= 14'b0 ;
    end   
    else
        if ( timercounter == ( countconfig - 1 ) && timerstart == 1'b1  ) 
        begin
            times <= times - 1 ;
            timercounter <= 0 ;
        end
        else
            if ( timerstart == 1'b1 )
                timercounter <= timercounter + 1 ;
            else
                timercounter <= 1'b0 ;                  
end
wire [15:0]timerout = ( addrr[0] == 1'b1 ) ? times : 16'b0 ;
assign timerfinished = ~timerstart ;
//_________________manejo de consulta de multiples perifericos_________________
assign read =   asyncramout &     {32{deviceselr[0]}} |
                syncramout &      {32{deviceselr[1]}} |
                gpioout &         {32{deviceselr[2]}} |
                uartout &         {32{deviceselr[3]}} |
                timerout &         {32{deviceselr[4]}};
endmodule

