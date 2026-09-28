public class OperationTest7 {
    public static void main(String[] args) {
        int x = 3;
        int result = 0;
        result = x << 2;
        System.out.println("x << 2 = " + result); // 수정됨
        x = -1;
        result = x >> 2;
        System.out.println("x >> 2 = " + result); // 수정됨 (원래 코드의 >> 1을 >> 2로 수정함)
        result = x >>> 1;
        System.out.println("x >>> 1 = " + result); // 수정됨
    }
}
