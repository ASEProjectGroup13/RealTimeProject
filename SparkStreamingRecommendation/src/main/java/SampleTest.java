import java.io.*;

/**
 * Created by Venu on 12/7/15.
 */
public class SampleTest {

    public static void main(String args[]){
        System.out.println("hello how are you");

        try {

            File fin = new File("music/artist_dat.txt");
            FileInputStream fis = new FileInputStream(fin);
            BufferedReader in = new BufferedReader(new InputStreamReader(fis));

            FileWriter fstream = new FileWriter("userartistplay1.csv", true);
            BufferedWriter out = new BufferedWriter(fstream);

            String aLine = null;
            while ((aLine = in.readLine()) != null) {
                //Process each line and add output to Dest.txt file

                String words[]=aLine.split("::");

                int values = 0;

                boolean status = true;

                try{

                    values = Integer.parseInt(words[0]);

                }catch (NumberFormatException ne){

                    status = false;

                    System.out.println("printingnumber format");

                }
                if(status && (words.length == 2)){

                    System.out.println(words.length);
                    out.write(aLine.toString());
                    out.newLine();
                }
            }

            // do not forget to close the buffer reader
            in.close();

            // close buffer writer
            out.close();

        } catch (IOException e) {
            e.printStackTrace();
        }


    }
}
