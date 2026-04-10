package Analisis;

public class Token {

    // variables privadas
    private String valor;       // texto a identificar
    private Tipos tipo;         // tipo identificado
    public String getValor() { return valor; }
    public void setValor(String valor) { this.valor = valor; }
    public Tipos getTipo() { return tipo; }
    public void setTipo(Tipos tipo) { this.tipo = tipo; }

    // variable tipo enum para expresiones regulares
    public enum Tipos {
        INSTRUCCION1    ( "(?i)^(NOP|HALT|RET)$" ),
        INSTRUCCION2    ( "(?i)^(PUSH|PULL|CALL)$" ),
        INSTRUCCION3    ( "(?i)^(MOV|CMP|JMP|INC|DEC|NOT|COMP|STR)$" ),
        INSTRUCCION4    ( "(?i)^(LSFT|RSFT|ADD|SUB|MUL|OR|AND|XOR|NOR|NAND|XNOR)$" ),
        BANDERAS        ( "(?i)^(C|Z|N|V|BEA|BNEA|BSA|BSEA|BGA|BGEA|NEV|ALW|SYS[0-3]|USR[0-9]{2})$" ), 
        DESTINOLOCD     ( "(?i)(ASD[0-9]+)" ),
        DESTINOLOCX     ( "[Aa][Ss][Xx][0-9A-Fa-f]{5}" ),
        DESTINOLOCB     ( "[As][Ss][Bb][0-1]{20}" ),
        DESTINOMEMORIA  ( "(?i)(MS[+-][0-9]+)" ),                                           // destino en memoria + offset
        DESTINOREGISTRO ( "[Rr][Ss][0-9]+"),                                                // destino en registros
        INDIRECT        ( "[Rr][Ii][0-9]+"),                                                // registro indirecto
        MEMD            ( "[Mm][Mm][Dd][0-9]+"),                                            // referencia a memoria directa
        MEMX            ( "[Mm][Mm][Xx][0-9A-Fa-f]{4}"),                                    // referencia a memoria directa
        MEMB            ( "[Mm][Mm][Bb][0-1]{16}"),                                         // referencia a memoria directa
        INDEX           ( "[Rr][Xx][+-][0-9]+"),                                            // referencia a memoria indexada + offset
        DIRECT          ( "[Rr][Dd][0-9]+"),                                                // registro A y B
        IMMEDIATED      ( "[Ii][Mm][Dd][0-9]+"),                                            // datos inmediatos
        IMMEDIATEX      ( "[Ii][Mm][Xx][0-7][0-9A-Fa-f]{3}"),                               // datos inmediatos
        IMMEDIATEB      ( "[Ii][Mm][Bb][0-1]{15}+"),                                        // datos inmediatos
        SHIFT           ( "[<>][<>][0-9]"),                                                 // numero de desplazamientos
	TAG		( "[A-Za-z0-9][:]");                                                // tags
        
        public final String patron;
        // constructor de tipos
        Tipos ( String s ){
            this.patron = s ;
        }
    }
}














