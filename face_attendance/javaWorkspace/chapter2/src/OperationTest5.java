public class OperationTest5 {
    public static void main(String[] args){
        int var_inc = 1;
        int var_dec = 1;
        int result = 0;

        result = var_inc++;
        System.out.println("Result: " + result);
        System.out.println("var_inc: " + var_inc);

        result = ++var_inc;
        System.out.println("result: " + result);
        System.out.println("var_inc: " + var_inc);
        result = var_dec--;
        System.out.println("result: " + result);
        System.out.println("var_dec: " + var_dec);
        result = --var_dec;
        System.out.println("result: " + result);
        System.out.println("var_dec: " + var_dec);

    }
}