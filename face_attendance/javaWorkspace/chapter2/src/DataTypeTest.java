public class DataTypeTest {
    /**
     * @param args
     */

     public static void main(String[] args){
        //TODO Auto-generated method stub
        //boolean 
        boolean var_boolean = true;

        byte var_byte = 127;

        //byte
        short var_short = 32767;

        //char
        char var_char1 = 66;
        char var_char2 = 'A';
        char var_char3 = '\u0041';
        char var_char4 = '가';
        char var_char5 = '□';

        //int
        int var_int = 100000;
        int num0 = 011;
        int num0x = 0x12;
        int num0B = 0b0111;
        int binaryInt = 0b1111_0000_1010_0000;

        //long
        long var_long = 1000000;
        long positionNumber = 122_122_122L;

        //float
        float var_float = 3.14f;

        double var_double = 3.14;
        
        System.out.println("var_boolean:" + var_boolean);
         System.out.println("var_byte:" + var_byte);
         System.out.println("var_short:" + var_short);
         System.out.println("var_char1:" + var_char1);
         System.out.println("var_char2:" + var_char2);
         System.out.println("var_char3:" + var_char3);
         System.out.println("var_char4:" + var_char4);

         System.out.println("var_char5:" + var_char5);
         System.out.println("var_int:" + var_int);
         System.out.println("num0:" + num0);
         System.out.println("num0x = " + num0x);
         System.out.println("num0B = " + num0B);
         System.out.println("binaryInt = " + binaryInt);
         System.out.println("var_long:" + var_long);
         System.out.println("positionNumber:" + positionNumber);
         System.out.println("var_float = " + var_float);
         System.out.println("var_double = " + var_double);
      }
}
