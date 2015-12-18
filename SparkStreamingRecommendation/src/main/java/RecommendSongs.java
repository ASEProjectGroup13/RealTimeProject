import java.io.File;
import java.util.Random;

/**
 * Created by Venu on 12/14/15.
 */
public class RecommendSongs {

    public String recommendSongs(String path){

        File playlistPath=  new File(path);


        File[] files =  playlistPath.listFiles();

        Random randomNumbers = new Random();

        int numbers[] = new int[5];

        for (int i = 0; i < 5; i++) {
            numbers[i]= randomNumbers.nextInt(5)+1;

            System.out.println("random numbers"+numbers[i]);
        }
        String songNames[] = new String[5];
        int i =0;
        while(i <numbers.length){
            songNames[i] = files[numbers[i]].toString().substring(files[numbers[i]].toString().lastIndexOf("/")+1);
            System.out.println("random songs"+songNames[i]);
            i++;
        }
        System.out.println("Printing names"+songNames);

        String outputString = new String();

        for (String song: songNames){
            outputString = outputString+"::"+song;
        }
        System.out.println("outputs"+outputString);
        return outputString;
    }
}
