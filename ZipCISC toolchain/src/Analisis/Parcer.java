package Analisis;

import java.util.ArrayList;

public class Parcer {

    public static boolean Syntax ( ArrayList<Token> linea ) {
        // la lista que almacena token se debe de separara en dos listas, una de valor, otra de tipo
        ArrayList<String> tipos = new ArrayList<>() ;   // lista de solo tipos
        
        // almacena el valor y el tipo en sus respectivas listas
        for ( Token token : linea ) {
            tipos.add(token.getTipo().name());
        }
        
        int tamaño = tipos.size();
        switch (tamaño){
            case 1 -> {
                if ( "INSTRUCCION1".equals(tipos.get(0)) || "TAG".equals(tipos.get(0))
                    ) return true ;
                else return false ;
            }
            
            case 2 -> {
                if ( "INSTRUCCION2".equals(tipos.get(0)) &&
                        (
                        "DESTINOMEMORIA".equals(tipos.get(1)) ||
                        "DESTINOREGISTRO".equals(tipos.get(1)) ||
                        "INDIRECT".equals(tipos.get(1)) ||        
                        "MEMD".equals(tipos.get(1)) ||
                        "MEMX".equals(tipos.get(1)) ||
                        "MEMB".equals(tipos.get(1)) ||
                        "INDEX".equals(tipos.get(1)) ||           
                        "DIRECT".equals(tipos.get(1)) ||          
                        "IMMEDIATED".equals(tipos.get(1)) ||
                        "IMMEDIATEX".equals(tipos.get(1)) ||
                        "IMMEDIATEB".equals(tipos.get(1)) ||
                        "TAG".equals(tipos.get(1))
                        )       
                    ) return true ;
                else return false ;
            }
            
            case 3 -> {
                if ( "INSTRUCCION3".equals(tipos.get(0)) &&   
                        (
                        "DESTINOLOCD".equals(tipos.get(1)) ||
                        "DESTINOLOCX".equals(tipos.get(1)) ||
                        "DESTINOLOCB".equals(tipos.get(1)) ||
                        "DESTINOMEMORIA".equals(tipos.get(1)) ||
                        "DESTINOREGISTRO".equals(tipos.get(1)) ||
                        "BANDERAS".equals(tipos.get(1)) ||
                        "INDIRECT".equals(tipos.get(1)) ||        
                        "MEMD".equals(tipos.get(1)) ||
                        "MEMX".equals(tipos.get(1)) ||
                        "MEMB".equals(tipos.get(1)) ||
                        "INDEX".equals(tipos.get(1)) ||           
                        "DIRECT".equals(tipos.get(1))
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
                        "IMMEDIATEB".equals(tipos.get(2)) ||
                        "TAG".equals(tipos.get(2))
                        )       
                    ) return true ;
                else return false ;        
            }
            
            case 4 -> {
                if ( "INSTRUCCION4".equals(tipos.get(0)) &&
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
                        "IMMEDIATEX".equals(tipos.get(2)) ||
                        "IMMEDIATEB".equals(tipos.get(2)) ||
                        "SHIFT".equals(tipos.get(3))
                        )
                    ) return true ;
                else return false ;
            }
            default ->{
                return false ;
            }
        } 
    }
}