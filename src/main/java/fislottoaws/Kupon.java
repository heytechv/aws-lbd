package fislottoaws;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class Kupon {

    private List<Integer> liczbyList = new ArrayList<>();

    public Kupon(List<Integer> liczbyList) {
//        this.liczbyList.addAll(Arrays.asList(liczby));
        this.liczbyList = liczbyList;
    }

    public List<Integer> getLiczbyList() { return liczbyList; }
    public void addLiczba(Integer liczba) { this.liczbyList.add(liczba); }

    @Override public String toString() {
        StringBuilder sb = new StringBuilder("|\t");
        for (int l : liczbyList)
            sb.append(l).append("\t|\t");
        return sb.toString();
    }
}
