// /================================================================================================================================================\
// ||                                              																									||
// ||                                                                 CORE              															||
// ||                                              																									||
// \================================================================================================================================================/
module littleSATURN(
    // entradas generales
	input wire [15:0]extf,		// banderas externas
	input wire [3:0]sysf,
    input wire rst,				// reset maestro
    input wire clk,				// reloj maestro
    // conexion con la ROM de instrucciones
	input wire[31:0]ins,		// entrada de instrucciones
	output wire[31:0]pc,		// salida de contador de programas
	// conexion con la RAM de datos
	input wire busy,			// se?al de espera de memorias
	input wire[31:0]read,	// datos RAW
	output wire[31:0]write,	// datos PROCC
	output wire[31:0]addrw,	// localidades ADDRSET
	output wire[31:0]addrr,	// localidades ADDRGET
	output wire we			// habilitador DPPBUS
);
wire [11:0]intf;
wire [31:0]insfix ;
wire stop ;
// instancias
controlunit controlMOD(
   .rst(rst),                
   .clk(clk),  
   .miss(busy),
   .ins(ins),  
   .gpr(write),          
   .intf(intf),      
   .sysf(sysf),
   .extf(extf),
   .stack(read),          
   .pc(pc),  
   .insbuffer(insfix),
   .stop(stop));
datapath datapathMOD(
    .rst(rst),
	.ins(insfix),
	.clk(clk),
	.miss(stop),
	.pcin(pc),
	.ramin(read),
	.dataout(write),
	.fout(intf),
	.ramwe(we),
    .addrw(addrw),
    .addrr(addrr));
endmodule
//╔════════════════════════════════════════════════════════════════════════════════════════════════╗
//║										UNIDAD DE CONTROL										   ║
//╚════════════════════════════════════════════════════════════════════════════════════════════════╝
module controlunit(
   input rst,                	// reset maestro
   input clk,                	// reloj maestro
    input miss,					// bandera de carga de cache
   input [31:0]ins,         	// entrada de instrucciones
    input [31:0]gpr,			// entrada de registro base
   input [11:0]intf,         	// entrada de banderas ALU
    input [3:0]sysf,			// entrada de banderas del sistema
    input [15:0]extf,			// entrada de banderas de usuario
   input [31:0]stack,        	// entrada de la pila
   output [31:0]pc,   		    // contador de programas
   output reg [31:0]insbuffer,      // salida de instrucciones
   output stop
);
//________________________________ modo de salto ______________________________________
reg [31:0]pctemp = 32'b0;
wire [3:0] mode ;
assign mode = 4'b0001 << ins[21:20] ;
// modos de salto
wire [31:0] absolute = ({{12{1'b0}}, ins[19:0]})                      & {32{mode[0]}};
wire [31:0] relative = (pctemp + {{12{ins[19]}}, ins[19:0]})          & {32{mode[1]}};
wire [31:0] hybrid   = ((ins[11:0] + {{24{ins[19]}}, ins[19:12]}))    & {32{mode[2]}};
wire [31:0] rbase    = (gpr + ins[15:0])                              & {32{mode[3]}};

// selector de modo
wire [31:0]target 	= absolute | relative | hybrid | rbase ;
//___________________________________ banderas ________________________________________
wire [31:0]flagvector ;
assign flagvector = { extf, sysf, intf } ;
// seleccion de salto a realizar
wire [31:0]jumpselector ;
assign jumpselector = 32'b1 << ins[26:22] ;
// se?al de mascara entre jumpselector y la bandera a usar
wire [31:0]flagmask ;
assign flagmask = jumpselector & flagvector ;
// salto si la mascara fue diferente de cero
wire jump ;
assign jump = |flagmask ;
reg jumped = 1'b1 ;
//_____________________________________ estados _______________________________________					
parameter idle = 0 ;        // inicio del CPU, no hace nada y reinicia el conteo
parameter execute = 1 ;     // flujo normal de programs
parameter halt = 2 ;		// ciclo de HALT
// alternador de estados
reg [1:0]state = idle ;
reg [1:0]next = idle ;												
// arranque del procesador
always@( posedge clk )
begin
    if(rst)
        state <= idle ;	// vuelve al inicio si se presiona reset sincrono
    else
        state <= next ; // avance normal del procesador
end
//_______________________________ maquina de estados __________________________________
always@( posedge clk )
begin
    case( state )
//estado de inicializacion del procesador 
        idle :
            begin
                pctemp <= 0 ;	// reinicio del conteo
            end
//flujo normal del programa 
        execute :
            begin
            // espera a que no haya habido miss en la instruccion acual
            if ( miss == 1'b0 )							
                case( ins[31:27] )
                    // HALT
                    5'b10011 : pctemp <= pctemp ;
                    // JUMP INC/CON
                    5'b10101 : // cambia el PC al valor inmediato si jump = 1
                        if( jump == 1'b1 )
                            begin
                            pctemp <= target ;
                            jumped <= 1'b0 ;
                            end				
                        else
                            pctemp <= pctemp + 1 ;
                    // CALL
                    5'b10110 : // salto a subrutina
                       begin
                       pctemp <= target ;	
                       jumped <= 1'b0 ;
                       end
                    // RET
                    5'b10111 : // retorno de subrutina
                       begin
                       pctemp <= stack + 1;   
                       jumped <= 1'b0 ;
                       end 
                    // cualquier otra instruccion
                    default : 
                       begin
                       pctemp <= pctemp + 1 ;
                       jumped <= 1'b1 ;
                       end
                endcase
            // si hubo miss en la instruccion
            else
                pctemp <= pctemp ;	// espera un ciclo de reloj
            end
//estado de halt
        halt :
            pctemp <= pctemp ;
    endcase
end
//________________________________ cambio de estado ___________________________________
always @(*)
begin
    case( state )
        // idle > execute
        idle : next = execute ; 	
        // execute > halt
        execute :
            if ( ins[31:27] == 5'b10011 )
                next = halt ;			
            else
                next = execute ;
        // halt > idle
        halt :
            if(rst)
                next = idle ;    	
            else
                next = halt ;
    endcase
end
//_______________________________ manejo de retardos __________________________________
reg [31:0]oldins ;
reg oldmiss ;
always @( posedge clk )
begin
  oldins <= ins ;  
  oldmiss <= miss ;    
end
//__________________________ manejo de peligros al saltar _____________________________
always @(*)
begin
  if ( oldmiss == 1'b0 )
      insbuffer = ins & {32{jumped}} ; 
  else
      insbuffer = oldins ;
end

assign pc = pctemp;  
assign stop = miss ; 
                                                                            
endmodule
//╔════════════════════════════════════════════════════════════════════════════════════════════════╗
//║									    	DATAPATH										  	   ║
//╚════════════════════════════════════════════════════════════════════════════════════════════════╝
module datapath(
    input wire rst,				// reset maestro
    input wire[31:0]ins,		// instrucciones
    input wire clk,				// reloj maestro
    input wire miss,            // señal de handshake
    input wire [31:0]pcin,		// programa actual
    input wire [31:0]ramin,		// entrada de datos RAW
    output wire[31:0]dataout,	// salida de datos PROCC
    output wire[11:0]fout,		// salida de banderas
    output wire ramwe ,			// habilitador de escritura WE
    output wire [31:0]addrw ,	// localidades escritura ADDRSET
    output wire [31:0]addrr 	// localidades lectura ADDRGET
);
// conexion entre alu y flags
wire [11:0]f ;
// conexion entre gpr y decoderram
wire [31:0]SP ;
wire [31:0]Y ;
wire [31:0]X ;
wire [31:0]BE ;
wire [31:0]I ;
// conexion entre decoderram y gpr
wire [3:0]selI ;
wire [3:0]selW ;
// conexion entre reminder, gpr y ramtemp
wire we ;
wire pushe ;
wire pulle ;
// conexion entre decoderalu y gpr
wire [3:0]selA ;
wire [3:0]selB ;
// conexion entre gpr y decoderalu
wire [31:0]A ;
wire [31:0]B ;
// conexion entre decoderalu y alu
wire [31:0]Aout ;
wire [31:0]Bout ;
wire [3:0]op ;
// instancias
flagcontrol modFLAG(
    .clk(clk),
    .ins(ins),
    .fin(f),
    .fout(fout));
decoderINDEX modDECRAM(
    .ins(ins),
    .spin(SP),
    .win(Y),
    .rin(X),
    .iin(I),
    .bein(BE),
    .addrw(addrw),
    .addrr(addrr),
    .seli(selI),
    .selw(selW));
remindercontrol modREM(
    .miss(miss),
    .ins(ins),
    .gprwe(we),
    .ramwe(ramwe),
    .pushe(pushe),
    .pulle(pulle));
gpr modGPR(
    .rst(rst),
    .clk(clk),
    .we(we),
    .pushe(pushe),
    .pulle(pulle),
    .selA(selA),
    .selB(selB),
    .selI(selI),
    .selW(selW),
    .datain(dataout),
    .A(A),
    .B(B),
    .SP(SP),
    .Y(Y),
    .X(X),
    .BE(BE),
    .I(I));
decoderALU modDEC(
    .ins(ins),
    .pcin(pcin),
    .ramin(ramin),
    .Ain(A),
    .Bin(B),
    .selA(selA),
    .selB(selB),
    .Aout(Aout),
    .Bout(Bout),
    .op(op));
alu modALU(
    .op(op),
    .a(Aout),
    .b(Bout),
    .r(dataout),
    .f(f));
endmodule
//╔════════════════════════════════════════════════════════════════════════════════════════════════╗
//║								decodificador de operaciones									   ║
//╚════════════════════════════════════════════════════════════════════════════════════════════════╝
module decoderALU(
    input [31:0]ins,	// entrada de instrucciones
    input [31:0]pcin,	// entrada de programa actual(se usa en subrutinas)
    input [31:0]ramin,	// entrada de datos de la memoria
    input [31:0]Ain,	// entrada de datos de los GPR hacia el operando A
    input [31:0]Bin,	// entrada de datos de los GPR hacia el operando B
    output [3:0]selA,	// selector de registros para el operando A
    output [3:0]selB,	// selector de registros para el operando B
    output [31:0]Aout,	// salida del operando A hacia la ALU
    output [31:0]Bout,	// salida del operando B hacia la ALU
    output [3:0]op		// slaida de operaciones hacia la ALU
);
//______________________________ multiplexor de operaciones ______________________________
// señales de activacion
wire normalmode = ~( ins[31] ) ;
wire compmode = ( ins[31:27] == 5'b10100 ) ? 1'b1 : 1'b0 ;
// operaciones posibles
wire [3:0]normalop = ins[30:27] ;
wire [3:0]compop = 4'b1110 ;
wire [3:0]otherops = 4'b0000 ;
// asignacion de comandos hacia la ALU
assign op =	( normalmode == 1'b1 ) ? normalop :
                ( compmode == 1'b1  ) ? compop :
                otherops ;
//______________________________ multiplexor de operando A ______________________________
// señales de activacion
wire immediateinmov = ( ins[31:27] == 5'b10000 && ins[15] == 1'b1 ) ;
wire getprogramcount = ( ins[31:27] == 5'b10110 ) ;
wire getgprdata = ( ins[21:20] == 2'b00 && ins[31:27] != 5'b10010 ) ;
// posibles entradas para el operando A
wire [31:0]immdata = ins[14:0] ;
wire [31:0]pcdata = pcin ;
wire [31:0]gprdata = Ain ;
wire [31:0]ramdata = ramin ;
// asignacion del operando A
assign Aout = 	( immediateinmov == 1'b1 ) ? immdata :
                    ( getprogramcount == 1'b1 ) ? pcdata :
                    ( getgprdata == 1'b1 ) ? gprdata : 
                    ramdata;  
//______________________________ multiplexor de operando A ______________________________
wire getaoperand = ( ins[21:20] == 2'b10 ) ? 1'b1 : 1'b0 ;
wire getboperand = ( ins[15] == 0 ) ? 1'b1 : 1'b0 ;
// posibles entradas para el operando A
wire [31:0]aopdata = Ain ;
wire [31:0]bopdata = Bin ;
// asignacion del operando B
assign Bout = 	( getaoperand == 1'b1 ) ? Ain : 
                    ( getboperand == 1'b1 ) ? Bin 
                    : ins[14:0] ;
                    
assign selA = ( ins[31:27] != 5'b11000 ) ? ins[19:16] : ins[25:22] ;
assign selB =  ins[14:11] ;
endmodule 
//╔════════════════════════════════════════════════════════════════════════════════════════════════╗
//║								    decodificador de indices									   ║
//╚════════════════════════════════════════════════════════════════════════════════════════════════╝
module decoderINDEX(
    input [31:0]ins,	// entrada de instrucciones
    input [31:0]spin,	// entrada del stack pointer
    input [31:0]win,	// entrada del puntero de escritura
    input [31:0]rin,	// entrada del puntero de lectura
    input [31:0]iin,	// entrada del puntero indirecto
    input [31:0]bein,  // entrada de registro BIG ENDIAN
    output [31:0]addrw,	// salida de bus de localidades de escritura
    output [31:0]addrr,	// salida de bus de localidades de lectura
    output [3:0]seli,	// salida de selector de registro indirecto
    output [3:0]selw	// salida de selector de registro a escribir
);
// logica yse?ales para hacer offset
wire [31:0]offsetW;
wire [31:0]offsetR;
assign offsetW =        {{28{ins[25]}}, ins[25:22]} ;
assign offsetR =    	{{28{ins[19]}}, ins[19:16]} ;
//___________________________ multiplexor de indices de escritura ___________________________					
// señales de seleccion
wire wpush = ( ins[31:26] == 6'b100010 || ins[31:26] == 6'b101100 ) ? 1'b1 : 1'b0 ;
wire wmem = ( ins[26] == 1 ) ? 1'b1 : 1'b0 ;
wire wstr = ( ins[31:26] == 6'b110000 ) ? 1'b1 : 1'b0 ;
// multiplexor one hot
wire [3:0]wselector = { wpush, wmem, wstr, 1'b0 } ;
// direccionamiento de escritura
wire [31:0]push = spin + 1'b1 ;									// push y call
wire [31:0]memaddrw = win + offsetW ;							// escritura indexada
wire [31:0]straddrw = { bein[11:0], ins[19:0] } ;			// str con escritura directa
wire [31:0]donotw = 32'b0 ;										// escritura en registro
// asignacion de direccionamiento
assign addrw = ({32{wselector[3]}} & push ) |
                    ({32{wselector[2]}} & memaddrw ) |
                    ({32{wselector[1]}} & straddrw ) |
                    ({32{wselector[0]}} & donotw ) ;
//____________________________ multiplexor de indices de lectura ____________________________									
// señales de seleccion
wire rpull = ( ins[31:27] == 5'b10010 || ins[31:27] == 5'b10111 ) ? 1'b1 : 1'b0 ;
wire rdic = ( ins[21:20] == 2'b00 && !rpull ) ? 1'b1 : 1'b0 ;
wire rinx = ( ins[21:20] == 2'b01 && !rpull && ins[31:27] != 5'b10101 ) ? 1'b1 : 1'b0 ;
wire rext = ( ins[21:20] == 2'b10 && !rpull ) ? 1'b1 : 1'b0 ;
wire rind = ( ins[21:20] == 2'b11 && !rpull ) ? 1'b1 : 1'b0 ;
// multiplexor one hot
wire [4:0]rselector = { rpull, rdic, rinx, rext, rind } ;
// direccionamiento de lectura
wire [31:0]pull = spin ;									// instruccion PULL
wire [31:0]diraddrr = 32'b0 ;								// modo de lectura directa
wire [31:0]xaddrr = rin + offsetR ;						// modo de lecura indexada
wire [31:0]extaddrr = { bein[15:0], ins[15:0] } ;	// modo de lectura extendida
wire [31:0]indaddrr = iin ;								// modo de lectura indirecta
// asignacion de direccionamiento 
assign addrr = ({32{rselector[4]}} & pull ) |
                    ({32{rselector[3]}} & diraddrr ) |
                    ({32{rselector[2]}} & xaddrr ) |
                    ({32{rselector[1]}} & extaddrr ) |
                    ({32{rselector[0]}} & indaddrr ) ;
//__________________________________ multiplexor registros __________________________________
// logica de selectores de registros 
assign seli = 	( ins[31:26] == 6'b110000 ) ? ins[25:22] : ins[19:16] ;			// selector de registro indirecto
assign selw = ( ins[26] == 0 || ins[31:27] != 5'b10100 ) ? ins[25:22] : 4'b0;	// selector de registro para escribir 
endmodule	
//╔════════════════════════════════════════════════════════════════════════════════════════════════╗
//║								     decodificador de escritura									   ║
//╚════════════════════════════════════════════════════════════════════════════════════════════════╝
module remindercontrol(
    input miss,         // entrada handshake
    input [31:0]ins,	// instrucciones
    output gprwe,		// habilitador GPR
    output ramwe,		// habilitador RAM 
    output pushe,		// PUSH enabler
    output pulle		// PULL enabler
);
// se?al interna
wire [3:0]wetemp;
wire [3:0]we ;
// habilitacion de escritura para cuando termine la instruccion
assign wetemp = ( ins[31:27] == 5'b00000 ) ? 4'b0000 :
                ( ins[31:27] < 5'b10001 ) ? 
                    ( ins[26] == 1'b1 ) ? 4'b0100 : 
                        4'b1000 :
                ( ins[31:27] == 5'b10001 ) ? 4'b0110 :
                ( ins[31:27] == 5'b10010 ) ? 
                    ( ins[26] == 1'b1 ) ? 4'b0101 : 
                        4'b1001 :
                ( ins[31:27] == 5'b10110 ) ? 4'b0110 :
                ( ins[31:27] == 5'b10111 ) ? 4'b0001 :
                ( ins[31:27] == 5'b11000 ) ? 4'b0100 :
                4'b0000 ;
// salida del decodificador
assign we = wetemp & ~{4{miss}} ;
// habilitacion de escritura segun handshake
assign gprwe = we[3] ;
assign ramwe = we[2] ;
assign pushe = we[1] ;
assign pulle = we[0] ;		
endmodule 
//╔════════════════════════════════════════════════════════════════════════════════════════════════╗
//║								        registro de banderas									   ║
//╚════════════════════════════════════════════════════════════════════════════════════════════════╝
module flagcontrol(
    input clk,			// reloj maestro
    input [31:0]ins,	// instrucciones
    input [11:0]fin,	// entrada de banderas
    output [11:0]fout	// salida de banderas
);
// registro de almacenamiento de banderas de la anterior instruccion
reg [11:0]ftemp = 12'b0 ;
// guarda el dato de la bandera al finalizar instruccion CMP
always@( posedge clk )
begin
    if ( ins[31:27] == 5'b10100 )
        ftemp <= fin ;
    else
        ftemp <= 12'b0100_0000_0000 ;
end
// salida del modulo, depende de la instruccion 
assign fout = ftemp ;
endmodule
//╔════════════════════════════════════════════════════════════════════════════════════════════════╗
//║										registro de uso general									   ║
//╚════════════════════════════════════════════════════════════════════════════════════════════════╝
module gpr(
    input rst,			// reset maestro
    input clk,			// reloj maestro
    input we,			// habilitador de escritura
    input pushe,		// habilitador de escritura del stack pointer en PUSH
    input pulle,		// habilitador de escritura del stack pointer en PULL
    input [3:0]selA,	// direccion para leer en el operando A
    input [3:0]selB,	// direccion para leer en el operando B
    input [3:0]selW,	// direccion para escribir
    input [3:0]selI,	// direccion para leer localidades de la RAM
    input [31:0]datain,	// bus de entrada de datos
    output [31:0]A,		// bus de salida de datos al operando A
    output [31:0]B,		// bus de salida de datos al operando B
    output [31:0]SP,	// bus de salida de datos del stack pointer
    output [31:0]Y,		// bus de salida de registro apuntador de escritura
    output [31:0]X,		// bus de salida de registro apuntador de lectura
    output [31:0]BE,	// bus de salida de registro apuntador BIG ENDIAN
    output [31:0]I		// bus de salida de registro apuntador indirecto
);
// array de 16 registros de 32 bits cada uno
reg [31:0]gpr [15:0] ;
// logica para escribir
always@( posedge clk )
begin
    if (rst == 1) 
    begin
        gpr[0] <= 32'b0 ;
        gpr[1] <= 32'b0 ;
        gpr[2] <= 32'b0 ;
        gpr[3] <= 32'b0 ;
        gpr[4] <= 32'b0 ;
        gpr[5] <= 32'b0 ;
        gpr[6] <= 32'b0 ;
        gpr[7] <= 32'b0 ;
        gpr[8] <= 32'b0 ;
        gpr[9] <= 32'b0 ;
        gpr[10] <= 32'b0 ;
        gpr[11] <= 32'b0 ;
        gpr[12] <= 32'b0 ;
        gpr[13] <= 32'b0 ;
        gpr[14] <= 32'b0 ;
        gpr[15] <= 32'b0 ;
    end
    else
        if ( we == 1 )		// logica de escritura a cualquier registro
            gpr [selW] <= datain ;
        if ( pushe == 1'b1 && pulle == 1'b0 )	// aumenta el stack despues de PUSH
            gpr [0] <= gpr [0] + 1 ;
        if ( pushe == 1'b0 && pulle == 1'b1 )	// disminuye el stack despues de PULL
            gpr [0] <= gpr [0] - 1 ;
end
// logica de salida de datos asincrona
assign A = gpr[selA] ;
assign B = gpr[selB] ;
assign I = gpr[selI] ;
assign SP = gpr[0] ;
assign Y = gpr[1] ;
assign X = gpr[2] ;
assign BE = gpr[3] ;
endmodule   
//╔════════════════════════════════════════════════════════════════════════════════════════════════╗
//║								    unidad logica aritmetica									   ║
//╚════════════════════════════════════════════════════════════════════════════════════════════════╝
module alu(
    input [3:0]op,		// bus de entrada de las operaciones a realizar
    input [31:0]a,		// bus de entrada de el operando "a"
    input [31:0]b,		// bus de entrada de el operando "b"
    output [31:0]r,		// bus de salida de los resultados(es de 64 bits por la multiplicacion)
    output [11:0]f			// bus de salida de la banderas
);

// comportamiento de selectores ONE HOT
wire [15:0] onehot 	= 16'b1 << op ;
wire [3:0] shiftsel 	= ( b[3:0] == 4'b0000 ) ? 4'b0000 :
                              ( b[3:0] == 4'b0001 ) ? 4'b0001 :
                              ( b[3:0] == 4'b0010 ) ? 4'b0010 :
                              ( b[3:0] == 4'b0100 ) ? 4'b0100 :
                              ( b[3:0] == 4'b1000 ) ? 4'b1000 :
                              4'b0000 ;                  
// bypass
// _____________________________________________________________________
wire [31:0] bypass	= a  & {32{onehot[0]}} ;	
// shifters
// _____________________________________________________________________
wire [31:0] L1		= ( shiftsel == 4'b0000 ) ? a << 1 : 32'b0 ;
wire [31:0] L2		= ( a << 2 ) & {32{shiftsel[0]}} ;
wire [31:0] L4		= ( a << 4 ) & {32{shiftsel[1]}} ;
wire [31:0] L8		= ( a << 8 ) & {32{shiftsel[2]}} ;
wire [31:0] L16	= ( a << 16 ) & {32{shiftsel[3]}} ;
wire [31:0] R1		= ( shiftsel == 4'b0000 ) ? a >> 1 : 32'b0 ;
wire [31:0] R2		= ( a >> 2 ) & {32{shiftsel[0]}} ;
wire [31:0] R4		= ( a >> 4 ) & {32{shiftsel[1]}} ;
wire [31:0] R8		= ( a >> 8 ) & {32{shiftsel[2]}} ;
wire [31:0] R16	= ( a >> 16 ) & {32{shiftsel[3]}} ;
wire [31:0] Lshift 	= ( L1 | L2 | L4 | L8 | L16 ) & {32{onehot[1]}} ;
wire [31:0] Rshift 	= ( R1 | R2 | R4 | R8 | R16 ) & {32{onehot[2]}} ; 
// not
// _____________________________________________________________________
wire [31:0] neg 		= ( ~a ) & {32{onehot[3]}} ;
// complemento
// _____________________________________________________________________
wire [31:0] comp 		= ( ~a + 1 ) & {32{onehot[4]}} ;
// incremento
// _____________________________________________________________________
wire [31:0] inc		= ( a + 1 ) & {32{onehot[5]}} ;
// decremento
// _____________________________________________________________________
wire [31:0] dec		= ( a - 1 ) & {32{onehot[6]}} ;
// logica
// _____________________________________________________________________
wire [31:0] log1		= ( a | b ) & {32{onehot[7]}} ;
wire [31:0] log2		= ( a & b ) & {32{onehot[8]}} ;
wire [31:0] log3		= ( a ^ b ) & {32{onehot[9]}} ;
wire [31:0] log4		= ~( a | b ) & {32{onehot[10]}} ;
wire [31:0] log5		= ~( a & b ) & {32{onehot[11]}} ;
wire [31:0] log6		= ~( a ^ b ) & {32{onehot[12]}} ;
// aritmetica
// _____________________________________________________________________
wire [32:0] add = ( {1'b0, a} + {1'b0, b} ) & {33{onehot[13]}} ;
wire [32:0] sub = ( {1'b0, a} - {1'b0, b} ) & {33{onehot[14]}} ;
wire carry = 	(op == 4'b1101) ? add [32] :
                    (op == 4'b1110) ? sub [32] :
                    1'b0 ;
wire [31:0] mul = ( a[15:0] * b[15:0] ) & {32{onehot[15]}} ;
// resultado final
// decremento
// _____________________________________________________________________
assign r = 	bypass | Lshift | Rshift | neg | comp | inc | dec | log1 | log2 | log3 | log4 | log5 | log6 | add | sub | mul ;           
// comportamiento de las banderas de la alu				
assign f[0] = 	carry ;																		//carry									
assign f[1] = 	~(|r);																		// zero
assign f[2] =	r[31];																      // negative
assign f[3]	=	(op == 4'b1101) ? (a[31] == b[31] && r[31] != a[31]) :     	                // overflow
                    (op == 4'b1110) ? (a[31] != b[31] && r[31] != a[31]) : 0;
assign f[4] =	f[1] ;																		// b = a
assign f[5] =	~f[1] ;																		// b != a
assign f[6] =	f[0] & ~f[1];																// b < a
assign f[7] =	f[0] | f[1];																// b <= a
assign f[8] =	~f[0]	& ~f[1];																// b > a
assign f[9] =	~f[0] | f[1];																// b >= a  
assign f[10] =	1'b1 ;
assign f[11] =	1'b0 ;
endmodule 