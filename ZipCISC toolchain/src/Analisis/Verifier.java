package Analisis;

import java.util.ArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Verifier {
    
    public static boolean Semantica ( ArrayList<Token> linea ) {
        ArrayList<String> valores = new ArrayList<>() ;
        ArrayList<String> tipos = new ArrayList<>() ;
        // almacena el valor y el tipo en sus respectivas listas
        for ( Token token : linea ) {
            valores.add(token.getValor());
            tipos.add(token.getTipo().name());
        }
        
        int tamaño = valores.size();
        boolean ok = false ;
        
        switch (tamaño){
            case 1 -> {
                ok = true;
            }
            
            case 2 -> {
                if ("PUSH".equalsIgnoreCase(valores.get(0)) &&
                    (
                    "INDIRECT".equals(tipos.get(1)) ||
                    "MEMD".equals(tipos.get(1)) ||
                    "MEMX".equals(tipos.get(1)) ||
                    "MEMB".equals(tipos.get(1)) ||
                    "INDEX".equals(tipos.get(1)) ||           
                    "DIRECT".equals(tipos.get(1))          
                    )
                ) ok = true ;
                if ("PULL".equalsIgnoreCase(valores.get(0)) &&
                    (
                    "DESTINOMEMORIA".equals(tipos.get(1)) ||
                    "DESTINOREGISTRO".equals(tipos.get(1))
                    )
                ) ok = true ;
                if ("CALL".equalsIgnoreCase(valores.get(0)) &&
                    (
                    "TAG".equals(tipos.get(1))
                    )
                ) ok = true ;    
            }
            
            case 3 -> {  
                if ("MOV".equalsIgnoreCase(valores.get(0)) &&
                    (
                    "DESTINOMEMORIA".equals(tipos.get(1)) ||
                    "DESTINOREGISTRO".equals(tipos.get(1))
                    ) &&
                    (
                    "INDIRECT".equals(tipos.get(2)) ||
                    "MEMD".equals(tipos.get(2)) ||
                    "MEMX".equals(tipos.get(2)) ||
                    "MEMB".equals(tipos.get(2)) ||
                    "INDEX".equals(tipos.get(2)) ||           
                    "DIRECT".equals(tipos.get(2)) ||          
                    "IMMEDIATED".equals(tipos.get(2)) ||
                    "IMMEDIATEX".equals(tipos.get(2)) ||
                    "IMMEDIATEB".equals(tipos.get(2))  
                    )
                ) ok = true ;
                if ("CMP".equalsIgnoreCase(valores.get(0)) &&
                    (
                    "INDIRECT".equals(tipos.get(1)) ||
                    "MEMD".equals(tipos.get(1)) ||
                    "MEMX".equals(tipos.get(1)) ||
                    "MEMB".equals(tipos.get(1)) ||
                    "INDEX".equals(tipos.get(1)) ||           
                    "DIRECT".equals(tipos.get(1))
                    ) &&
                    (          
                    "DIRECT".equals(tipos.get(2)) ||          
                    "IMMEDIATED".equals(tipos.get(2)) ||
                    "IMMEDIATEX".equals(tipos.get(2)) ||
                    "IMMEDIATEB".equals(tipos.get(2)) 
                    )
                ) ok = true ;
                if ("JMP".equalsIgnoreCase(valores.get(0)) &&
                    "BANDERAS".equals(tipos.get(1)) &&       
                    "TAG".equals(tipos.get(2))
                ) ok = true ;
                if ((
                    "INC".equalsIgnoreCase(valores.get(0)) ||
                    "DEC".equalsIgnoreCase(valores.get(0)) || 
                    "NOT".equalsIgnoreCase(valores.get(0)) || 
                    "COMP".equalsIgnoreCase(valores.get(0))
                    )&&
                    (
                    "DESTINOMEMORIA".equals(tipos.get(1)) ||
                    "DESTINOREGISTRO".equals(tipos.get(1))
                    ) &&
                    (
                    "INDIRECT".equals(tipos.get(2)) ||
                    "MEMD".equals(tipos.get(2)) ||
                    "MEMX".equals(tipos.get(2)) ||
                    "MEMB".equals(tipos.get(2)) ||
                    "INDEX".equals(tipos.get(2)) ||           
                    "DIRECT".equals(tipos.get(2)) ||          
                    "IMMEDIATED".equals(tipos.get(2)) ||
                    "IMMEDIATEX".equals(tipos.get(2)) ||
                    "IMMEDIATEB".equals(tipos.get(2)) 
                    )
                ) ok = true ;
                if ("STR".equalsIgnoreCase(valores.get(0)) &&
                    (
                    "DESTINOLOCD".equals(tipos.get(1)) ||
                    "DESTINOLOCX".equals(tipos.get(1)) ||
                    "DESTINOLOCB".equals(tipos.get(1))
                    ) &&
                    (        
                    "DIRECT".equals(tipos.get(2))
                    )    
                ) ok = true ;
            }
            
            case 4 -> {
                if (( 
                    "LSFT".equalsIgnoreCase(valores.get(0)) || 
                    "RSFT".equalsIgnoreCase(valores.get(0))
                    )&&
                    (
                    "DESTINOMEMORIA".equals(tipos.get(1)) ||
                    "DESTINOREGISTRO".equals(tipos.get(1))
                    ) &&
                    (
                    "INDIRECT".equals(tipos.get(2)) ||
                    "MEMD".equals(tipos.get(2)) ||
                    "MEMX".equals(tipos.get(2)) ||
                    "MEMB".equals(tipos.get(2)) ||
                    "INDEX".equals(tipos.get(2)) ||           
                    "DIRECT".equals(tipos.get(2))
                    ) &&
                    (
                    "SHIFT".equals(tipos.get(3))
                    ) 
                ) ok = true ;
                if (( 
                    "ADD".equalsIgnoreCase(valores.get(0)) ||
                    "SUB".equalsIgnoreCase(valores.get(0)) || 
                    "MUL".equalsIgnoreCase(valores.get(0)) || 
                    "OR".equalsIgnoreCase(valores.get(0)) ||
                    "AND".equalsIgnoreCase(valores.get(0)) || 
                    "XOR".equalsIgnoreCase(valores.get(0)) || 
                    "NOR".equalsIgnoreCase(valores.get(0)) ||
                    "NAND".equalsIgnoreCase(valores.get(0)) || 
                    "XNOR".equalsIgnoreCase(valores.get(0))
                    )&&
                    (
                    "DESTINOMEMORIA".equals(tipos.get(1)) ||
                    "DESTINOREGISTRO".equals(tipos.get(1))
                    ) &&
                    (
                    "INDIRECT".equals(tipos.get(2)) ||
                    "MEMD".equals(tipos.get(2)) ||
                    "MEMX".equals(tipos.get(2)) ||
                    "MEMB".equals(tipos.get(2)) ||
                    "INDEX".equals(tipos.get(2)) ||           
                    "DIRECT".equals(tipos.get(2))
                    ) &&
                    (
                    "DIRECT".equals(tipos.get(3)) ||          
                    "IMMEDIATED".equals(tipos.get(3)) ||
                    "IMMEDIATEX".equals(tipos.get(3)) ||
                    "IMMEDIATEB".equals(tipos.get(3))
                    ) 
                ) ok = true ;
            }
        } 
        return ok ;
    }
    
    
    // analiza que el numero no exeda el tamaño maximo
    public static boolean Numerica ( ArrayList<Token> linea ) {
        // booleano de retorno
        boolean ok = true ;
        for ( Token token : linea ){
            // crea un patron que encuentra el numero dentro de un token
            Pattern numeros = Pattern.compile("[0-9]+") ;
            Matcher numeroencontrado = numeros.matcher(token.getValor() ) ;
            // crea un patron que encuentra el signo dentro de un token
            Pattern signo = Pattern.compile("[+-]") ;
            Matcher signoencontrado = signo.matcher(token.getValor() ) ;
            
            // analisis de numero segun el tipo de token
            switch (token.getTipo().name()) {
                // verifica que se tenga offset entre -8 y +7
                case "DESTINOMEMORIA" , "INDEX" -> {
                    if ( numeroencontrado.find() && signoencontrado.find() ) {
                        int valor = Integer.parseInt( numeroencontrado.group() );
                        String signoStr = signoencontrado.group();

                        if ( ( "+".equals(signoStr) && valor < 8 ) || ( "-".equals(signoStr) && valor < 9 ) )
                            ok = true ;
                        else
                            return false ;
                    } else {
                        return false ;
                    }
                }
                // verifica que no se intente a acceder a un registro mayor a 15
                case "DESTINOREGISTRO" , "DIRECT" , "INDIRECT" -> {
                    if ( numeroencontrado.find() && Integer.parseInt(numeroencontrado.group()) < 16 )
                        ok = true ;
                    else
                        return false ; 
                }
              
                // verifica que no se intente apuntar a una direccion no alcanzable por la instruccion
                case "MEMD" -> {
                    if (numeroencontrado.find() && Integer.parseInt(numeroencontrado.group()) < 65536 )
                        ok = true ;
                    else
                        return false ;    
                } 
                
                // verifica que no se intente colocar un numero no alcanzable por la instruccion
                case "IMMEDIATED" -> {
                    if ( numeroencontrado.find() && Integer.parseInt(numeroencontrado.group()) < 32768 )
                        ok = true ;
                    else
                        return false ;
                }
                case "SHIFT" -> {
                    if ( numeroencontrado.find() )
                        switch ( Integer.parseInt(numeroencontrado.group()) ) {
                            case 0, 1, 2, 4, 8 -> ok = true ;
                            default -> { return false ; }
                        }
                }
                case "DESINTOLOCD" -> {
                    if (numeroencontrado.find() && Integer.parseInt(numeroencontrado.group()) < 1048575 )
                        ok = true ;
                    else
                        return false ;  
                }
                // todos los demas casos
                default -> {
                    ok = true ;
                }
            }
        }
        return ok ;
    }
}
