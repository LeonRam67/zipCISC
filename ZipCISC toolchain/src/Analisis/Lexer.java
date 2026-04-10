package Analisis;

import java.util.ArrayList;
import java.util.StringTokenizer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Lexer {
    // funcion que detecta los tokens
    public static ArrayList<Token> lex ( String entrada ) {
        final ArrayList<Token> tokens = new ArrayList ();               // crea lista dinamica de tokens
        final StringTokenizer st = new StringTokenizer ( entrada ) ;    // separa la linea de tokens
        
        // funcion de analizacion lexica
        while ( st.hasMoreTokens() ) {              // continua mientras falten tokens por analizar
            String palabra = st.nextToken () ;      // toma la primer palabra que falta por leer
            boolean banderas = false ;              // crea un bandera que indica si se enviaron datos validos
            
            // funcion de comparar la palabra individual actual (token) con un tipo
            for (Token.Tipos tokenTipo: Token.Tipos.values () ) {       // por cada tipo ejecuto el bloque hasta acabar con mis tipos
                Pattern patron = Pattern.compile( tokenTipo.patron ) ;  // crea una regla para comparar con mi token
                Matcher busqueda = patron.matcher( palabra ) ;          // crea un comparador entre la regla y el token actual
                
                if ( busqueda.find() ) {
                    Token token = new Token () ;    // instancia clase token
                    token.setTipo(tokenTipo) ;      // guarda el tipo que corresponde con mi token actual
                    token.setValor(palabra) ;       // gurada el contenido del token actual
                    tokens.add(token);              // guarda toda la clase en la lista creada al inicio
                    banderas = true ;               // marca que si hubo coincidencia alguna
                }
            }
            
            // si la bandera no cambio de 0 a uno, jamas hubo coincidencia
            if ( !banderas ) {
                throw new RuntimeException( "token: " + palabra +  " invalido" ); // excepcion en caso de fallo
            }
        }
        return tokens;
    }
}
