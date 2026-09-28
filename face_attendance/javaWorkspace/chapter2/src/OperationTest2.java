public class OperationTest2 {
    public static void main(String[] args) {
       int total = 0;
       int avg = 0;

       int  kor = Integer.parseInt(args[0]);
       int mat =  Integer.parseInt(args[1]);
       int eng = Integer.parseInt(args[2]);

       total = kor + mat + eng;
       avg = total / 3;

       System.out.println("total = " + total);
       System.out.println("avg = " + avg);
    }
}
