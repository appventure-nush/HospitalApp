package tk.owl10124.crisismanual;

import android.content.Intent;
import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;

public class SplashActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash);
        findViewById(R.id.startBtn).setOnClickListener(e->launch());
    }

    public void launch() {
        startActivity(new Intent(this, MainActivity.class));
    }

}
