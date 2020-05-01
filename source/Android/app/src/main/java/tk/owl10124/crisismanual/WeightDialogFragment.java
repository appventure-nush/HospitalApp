package tk.owl10124.crisismanual;

import android.app.Dialog;
import android.content.Context;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.EditText;
import android.widget.Switch;
import android.widget.Toast;

import java.util.Locale;

import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.DialogFragment;

public class WeightDialogFragment extends DialogFragment {
    private WeightDialogListener listener;
    @Override
    public Dialog onCreateDialog(Bundle savedInstanceState) {
        LayoutInflater inflater = requireActivity().getLayoutInflater();
        View v = inflater.inflate(R.layout.dialog_weight,null);
        Switch t = v.findViewById(R.id.weightSwitch);
        EditText w = v.findViewById(R.id.weightInput);
        t.setOnCheckedChangeListener((b,n)->{
            w.setEnabled(n);
        });
        t.setChecked(MainActivity.calculateByWeight);
        w.setEnabled(MainActivity.calculateByWeight);
        w.setText(String.valueOf(MainActivity.weight));
        AlertDialog.Builder b = new AlertDialog.Builder(getActivity());
        b.setTitle("Weight")
                .setView(v)
                .setPositiveButton(R.string.set,(d,id)->{
                    try {
                        MainActivity.weight = Float.parseFloat(w.getText().toString());
                    } catch (NumberFormatException e) {
                        Toast.makeText(getContext(), "Input invalid.",Toast.LENGTH_SHORT).show();
                        listener.onDialogNegativeClick(this);
                        return;
                    }
                    MainActivity.calculateByWeight=t.isChecked();
                    if (t.isChecked())
                        Toast.makeText(getContext(), "Calculating doses for " + String.format(Locale.ENGLISH, "%.1f", MainActivity.weight) + "kg patient", Toast.LENGTH_SHORT).show();
                    else
                        Toast.makeText(getContext(), "Dose calculation disabled", Toast.LENGTH_SHORT).show();
                    listener.onDialogPositiveClick(this);
                })
                .setNegativeButton(R.string.cancel,(d,id)->{
                    Toast.makeText(getContext(),(MainActivity.calculateByWeight ? "Still calculating doses for "+String.format(Locale.ENGLISH,"%.1f",MainActivity.weight)+"kg":"Dose calculation still disabled"),Toast.LENGTH_SHORT).show();
                    listener.onDialogNegativeClick(this);
                });
        return b.create();
    }
    @Override
    public void onAttach(Context c) {
        super.onAttach(c);
        listener = (WeightDialogListener) c;
    }

    public interface WeightDialogListener {
        public void onDialogPositiveClick(DialogFragment dialog);
        public void onDialogNegativeClick(DialogFragment dialog);
    }
}