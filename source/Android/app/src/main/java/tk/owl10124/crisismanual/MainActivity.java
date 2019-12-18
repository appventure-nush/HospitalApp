package tk.owl10124.crisismanual;

import android.graphics.Typeface;
import android.os.Bundle;
import android.support.constraint.ConstraintLayout;
import android.support.design.widget.FloatingActionButton;
import android.support.design.widget.NavigationView;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.CardView;
import android.support.v7.widget.Toolbar;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.style.BackgroundColorSpan;
import android.text.style.ForegroundColorSpan;
import android.text.style.LineHeightSpan;
import android.text.style.RelativeSizeSpan;
import android.text.style.StyleSpan;
import android.text.style.SubscriptSpan;
import android.text.style.SuperscriptSpan;
import android.text.style.TypefaceSpan;
import android.transition.TransitionManager;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.Scanner;


public class MainActivity extends AppCompatActivity {
    private NavigationView navigationView;
    private ConstraintLayout root;
    private LinearLayout container;
    private FloatingActionButton zoomIn;
    private FloatingActionButton zoomOut;
    private ArrayList<String> headers = new ArrayList<>();
    private ArrayList<ArrayList<SpannableStringBuilder>> subHeaders = new ArrayList<>();
    private ArrayList<ArrayList<SpannableStringBuilder>> content = new ArrayList<>();
    private ArrayList<Integer> toggled = new ArrayList<>();
    private int size = 20;
    private float weight = 50f;
    private int menuWidth = 840;
    private int ind;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        container = findViewById(R.id.container);
        navigationView = findViewById(R.id.navigationView);
        root = findViewById(R.id.root);
        zoomIn = findViewById(R.id.zoomInButton);
        zoomOut = findViewById(R.id.zoomOutButton);

        findViewById(R.id.scrollView).setOnScrollChangeListener((v,x,y,ox,oy)->{
            if (y-oy>20&&zoomIn.isOrWillBeShown()) {
                zoomIn.hide(); zoomOut.hide();
            } else if (oy-y>20&&zoomIn.isOrWillBeHidden()) {
                zoomIn.show(); zoomOut.show();
            }
        });

        findViewById(R.id.zoomInButton).setOnClickListener(e->{
            if (size<36) size+=2;
            loadPage(ind);
        });

        findViewById(R.id.zoomOutButton).setOnClickListener(e->{
            if (size>10) size-=2;
            loadPage(ind);
        });

        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setHomeAsUpIndicator(R.drawable.ic_menu);

        loadManual();
        loadPage(0);
    }

    public void toggleCard(View linearLayout, int j) {
        CardView currentCard = (CardView)((LinearLayout)linearLayout).getChildAt(1);
        TransitionManager.beginDelayedTransition(container);
        if (currentCard.getVisibility()==View.VISIBLE) {
            currentCard.setVisibility(View.GONE);
            toggled.set(ind,toggled.get(ind)|(1<<j));
        } else {
            currentCard.setVisibility(View.VISIBLE);
            toggled.set(ind,toggled.get(ind)&~(1<<j));
        }
    }

    public void addCard(SpannableStringBuilder header, SpannableStringBuilder content, int i, boolean expanded) {
        LinearLayout ll = new LinearLayout(getApplicationContext());
        ll.setLayoutParams(new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));
        ll.setOrientation(LinearLayout.VERTICAL);

        CardView ch = new CardView(getApplicationContext());
        ch.setRadius(0);
        ch.setCardBackgroundColor(getResources().getColor(container.getChildCount()%2==0?R.color.colorPrimary:R.color.colorPrimaryLess));
        ch.setCardElevation(8);
        ll.addView(ch);

        TextView h = new TextView(getApplicationContext());
        h.setTextColor(getResources().getColor(R.color.colorText));
        CardView.LayoutParams lp = new CardView.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
        lp.setMargins(2*size, 2*size, 2*size, 2*size);
        h.setLayoutParams(lp);
        ch.addView(h);
        h.setTextSize(1.4f*size);
        h.setText(header);

        if (content.length()>0) {
            ll.setOnClickListener(e->toggleCard(ll,i));

            CardView cc = new CardView(getApplicationContext());
            cc.setRadius(0);
            cc.setCardBackgroundColor(getColor(container.getChildCount() % 2 == 0 ? R.color.colorPrimaryLight : R.color.colorPrimaryLightLess));
            cc.setCardElevation(4);
            if (!expanded) cc.setVisibility(View.GONE);
            ll.addView(cc);

            TextView c = new TextView(getApplicationContext());
            c.setTextColor(getResources().getColor(R.color.colorText));
            lp = new CardView.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
            lp.setMargins(2*size, 2*size, 2*size, 2*size);
            c.setLayoutParams(lp);
            //c.setLineHeight(Math.round(3*size));
            c.setTextSize(size);
            cc.addView(c);
            c.setText(content);
        }

        container.addView(ll);
    }

    public void toggleToolbar() {
        TransitionManager.beginDelayedTransition(root);
        ViewGroup.LayoutParams lp = navigationView.getLayoutParams();
        lp.width=(lp.width==0?menuWidth:0);
        navigationView.setLayoutParams(lp);
    }

    public void addItem(String title) {
        navigationView.getMenu().add(title);
    }

    public void loadManual() {
        Scanner info = new Scanner(getResources().openRawResource(R.raw.info));
        info.useDelimiter("\n\n");
        int i=-1, j=-1;
        SpannableStringBuilder s = new SpannableStringBuilder("");
        while (info.hasNext()) {
            String str = info.next();
            if (str.startsWith("# ")) {
                ++i;
                headers.add(str.substring(2));
                toggled.add(0);
                subHeaders.add(new ArrayList<>());
                content.add(new ArrayList<>());
                navigationView.getMenu().add(str.substring(2));
                int finalI=i;
                navigationView.getMenu().getItem(i).setOnMenuItemClickListener(e->{toggleToolbar();loadPage(finalI);return true;});
                j=-1;
            } else if (str.startsWith("## ")) {
                ++j;
                subHeaders.get(i).add(parse(str));
                content.get(i).add(new SpannableStringBuilder());
            } else {
                content.get(i).get(j).append(parse(str));
            }
        }
    }

    public boolean loadPage(int i) {
        ind=i;
        getSupportActionBar().setTitle(headers.get(i));
        container.removeAllViews();
        for (int j=0;j<subHeaders.get(i).size();j++) {
            addCard(subHeaders.get(i).get(j),content.get(i).get(j),j,(toggled.get(i)&(1<<j))==0);
        }
        return true;
    }

    public SpannableStringBuilder parse(String s) {
        SpannableStringBuilder span = new SpannableStringBuilder();
        String[] a = s.split("\n");
        int bold=-1, italic=-1, sub=-1, sup=-1;
        for (String str: a) {
            int st = span.length();
            String original = str;
            if (str.startsWith("#")) {
                str=str.substring(str.indexOf(' ')+1);
            }
            for (int i=0;i<str.length();i++) {
                char c = str.charAt(i);
                if (c=='*')
                    if (i+1<str.length()&&str.charAt(i+1)=='*') {
                        if (bold==-1) bold=span.length();
                        else {
                            span.setSpan(new StyleSpan(Typeface.BOLD),bold,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                            span.setSpan(new ForegroundColorSpan(ContextCompat.getColor(getApplicationContext(),R.color.colorAccent)),bold,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                            bold=-1;
                        }
                        i++;
                    } else {
                        if (italic==-1) italic=span.length();
                        else {
                            span.setSpan(new StyleSpan(Typeface.ITALIC),italic,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                            italic=-1;
                        }
                    }
                else if (c=='{') {
                    int e = str.indexOf('}',i);
                    float x = Float.parseFloat(str.substring(i+1,e));
                    int k = span.length();
                    span.append(x+"/kg");//x*weight+"");
                    //span.setSpan(new TypefaceSpan(Typeface.MONOSPACE),k,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                    span.setSpan(new StyleSpan(Typeface.BOLD),k,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                    span.setSpan(new ForegroundColorSpan(ContextCompat.getColor(getApplicationContext(),R.color.colorAccent)),k,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                    span.setSpan(new BackgroundColorSpan(ContextCompat.getColor(getApplicationContext(),R.color.colorTranslucent)),k,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                    i=e;
                }
                else if (i+5<=str.length()&&str.substring(i,i+5).equals("<sub>")) {
                    sub=span.length();
                    i+=4;
                } else if (i+6<=str.length()&&str.substring(i,i+6).equals("</sub>")) {
                    if (sub!=-1) {
                        span.setSpan(new SubscriptSpan(),sub,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                        span.setSpan(new RelativeSizeSpan(0.8f),sub,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                    }
                    sub=-1;
                    i+=5;
                }
                else if (i+5<=str.length()&&str.substring(i,i+5).equals("<sup>")) {
                    sup=span.length();
                    i+=4;
                } else if (i+6<=str.length()&&str.substring(i,i+6).equals("</sup>")) {
                    if (sup!=-1) {
                        span.setSpan(new SuperscriptSpan(),sup,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                        span.setSpan(new RelativeSizeSpan(0.8f),sup,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                    }
                    sup=-1;
                    i+=5;
                } else span.append(c);
            }
            if (original.startsWith("### ")) {
                span.setSpan(new StyleSpan(Typeface.BOLD), st, span.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                span.setSpan(new RelativeSizeSpan(1.4f), st, span.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                //span.setSpan(new LineHeightSpan.Standard(4*size), st, span.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            } else if (original.startsWith("#### ")) {
                span.setSpan(new StyleSpan(Typeface.ITALIC), st, span.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                span.setSpan(new RelativeSizeSpan(1.2f), st, span.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                //span.setSpan(new LineHeightSpan.Standard(4*size), st, span.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
            if (!(original.startsWith("#")&&original.indexOf(' ')<3)) {
                span.append("\n\n");
                span.setSpan(new RelativeSizeSpan(0.2f),span.length()-2,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
        }
        return span;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                toggleToolbar();
        }
        return true;
    }
}
