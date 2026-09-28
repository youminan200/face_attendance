
public class ConversionTest {

    public static void main(String[] args) {
        byte var_byte1 = 10;
        int var_int1 = var_byte1;
        System.out.println("var_int1 =" + var_int1);

        int var_int2 = 100;
        byte var_byte2 = (byte) var_int2;

        short var_short1 = 200;
        char var_char1 = (char) var_short1;
        System.out.println("var_char1 = " + var_char1);

        byte var_byte3 = 20;
        byte var_byte4 = 40;
        byte var_result1 = (byte) (var_byte3 + var_byte4);

        char var_char2 = 'A';
        int var_int_result1 = var_char2 + 1;
        System.out.println("var_int_result1 = " + var_int_result1);

        int var_int3 = 100;
        long var_long1 = 100;
        long var_long_result1 = var_int3 + var_long1;
        System.out.println("var_long_result1 =" + var_long_result1);

        long var_long2 = 100;
        float var_float1 = 3.14f;
        float var_float_result1 = var_long2 + var_float1;
        System.out.println("var_float_result1 = " + var_float_result1);

        float var_float2 = 3.33f;
        double var_double3 = 4.22;
        double var_long_result2 = var_float2 + var_double3;
        System.out.println("var_long_result2 = " + var_long_result2);

    }
}
