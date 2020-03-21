//
//  WeightCalculationHandler.swift
//  Hospital App iOS
//
//  Created by Wern Jie Lim on 21/3/20.
//  Copyright © 2020 Wern Jie Lim. All rights reserved.
//

import UIKit
import WebKit

public class WeightCalcHandler {
    
    ///Shows a prompt over a view controller for configuring the patient weight and updates it in `Settings.preferredPatientWeight`.
    public static func showConfigurationPrompt(on vc: UIViewController, completion: (() -> ())?) {
        var inputTextField: UITextField?
        let prompt = UIAlertController(title: "Weight (kg)", message: "Calculate dosage by patient weight:", preferredStyle: .alert)
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            completion?()
        }))
        prompt.addAction(UIAlertAction(title: "Set", style: .default, handler: { action in
            if let text = inputTextField?.text,
                let num = Double(text) {
                Settings.preferredPatientWeight = num
            } else if inputTextField?.text?.isEmpty != false {
                Settings.preferredPatientWeight = nil
            } else {
                let errorPrompt = UIAlertController(title: "Error", message: "Invalid value", preferredStyle: .alert)
                errorPrompt.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                vc.present(errorPrompt, animated: true, completion: nil)
            }
            completion?()
        }))
        prompt.addTextField(configurationHandler: { textField in
            textField.placeholder = "None (disabled)"
            textField.keyboardType = .decimalPad
            if let w = Settings.preferredPatientWeight {
                textField.text = "\(w)"
            }
            inputTextField = textField
         })

        vc.present(prompt, animated: true, completion: nil)
    }
    
    ///Replaces dynamic dosage values (wrapped in `{# unit}`) in the input text with the relevant calculations (assuming it to be unit/kg) based off `Settings.preferredPatientWeight`, and then returns the updated text as an output.
    public static func updateDynamicDosage(markdownContents: String) -> String {
        var newStr = ""
        var inDynDosTag = false
        var tmpDynDos = ""
        for c in markdownContents {
            switch c {
            case "{":
                inDynDosTag = true
            case "}":
                inDynDosTag = false
                let terms = tmpDynDos.split(separator: " ")
                if var val = Double(terms[0]) {
                    let unit = terms[1]
                    if let weight = Settings.preferredPatientWeight {
                        val *= weight
                        val = round(val*1000)/1000
                        newStr += "**<dyn>" + "\(val) \(unit)" + "</dyn>**";
                    } else {
                        newStr += "**<dyn>" + "\(val) \(unit)/kg" + "</dyn>**";
                    }
                } else {
                    newStr += "{" + "\(tmpDynDos)" + "}";
                }
                tmpDynDos = ""
            default:
                if inDynDosTag {
                    tmpDynDos.append(c)
                } else {
                    newStr.append(c)
                }
            }
        }
        newStr += tmpDynDos
        return newStr
    }
}

