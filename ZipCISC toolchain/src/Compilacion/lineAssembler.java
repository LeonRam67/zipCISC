package Compilacion; 

import Analisis.Token;
import java.util.ArrayList;
import java.util.HashMap;

/**
 *
 * @author dinero
 */
public class lineAssembler {
    
    private static final HashMap<String, Integer> tagList = new HashMap<>();
    private static String binarioInstruccion = null ;
    private static String binarioDestino = null ;
    private static String binarioModoA = null ;
    private static String binarioModoB = null ;
    private static String binarioOperandoA = null ;
    private static String binarioOperandoB = null ;
    private static String binarioSalto = null ;
    private static String binarioLocalidad = null ;
    
    
    
    
    // toma una linea y si es una tag, guarda la direccion en la que se encuentra
    public static void tagListConstructor (  ArrayList<Token> linea, int actual ) {
        ArrayList<String> valores = new ArrayList<>() ;
        ArrayList<String> tipos = new ArrayList<>() ;
        for ( Token token : linea ) {
            valores.add(token.getValor());
            tipos.add(token.getTipo().name());
        }
        if ( "TAG".equals(tipos.get(0)) ){
            tagList.put( valores.get(0), actual ) ;
        }
    }
    
    // toma una linea y ensambla el lenguaje maquina
    public static String lenguajeMaquina ( ArrayList<Token> linea, int actual ){
        limpiarCampos() ;
        ArrayList<String> valores = new ArrayList<>() ;
        ArrayList<String> tipos = new ArrayList<>() ;
        // almacena el valor y el tipo en sus respectivas listas
        
        
        String binarioFinal ;
        
        
        for ( Token token : linea ) {
            valores.add(token.getValor());
            tipos.add(token.getTipo().name());
        }

        switch ( valores.size() ){
            case 1 -> {
                switch ( valores.get(0).toUpperCase() ){
                    case "NOP" -> { binarioInstruccion = "00000" ; }
                    case "HALT" -> { binarioInstruccion = "10011" ; }
                    case "RET" -> { binarioInstruccion = "10111" ; }
                    default -> { binarioInstruccion = "00000" ; }
                } 
                binarioDestino = "00000" ;
                binarioModoA = "00" ;
                binarioOperandoA = "0000" ;
                binarioModoB = "0" ;
                binarioOperandoB = "000000000000000" ;
                binarioSalto = "" ;
                binarioLocalidad = "" ;
            } // fin del caso 1
            
            case 2 -> {
                
                switch ( valores.get(0).toUpperCase() ){
                    case "PUSH" -> { 
                        binarioInstruccion = "10001" ; 
                        binarioDestino = "00000" ;
                        binarioSalto = "" ;
                        binarioLocalidad = "" ;
                        operandoAAuto( tipos.get(1), valores.get(1) );
                    }
                    case "PULL" -> { 
                        binarioInstruccion = "10010" ; 
                        binarioDestino = numeroDestino( tipos.get(1), valores.get(1) ) ;
                        binarioModoA = "00" ;
                        binarioOperandoA = "0000" ;
                        binarioModoB = "0" ;
                        binarioOperandoB = "000000000000000" ;
                        binarioSalto = "" ;
                        binarioLocalidad = "" ;
                    }
                    case "CALL" -> { 
                        binarioInstruccion = "10110" ; 
                        binarioDestino = "00000" ;
                        binarioModoA = "" ;
                        binarioOperandoA = "" ;
                        binarioModoB = "" ;
                        binarioOperandoB = "" ;
                        binarioSalto = numeroDireccion ( actual, tagList.get(valores.get(1)), valores.get(0) ) ;
                        binarioLocalidad = "" ;
                    }
                    default -> { binarioInstruccion = "00000" ; }
                }
            } // fin del caso 2
            
            case 3 -> {
                switch ( valores.get(0).toUpperCase() ){
                    case "MOV" -> {
                        binarioInstruccion = "10000" ;
                        binarioDestino = numeroDestino( tipos.get(1), valores.get(1) ) ;
                        operandoAAuto( tipos.get(2), valores.get(2) ) ;
                        binarioSalto = "" ;
                        binarioLocalidad = "" ;
                    }
                    case "CMP" -> {
                        binarioInstruccion = "10100" ;
                        binarioDestino = "00000" ;
                        operandoAAuto( tipos.get(1), valores.get(1) ) ;
                        operandoBAuto( tipos.get(2), valores.get(2) ) ;
                        binarioSalto = "" ;
                        binarioLocalidad = "" ;
                    }
                    case "JMP" -> {
                        binarioInstruccion = "10101" ;
                        binarioDestino = numeroSalto( valores.get(1) ) ;
                        binarioModoA = "" ;
                        binarioOperandoA = "" ;
                        binarioModoB = "" ;
                        binarioOperandoB = "" ;
                        binarioSalto = numeroDireccion ( actual, tagList.get(valores.get(2)), tipos.get(0) ) ;
                        binarioLocalidad = "" ;
                    }
                    case "NOT" -> {
                        binarioInstruccion = "00011" ;
                        binarioDestino = numeroDestino( tipos.get(1), valores.get(1) ) ;
                        operandoAAuto( tipos.get(2), valores.get(2) ) ;
                        binarioSalto = "" ;
                        binarioLocalidad = "" ;
                    }
                    case "COMP" -> {
                        binarioInstruccion = "00100" ;
                        binarioDestino = numeroDestino( tipos.get(1), valores.get(1) ) ;
                        operandoAAuto( tipos.get(2), valores.get(2) ) ;
                        binarioSalto = "" ;
                        binarioLocalidad = "" ;
                    }
                    case "INC" -> {
                        binarioInstruccion = "00101" ;
                        binarioDestino = numeroDestino( tipos.get(1), valores.get(1) ) ;
                        operandoAAuto( tipos.get(2), valores.get(2) ) ;
                        binarioSalto = "" ;
                        binarioLocalidad = "" ;
                    }
                    case "DEC" -> {
                        binarioInstruccion = "00110" ;
                        binarioDestino = numeroDestino( tipos.get(1), valores.get(1) ) ;
                        operandoAAuto( tipos.get(2), valores.get(2) ) ;
                        binarioSalto = "" ;
                        binarioLocalidad = "" ;
                    }
                    case "STR" -> {
                        binarioInstruccion = "11000" ;
                        binarioModoA = "00" ;
                        binarioDestino = "0" + numeroRegistro ( valores.get(2) ) ;
                        binarioOperandoA = "" ;
                        binarioModoB = "" ;
                        binarioOperandoB = "" ;
                        binarioSalto = "" ;
                        binarioLocalidad = localidadInmediato ( tipos.get(1),  valores.get(1) ) ;
                    }
                    default -> { binarioInstruccion = "00000" ; }
                }
            } // fin del caso 3
            
            case 4 -> {
                if ( "LSFT".equals( valores.get(0).toUpperCase() ) ||  "RSFT".equals( valores.get(0).toUpperCase() ) ) {
                        binarioInstruccion = "00001" ;
                        binarioDestino = numeroDestino( tipos.get(1), valores.get(1) ) ;
                        operandoAAuto( tipos.get(2), valores.get(2) ) ;
                        binarioModoB = "1" ;
                        binarioOperandoB = "00000000000"  + numeroRegistro( valores.get(3) ) ;
                        binarioSalto = "" ;
                        binarioLocalidad = "" ;
                    
                }
                else {
                    
                    switch ( valores.get(0).toUpperCase() ) {
                        case "OR" -> { binarioInstruccion = "00111" ; }
                        case "AND" -> { binarioInstruccion = "01000" ; }
                        case "XOR" -> { binarioInstruccion = "01001" ; }
                        case "NOR" -> { binarioInstruccion = "01010" ; }
                        case "NAND" -> { binarioInstruccion = "01011" ; }
                        case "XNOR" -> { binarioInstruccion = "01100" ; }
                        case "ADD" -> { binarioInstruccion = "01101" ; }
                        case "SUB" -> { binarioInstruccion = "01110" ; }
                        case "MUL" -> { binarioInstruccion = "01111" ; }
                        default -> { binarioInstruccion = "00000" ; }
                    }
                    binarioDestino = numeroDestino( tipos.get(1), valores.get(1) ) ;
                    operandoAAuto( tipos.get(2), valores.get(2) ) ;
                    operandoBAuto( tipos.get(3), valores.get(3) ) ;
                    binarioSalto = "" ;
                    binarioLocalidad = "" ;
                }
                    
            } // fin del caso 4
        } // fin del switch de tamaño
        binarioFinal =  binarioInstruccion +
                        binarioDestino +
                        binarioModoA +
                        binarioOperandoA +
                        binarioModoB + 
                        binarioOperandoB +
                        binarioSalto +
                        binarioLocalidad ;
        return binarioFinal ;
    }
    
    private static void limpiarCampos() {
    binarioInstruccion = binarioDestino = binarioModoA = binarioModoB = 
    binarioOperandoA = binarioOperandoB = binarioSalto = "";
    }
    
    // metodo para convertir una direccion en binario
    private static String numeroExtendido (String tipo, String valor ){
        if ( null == tipo ) return null; else
        switch (tipo) {
            case "MEMD":
            {
                String numeroStr = valor.substring(3) ;
                int numero = Integer.parseInt(numeroStr) ;
                String numeroBinario = String.format( "%16s",Integer.toBinaryString(numero ) ).replace(' ', '0' ) ;
                return numeroBinario ;
            }
            case "MEMX":
            {
                String numeroStr = valor.substring(3) ;
                int numero = Integer.parseInt( numeroStr, 16 ) ;
                String numeroBinario = String.format( "%16s",Integer.toBinaryString (numero ) ).replace(' ', '0' ) ;
                return numeroBinario ;
            }
            case "MEMB":
            {
                String numeroStr = valor.substring(3) ;
                return numeroStr ;
            }
            default:
                return "";
        }
    }
    // metodo para convertir un registro en binario
    private static String numeroRegistro ( String valor ) {
        
        String numeroStr = valor.substring(2) ;
        int numero = Integer.parseInt( numeroStr ) ;
        return String.format( "%4s",Integer.toBinaryString ( numero ) ).replace(' ', '0' ) ;
    }
    // metodo para convertir un offset con signo en binario
    private static String numeroOffset ( String valor ) {
        String numeroStr = valor.substring(3) ;
        int numero = Integer.parseInt( numeroStr ) ;
        char signo = valor.charAt(2) ;
        if ( signo == '+' ){
            return String.format( "%4s",Integer.toBinaryString ( numero ) ).replace(' ', '0' ) ;
        }
        else {
            int complemento = ~numero ;
            complemento = complemento + 1 ;
            return String.format( "%4s",Integer.toBinaryString ( complemento & 0xF ) ).replace(' ', '0' ) ;
        }   
    }
    // generador de direcciones
    private static String numeroDestino ( String tipo, String valor ) {
        if ( "DESTINOMEMORIA".equals(tipo) )
            return "1" + numeroOffset( valor ) ;
        else
            return "0" + numeroRegistro( valor ) ;
    }
    // metodo para convertir una localidad en binario
    private static String localidadInmediato ( String tipo, String valor ){
        if ( null == tipo ) return null; else
        switch (tipo) {
            case "DESTINOLOCD":
            {
                String numeroStr = valor.substring(3) ;
                int numero = Integer.parseInt(numeroStr) ;
                String numeroBinario = String.format( "%20s",Integer.toBinaryString(numero ) ).replace(' ', '0' ) ;
                return numeroBinario ;
            }
            case "DESTINOLOCX":
            {
                String numeroStr = valor.substring(3) ;
                int numero = Integer.parseInt( numeroStr, 16 ) ;
                String numeroBinario = String.format( "%20s",Integer.toBinaryString (numero ) ).replace(' ', '0' ) ;
                return numeroBinario ;
            }
            case "DESTINOLOCB":
            {
                String numeroStr = valor.substring(3) ;
                return numeroStr ;
            }
            default:
                return "";
        }
    }
    // metodo para convertir un numero inmediato en binario
    private static String numeroInmediato ( String tipo, String valor ){
        if ( null == tipo ) return null; else
        switch (tipo) {
            case "IMMEDIATED":
            {
                String numeroStr = valor.substring(3) ;
                int numero = Integer.parseInt(numeroStr) ;
                String numeroBinario = String.format( "%15s",Integer.toBinaryString(numero ) ).replace(' ', '0' ) ;
                return numeroBinario ;
            }
            case "IMMEDIATEX":
            {
                String numeroStr = valor.substring(3) ;
                int numero = Integer.parseInt( numeroStr, 16 ) ;
                String numeroBinario = String.format( "%15s",Integer.toBinaryString (numero ) ).replace(' ', '0' ) ;
                return numeroBinario ;
            }
            case "IMMEDIATEB":
            {
                String numeroStr = valor.substring(3) ;
                return numeroStr ;
            }
            default:
                return "";
        }
    }
    // generador de saltos
    private static String numeroDireccion ( int actual, int tag, String valor ) {
        int complemento ;
        String binSalto ;
        if ( "CALL".equalsIgnoreCase(valor) ){
            
            binSalto = "00" + String.format( "%20s",Integer.toBinaryString ( tag ) ).replace(' ', '0' ) ;
        }
        else
            if ( tag > actual )
                binSalto = "01" + String.format( "%20s",Integer.toBinaryString ( tag - actual ) ).replace(' ', '0' ) ;
            else{
                complemento = ~ ( actual - tag ) ;
                binSalto = "01" + String.format( "%20s",Integer.toBinaryString ( ( complemento + 1 ) & ( 0xFFFFF ) ) ).replace(' ', '0' ) ;
            }    
        return binSalto ;
    }
    // generador de destinos
    private static String numeroSalto ( String valor ) {
        switch ( valor ) {
            case "C" -> { return "00000" ; }
            case "Z" -> { return "00001" ; }
            case "N" -> { return "00010" ; }
            case "V" -> { return "00011" ; }
            case "BEA" -> { return "00100" ; }
            case "BNEA" -> { return "00101" ; }
            case "BSA" -> { return "00110" ; }
            case "BSEA" -> { return "00111" ; }
            case "BGA" -> { return "01000" ; }
            case "BGEA" -> { return "01001" ; }
            case "ALW" -> { return "01010" ; }
            case "NEV" -> { return "01011" ; }
            case "SYS0" -> { return "01100" ; }
            case "SYS1" -> { return "01101" ; }
            case "SYS2" -> { return "01110" ; }
            case "SYS3" -> { return "01111" ; }
            case "USR0" -> { return "10000" ; }
            case "USR1" -> { return "10001" ; }
            case "USR2" -> { return "10010" ; }
            case "USR3" -> { return "10011" ; }
            case "USR4" -> { return "10100" ; }
            case "USR5" -> { return "10101" ; }
            case "USR6" -> { return "10110" ; }
            case "USR7" -> { return "10111" ; }
            case "USR8" -> { return "11000" ; }
            case "USR9" -> { return "11001" ; }
            case "USR10" -> { return "11010" ; }
            case "USR11" -> { return "11011" ; }
            case "USR12" -> { return "11100" ; }
            case "USR13" -> { return "11101" ; }
            case "USR14" -> { return "11110" ; }
            case "USR15" -> { return "11111" ; }
            default -> { return "00000" ; }
        }
    }
    
    // generador de operando A automatico
    private static void operandoAAuto ( String tipo, String valor ) {
        if ( null != tipo ) switch (tipo) {
            case "INDIRECT":
                binarioModoA = "11" ;
                binarioOperandoA = numeroRegistro( valor ) ;
                binarioModoB = "0" ;
                binarioOperandoB = "000000000000000" ;
                break ;
            case "MEMD":
            case "MEMX":
            case "MEMB":
                binarioModoA = "10" ;
                binarioOperandoA = "0000" ;
                binarioModoB = "" ;
                binarioOperandoB = numeroExtendido( tipo, valor ) ;
                break ;
            case "INDEX":
                binarioModoA = "01" ;
                binarioOperandoA = numeroOffset( valor ) ;
                binarioModoB = "0" ;
                binarioOperandoB = "000000000000000" ;
                break ;
            case "DIRECT": 
                binarioModoA = "00" ;
                binarioOperandoA = numeroRegistro( valor ) ;
                binarioModoB = "0" ;
                binarioOperandoB = "000000000000000" ;
                break ;
            case "IMMEDIATED":
            case "IMMEDIATEX":
            case "IMMEDIATEB":
                binarioModoA = "00" ;
                binarioOperandoA = "0000" ;
                binarioModoB = "1" ;
                binarioOperandoB = numeroInmediato( tipo, valor ) ;
                break ;
            default:
                break;
        }
    } 
    // generador de operando A automatico
    private static void operandoBAuto ( String tipo, String valor ) {
        if ( "10".equals(binarioModoA)){
            binarioOperandoA = numeroRegistro( valor ) ;
        }
        else
            if ( "DIRECT".equals(tipo) ){
                binarioModoB = "0" ;
                binarioOperandoB = numeroRegistro( valor ) + "00000000000" ;
                
            }
            else {
                binarioModoB = "1" ;
                binarioOperandoB = numeroInmediato( tipo, valor ) ;
            } 
    }  
}
