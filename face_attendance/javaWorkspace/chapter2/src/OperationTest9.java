public class OperationTest9 {
        public static void main (String[] args){
            
            int num = Integer.parseInt(args[0]);
            String msg = (num % 2 ==0) ? "짝수" : "홀수";
            System.out.println(num + "은" + msg + "입니다.");
        }
        
}

