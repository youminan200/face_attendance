public class FlowTest3 {
    


    public static void main(String[] args) {
        int year = Integer.parseInt(args[0]);
        boolean leapYear = false;
        leapYear = (year %4 == 0 && year % 100 != 0 || year % 400 == 0);
        if(leapYear){
            System.out.println(year + "은 윤년입니다.");
        } else {
            System.out.println(year + "은 윤년이 아닙니다.");
        }
    }
}
