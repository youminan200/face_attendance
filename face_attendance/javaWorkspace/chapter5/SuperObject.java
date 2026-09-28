
public class SuperObject {

    public void paint() {
        draw();
    }

    public void draw() {
        draw();
        System.out.println("SuperObject");
    }
}

class SubObject extends SuperObject {

    @Override
    public void paint() {
        super.draw();
    }

    @Override
    public void draw() {
        System.out.println("Sub Object");
    }
}

class Sample {

    public static void main(String[] args) {
        SuperObject b = new SubObject();
        b.paint();
    }
}
