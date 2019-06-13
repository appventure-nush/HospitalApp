package tk.owl10124.crisismanual;

import android.animation.Animator;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.support.v7.widget.CardView;
import android.transition.TransitionManager;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;

public class MainActivity extends AppCompatActivity {
    private LinearLayout container;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        container = findViewById(R.id.container);
    }

    public void toggle(View linearLayout) {
        CardView currentCard = (CardView)((LinearLayout)linearLayout).getChildAt(1);
        TransitionManager.beginDelayedTransition(container);
        if (currentCard.getVisibility()==View.VISIBLE) {
            currentCard.setVisibility(View.INVISIBLE);
            currentCard.setVisibility(View.GONE);
        } else currentCard.setVisibility(View.VISIBLE);
    }
}
