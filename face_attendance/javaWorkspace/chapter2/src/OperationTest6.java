public class OperationTest6 {
    public static void main(String[] args){
        int x = 8;
        int y = 3;
        int result = 0;
        boolean bResult = false;

        result = x + y;
        System.out.println("x & y =" + result);
        bResult = true & false;
        System.out.println("true & false = " + bResult);

        result = x | y;
        System.out.println("x | y = " + result);
        bResult = true | false;
        System.out.println("true | false = " + bResult);

        result = x ^ y;
        System.out.println("x ^ y = " + result);
        bResult = true ^ false;
        System.out.println("true ^ false = " + bResult);
    }
    
}
