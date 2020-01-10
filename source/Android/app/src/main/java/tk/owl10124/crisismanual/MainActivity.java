package tk.owl10124.crisismanual;

import android.content.Context;
import android.graphics.Typeface;
import android.os.Bundle;
import android.text.Spannable;
import android.text.SpannableString;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.style.BackgroundColorSpan;
import android.text.style.BulletSpan;
import android.text.style.ForegroundColorSpan;
import android.text.style.LeadingMarginSpan;
import android.text.style.RelativeSizeSpan;
import android.text.style.StyleSpan;
import android.text.style.SubscriptSpan;
import android.text.style.SuperscriptSpan;
import android.transition.TransitionManager;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.google.android.material.navigation.NavigationView;

import java.util.ArrayList;
import java.util.Scanner;

import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.cardview.widget.CardView;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.DialogFragment;


public class MainActivity extends AppCompatActivity implements WeightDialogFragment.WeightDialogListener {
    private NavigationView menu;
    private NavigationView optionsMenu;
    private Toolbar menuBar;
    private Toolbar toolbar;
    private ConstraintLayout root;
    private LinearLayout container;
    private LinearLayout navigationView;
    private LinearLayout modal;
    private FloatingActionButton zoomIn;
    private FloatingActionButton zoomOut;
    private FloatingActionButton menuBtn;
    private ScrollView scrollView;
    private View overlay;
    private EditText searchText;
    private ArrayList<String> headers = new ArrayList<>();
    private ArrayList<ArrayList<String>> subHeaders = new ArrayList<>();
    private ArrayList<ArrayList<ArrayList<String>>> content = new ArrayList<>();
    private int size = 14;
    public static float weight = 50f;
    public static boolean calculateByWeight = false;
    private int ind=-1, view=0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        container = findViewById(R.id.container);
        modal = findViewById(R.id.modal);
        navigationView = findViewById(R.id.navigationView);
        menu = findViewById(R.id.menu);
        menuBar = findViewById(R.id.menuBar);
        toolbar = findViewById(R.id.toolbar);
        optionsMenu = findViewById(R.id.optionsMenu);
        root = findViewById(R.id.root);
        zoomIn = findViewById(R.id.zoomInBtn);
        zoomOut = findViewById(R.id.zoomOutBtn);
        menuBtn = findViewById(R.id.menuBtn);
        scrollView = findViewById(R.id.scrollView);
        overlay = findViewById(R.id.overlay);
        searchText = findViewById(R.id.searchText);

        scrollView.setOnScrollChangeListener((v,x,y,ox,oy)->{
            if (y-oy>20&&zoomIn.isOrWillBeShown()) hideButtons();
            else if (oy-y>20&&zoomIn.isOrWillBeHidden()) showButtons();
        });

        zoomIn.setOnClickListener(e->{
            if (size<36) size+=2;
            loadPage();
            TransitionManager.endTransitions(root);
        });

        zoomOut.setOnClickListener(e->{
            if (size>8) size-=2;
            loadPage();
            TransitionManager.endTransitions(root);
        });

        menuBtn.setOnClickListener(e->{
            if (optionsMenu.isShown()) hideOptions(); else showOptions();
        });

        searchText.setOnFocusChangeListener((v,b)->{
            if (!b) ((InputMethodManager)getSystemService(Context.INPUT_METHOD_SERVICE)).hideSoftInputFromWindow(root.getWindowToken(),0);
        });

        setSupportActionBar(menuBar);
        ActionBar actionBar = getSupportActionBar();
        assert actionBar != null;
        actionBar.setTitle("Contents");

        loadManual();
    }

    public void addCard(String header, ArrayList<String> content, boolean inModal) {
        LinearLayout ll = new LinearLayout(getApplicationContext());
        ll.setLayoutParams(new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));
        ll.setOrientation(LinearLayout.VERTICAL);

        CardView ch = new CardView(getApplicationContext());
        ch.setRadius(0);
        ch.setCardBackgroundColor(getColor(container.getChildCount()%2==0?R.color.colorPrimary:R.color.colorPrimaryLess));
        ch.setCardElevation(2);
        ll.addView(ch);

        TextView h = new TextView(getApplicationContext());
        h.setTextColor(getColor(R.color.colorText));
        CardView.LayoutParams lp = new CardView.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
        lp.setMargins(2*size, 2*size, 2*size, 2*size);
        h.setLayoutParams(lp);
        ch.addView(h);
        h.setTextSize(1.4f*size);
        h.setText(parse(header));

        if (content.size()>0) {
            SpannableStringBuilder ssb = new SpannableStringBuilder();
            int j=0;
            for (String i: content) {
                if (inModal) ssb.append(parse(i));
                else {
                    if (i.startsWith("##### ")) ++j;
                    ssb.append(parse(i,j));
                }
            }
            CardView cc = new CardView(getApplicationContext());
            cc.setRadius(0);
            cc.setCardBackgroundColor(getColor(container.getChildCount() % 2 == 0 ? R.color.colorPrimaryLight : R.color.colorPrimaryLightLess));
            cc.setCardElevation(1);
            if (inModal) {
                ScrollView s = new ScrollView(getApplicationContext());
                s.setOnScrollChangeListener((v,x,y,ox,oy)->{
                    if (y-oy>20&&zoomIn.isOrWillBeShown()) hideButtons();
                    else if (oy-y>20&&zoomIn.isOrWillBeHidden()) showButtons();
                });
                ll.addView(s);
                s.addView(cc);
                s.fullScroll(View.FOCUS_DOWN);
            } else ll.addView(cc);

            TextView c = new TextView(getApplicationContext());
            c.setTextColor(getColor(R.color.colorText));
            lp = new CardView.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
            lp.setMargins(2*size, 2*size, 2*size, 2*size);
            c.setLayoutParams(lp);
            //c.setLineHeight(Math.round(3*size));
            c.setTextSize(size);
            cc.addView(c);
            c.setText(ssb);
        }

        if (inModal) modal.addView(ll);
        else container.addView(ll);
    }

    public void showContents() {
        TransitionManager.beginDelayedTransition(root);
        ind=-1;
        setSupportActionBar(menuBar);
        getSupportActionBar().setTitle("Contents");
        getSupportActionBar().setDisplayHomeAsUpEnabled(false);
        ViewGroup.LayoutParams lp = navigationView.getLayoutParams();
        lp.width=LayoutParams.MATCH_PARENT;
        navigationView.setVisibility(View.VISIBLE);
        navigationView.setLayoutParams(lp);
        hideButtons();
    }
    public void hideContents() {
        TransitionManager.beginDelayedTransition(root);
        setSupportActionBar(toolbar);
        getSupportActionBar().setHomeAsUpIndicator(R.drawable.ic_menu);        getSupportActionBar().setDisplayHomeAsUpEnabled(false);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setTitle(parse(headers.get(ind)));
        ViewGroup.LayoutParams lp = navigationView.getLayoutParams();
        lp.width=1;
        navigationView.setLayoutParams(lp);
        navigationView.setVisibility(View.GONE);
        loadPage();
        showButtons();
    }

    public void showOptions() {
        TransitionManager.beginDelayedTransition(root);
        optionsMenu.setVisibility(View.VISIBLE);
    }
    public void hideOptions() {
        TransitionManager.beginDelayedTransition(root);
        optionsMenu.setVisibility(View.GONE);
    }

    public void showButtons() {
        zoomIn.show(); zoomOut.show(); menuBtn.show(); hideOptions();
    }
    public void hideButtons() {
        zoomIn.hide(); zoomOut.hide(); menuBtn.hide(); hideOptions();
    }

    public void showSearch() {
        searchText.setVisibility(View.VISIBLE);
        searchText.requestFocus();
        ((InputMethodManager)getSystemService(Context.INPUT_METHOD_SERVICE)).showSoftInput(searchText, 0);
    }
    public void hideSearch() {
        searchText.clearFocus();
        searchText.setVisibility(View.GONE);
        ((InputMethodManager)getSystemService(Context.INPUT_METHOD_SERVICE)).hideSoftInputFromWindow(root.getWindowToken(),0);
    }

    public void hideModal() {
        TransitionManager.beginDelayedTransition(root);
        showButtons();
        modal.removeAllViews();
        overlay.setVisibility(View.GONE);
        view=0;
    }
    public void hideModal(View v) {hideModal();}

    public void loadManual() {
        Scanner info = new Scanner(getResources().openRawResource(R.raw.info));
        info.useDelimiter("\n\n");
        int h=-1, i=-1, j=-1;
        while (info.hasNext()) {
            String str = info.next();
            if (str.startsWith("# ")) {
                ++h;
                SpannableString s = new SpannableString(str.substring(2));
                s.setSpan(new ForegroundColorSpan(getColor(R.color.colorAccent)),0,s.length(),Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
                s.setSpan(new RelativeSizeSpan(1.75f),0,s.length(),Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
                s.setSpan(new StyleSpan(Typeface.BOLD),0,s.length(),Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
                MenuItem item = menu.getMenu().add(s);
                item.setEnabled(false);
            } else if (str.startsWith("## ")) {
                ++i;
                headers.add(str.substring(2));
                subHeaders.add(new ArrayList<>());
                content.add(new ArrayList<>());
                MenuItem item = menu.getMenu().add(i+1+".  "+str.substring(3));
                int finalI=i;
                item.setOnMenuItemClickListener(e->{
                    ind=finalI;
                    hideContents();
                    return true;
                });
                j=-1;
            } else if (str.startsWith("### ")) {
                ++j;
                subHeaders.get(i).add(str);
                content.get(i).add(new ArrayList<>());
            } else {
                content.get(i).get(j).add(str);
            }
        }
    }

    public void loadPage(){
        loadPage(ind);
    }

    public void loadPage(int i) {
        getSupportActionBar().setTitle(parse(headers.get(i)));
        container.removeAllViews();
        hideModal();
        optionsMenu.getMenu().clear();
        for (int j=0;j<subHeaders.get(i).size();j++) {
            if (j==0) addCard(subHeaders.get(i).get(j),content.get(i).get(j),false);
            else {
                optionsMenu.getMenu().add(parse(subHeaders.get(i).get(j)));
                int finalJ = j;
                optionsMenu.getMenu().getItem(j-1).setOnMenuItemClickListener(e->{
                    TransitionManager.beginDelayedTransition(root);
                    view=finalJ;
                    addCard(subHeaders.get(i).get(finalJ),content.get(i).get(finalJ),true);
                    hideButtons();
                    overlay.setVisibility(View.VISIBLE);
                    return true;
                });
            }
        }
        if (view!=0) addCard(subHeaders.get(i).get(view),content.get(i).get(view),true);
    }
    public SpannableStringBuilder parse(String s) {return parse(s,0);}

    public SpannableStringBuilder parse(String s, int ind) {
        SpannableStringBuilder span = new SpannableStringBuilder();
        String[] a = s.split("\n");
        int bold=-1, italic=-1, sub=-1, sup=-1;
        for (String str: a) {
            String original = str;
            if (str.startsWith("#")) {
                str=str.substring(str.indexOf(' ')+1);
                if (original.startsWith("##### ")&&ind!=0) str=ind+". "+str;
            }
            if (str.matches(" *-.*"))
                str=str.substring(str.indexOf('-')+1);
            int st = span.length();
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
                    span.append(calculateByWeight?x*weight+"":x+"/kg");
                    //span.setSpan(new TypefaceSpan(Typeface.MONOSPACE),k,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                    span.setSpan(new StyleSpan(Typeface.BOLD),k,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                    span.setSpan(new ForegroundColorSpan(ContextCompat.getColor(getApplicationContext(),R.color.colorAccent)),k,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                    span.setSpan(new BackgroundColorSpan(ContextCompat.getColor(getApplicationContext(),R.color.colorTranslucent)),k,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                    i=e;
                } else if (i+5<=str.length()&&str.substring(i,i+5).equals("<sub>")) {
                    sub=span.length();
                    i+=4;
                } else if (i+6<=str.length()&&str.substring(i,i+6).equals("</sub>")) {
                    if (sub!=-1) {
                        span.setSpan(new SubscriptSpan(),sub,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                        span.setSpan(new RelativeSizeSpan(0.8f),sub,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                    }
                    sub=-1;
                    i+=5;
                } else if (i+5<=str.length()&&str.substring(i,i+5).equals("<sup>")) {
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
            if (original.startsWith("#### ")) {
                span.setSpan(new StyleSpan(Typeface.BOLD), st, span.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                span.setSpan(new RelativeSizeSpan(1.4f), st, span.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                //span.setSpan(new LineHeightSpan.Standard(4*size), st, span.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            } else if (original.startsWith("##### ")) {
                span.setSpan(new StyleSpan(Typeface.BOLD_ITALIC), st, span.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                span.setSpan(new ForegroundColorSpan(ContextCompat.getColor(getApplicationContext(),R.color.colorAccentDark)),st,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                span.setSpan(new RelativeSizeSpan(1.2f), st, span.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                //span.setSpan(new LineHeightSpan.Standard(4*size), st, span.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            } else if (original.startsWith("- ")) {
                span.setSpan(new BulletSpan(), st, span.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            } else if (original.startsWith("  - ")) {
                span.setSpan(new LeadingMarginSpan.Standard(size*2), st, span.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
                span.setSpan(new BulletSpan(), st, span.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
            if (!(original.startsWith("#")&&original.indexOf(' ')<4)) {
                span.append("\n\n");
                span.setSpan(new RelativeSizeSpan(0.5f),span.length()-2,span.length(),Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
        }
        return span;
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.toolbar,menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                showContents();
                break;
            case R.id.scale:
                WeightDialogFragment f = new WeightDialogFragment();
                f.show(getSupportFragmentManager(),null);
                break;
            case R.id.more:
                Toast.makeText(getApplicationContext(),"Nothing to see here!",Toast.LENGTH_SHORT).show();
                break;
            case R.id.search:
                TransitionManager.beginDelayedTransition(root);
                if (searchText.isShown()) hideSearch();
                else showSearch();
        }
        return true;
    }

    @Override
    public void onBackPressed() {
        if (view==0) {
            if (navigationView.isShown()) super.onBackPressed();
            else showContents();
        }
        else hideModal();
    }

    @Override
    public void onDialogPositiveClick(DialogFragment dialog) {
        if (ind!=-1) loadPage();
        TransitionManager.endTransitions(root);
        showButtons();
    }

    @Override
    public void onDialogNegativeClick(DialogFragment dialog) {
        showButtons();
    }
}
