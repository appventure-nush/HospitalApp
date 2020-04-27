package tk.owl10124.crisismanual;

import android.content.Context;
import android.os.Bundle;
import android.transition.TransitionManager;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.MediaController;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.VideoView;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.constraintlayout.widget.ConstraintLayout;

public class MediaActivity extends AppCompatActivity {
    private ConstraintLayout root;
    private ActionBar actionBar;
    private Toolbar toolbar;
    private ListView listView;
    private View overlay;
    private RelativeLayout mediaHolder;
    private View media = null;

    private ArrayList<String> keys = new ArrayList<>();
    private HashMap<String,Integer> list = new HashMap<>();
    private static final int[] icons = {R.drawable.ic_movie,R.drawable.ic_image,R.drawable.ic_error};

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_media);

        root = findViewById(R.id.root);

        toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        actionBar = getSupportActionBar();
        assert(actionBar!=null);
        actionBar.setTitle("Media");
        actionBar.setDisplayHomeAsUpEnabled(true);
        System.out.println("help me\n");

        overlay = findViewById(R.id.overlay);
        mediaHolder = findViewById(R.id.videoHolder);
        listView = findViewById(R.id.listView);

        Field[] f = R.raw.class.getFields();
        for (Field i: f) {
            if (i.getName().startsWith("media_")) {
                try {
                    keys.add(i.getName());
                    list.put(i.getName(),i.getInt(i)); //I'm sorry this is stupid and inefficient. I'll use Firebase when I learn to use Firebase.
                } catch (IllegalAccessException e) {
                    e.printStackTrace();
                }
            }
        }
        listView.setAdapter(new MediaAdapter(this, R.layout.adapter_media, keys));

        listView.setOnItemClickListener((p,v,pos,id)->{
            if (pos>=0) showMedia(keys.get(pos));
        });

        overlay.setOnClickListener(x->hideMedia());

        if (getIntent()==null) return;
        Bundle x = getIntent().getExtras();
        if (x!=null) {
            showMedia(x.getString("link"));
        }
    }

    public int mediaType(String s) {
        s = s.substring(6);
        if (s.startsWith("video")) return 0;
        if (s.startsWith("image")) return 1;
        return 2;
    }

    public void showMedia(String m) {
        System.out.println(m);
        if (media!=null) return;
        int t = mediaType(m);
        if (t==0) showVideo(m);
        else if (t==1) showImage(m);
    }

    public void showImage(String m) {
        TransitionManager.beginDelayedTransition(root);
        overlay.setVisibility(View.VISIBLE);
        ImageView img = new ImageView(this);
        media = img;
        img.setImageResource(list.get(m));
        mediaHolder.addView(img);
    }

    public void showVideo(String m) {
        TransitionManager.beginDelayedTransition(root);
        overlay.setVisibility(View.VISIBLE);
        VideoView v = new VideoView(this);
        media = v;
        mediaHolder.addView(media);
        v.setVideoPath("android.resource://"+getPackageName()+"/raw/"+list.get(m));
        v.setKeepScreenOn(true);
        v.setId(R.id.video);
        v.setElevation(20*getResources().getDisplayMetrics().density);
        v.setLayoutParams(new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT));
        MediaController mc = new MediaController(this);
        v.setMediaController(mc);
        v.start();
        mc.show(0);
    }

    public void hideMedia() {
        if (media==null) return;
        TransitionManager.beginDelayedTransition(root);
        overlay.setVisibility(View.GONE);
        mediaHolder.removeAllViews();
        media = null;
    }

    @Override

    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            finish();
        }
        return true;
    }

    public static class MediaAdapter extends ArrayAdapter<String> {
        Context ctx;
        MediaAdapter(Context ctx, int res, List<String> list) {
            super(ctx,res,list);
            this.ctx = ctx;
        }
        @Override
        public View getView(int position, View v, ViewGroup parent) {
            if (v==null) v = (LayoutInflater.from(ctx)).inflate(R.layout.adapter_media,null);
            TextView t = v.findViewById(R.id.titleView);
            String s = getItem(position).substring(6);
            t.setText(s);
            ImageView img = v.findViewById(R.id.imageView);
            if (s.startsWith("video")) img.setImageResource(R.drawable.ic_movie);
            else if (s.startsWith("image")) img.setImageResource(R.drawable.ic_image);
            return v;
        }
    }
}
