
package Compilacion;

import static Analisis.Lexer.lex;
import static Analisis.Parcer.Syntax;
import Analisis.Token;
import static Analisis.Verifier.Numerica;
import static Analisis.Verifier.Semantica;
import static Compilacion.lineAssembler.lenguajeMaquina;
import static Compilacion.lineAssembler.tagListConstructor;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import com.fazecast.jSerialComm.*;

public class textAssembler {
       
    
    
    
    // ensamblado y mostrado en la consola
    public static void compilarProgramar ( String puerto, int baudRate, String archivo, int start ) {   
        analizarTags ( archivo, start ) ;
        ensamblarEnviar ( puerto, baudRate, archivo, start ) ;
    }
    
    
    
    
    
    // primer pasada del analisis
    private static void analizarTags ( String archivo, int start ) {
        FileReader programa ;
        BufferedReader lector ;
        try {
            programa = new FileReader( archivo );
            if ( programa.ready()){
                lector = new BufferedReader( programa ) ;
                String linea ;
                int i = start ;
                while ( ( linea = lector.readLine() ) != null ){
                    System.out.println("LINEA: " + ( i - start )  );
                    ArrayList<Token> tokens = lex( linea ) ;
                    if ( Syntax(tokens) == true && Semantica(tokens) == true && Numerica(tokens) == true ) {
                        tagListConstructor ( tokens , i ) ;
                        i ++ ;
                    }
                }
            }
        } 
        catch ( IOException e ) {
            System.out.println("Error: " + e.getMessage() );
        } 
    }
    
    
    
    
    
    // segunda pasada del analisis
    private static void ensamblarEnviar ( String puerto, int baudRate, String archivo, int start ) {
        SerialPort comPort = SerialPort.getCommPort(puerto); // ajusta aquí
        comPort.setBaudRate(baudRate);
        comPort.openPort();
        byte[] begin ={ (byte)0xAA, (byte)0xAA, (byte)0x00, (byte)0x00, };
        byte[] end ={ (byte)0x55, (byte)0x55, (byte)0x00, (byte)0x00, };
        FileReader programa ;
        BufferedReader lector ;
        comPort.writeBytes(begin,begin.length);
        try {
            programa = new FileReader( archivo );
            if ( programa.ready()){
                lector = new BufferedReader( programa ) ;
                String linea ;
                int i = start ;
                while ( ( linea = lector.readLine() ) != null ){
                    ArrayList<Token> tokens = lex( linea ) ;
                    if ( Syntax(tokens) == true && Semantica(tokens) == true && Numerica(tokens) == true ) {
                        //System.out.println( ( i-start )+": "+ lenguajeMaquina ( tokens, i ) );
                        System.out.println( "       sendins(32'b"+ lenguajeMaquina ( tokens, i )+");" );
                        //System.out.println(lenguajeMaquina ( tokens, i ) );
                        comPort.writeBytes(
                            new byte[] {
                                (byte) Integer.parseInt( lenguajeMaquina( tokens, i ).substring(24, 32), 2),
                                (byte) Integer.parseInt( lenguajeMaquina( tokens, i ).substring(16, 24), 2),
                                (byte) Integer.parseInt( lenguajeMaquina( tokens, i ).substring(8, 16), 2),
                                (byte) Integer.parseInt( lenguajeMaquina( tokens, i ).substring(0, 8), 2)
                            },
                            4
                        );
                        i ++ ;
                    }
                }
            }
        } 
        catch ( IOException e ) {
            System.out.println("Error: " + e.getMessage() );
        }
        comPort.writeBytes(end,end.length);
    }
    
    
    
    
    
    
}
