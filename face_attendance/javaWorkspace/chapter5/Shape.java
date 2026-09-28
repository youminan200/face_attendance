public class Shape {
    public void draw(){
        System.out.println("Shape");
    }
}

class Line extends Shape {
    public void draw(){
        System.out.println("Line");
    }
}

class Rect extends Shape{
    public void draw(){
        System.out.println("Rect");
    }
}

class Circle extends Shape{
    public void draw(){
        System.out.println("Circle");
    }
}
class MethodOverridingEx{
    static void print(Shape p){
        p.draw();
    }
    public static void main(String[] args){
        print(new Shape());
        print(new Line());
        print(new Rect());
        print(new Circle());
    }   
}
