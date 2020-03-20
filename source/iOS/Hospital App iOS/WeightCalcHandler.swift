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
    public static func showConfigurationPrompt(on vc: UIViewController, completion: (() -> ())?) {
        var inputTextField: UITextField?
        let prompt = UIAlertController(title: "Weight (kg)", message: "Calculate dosage by patient weight:", preferredStyle: .alert)
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            completion?()
        }))
        prompt.addAction(UIAlertAction(title: "Set", style: .default, handler: { action in
            if let text = inputTextField?.text,
                let num = Double(text) {
                Settings.patientWeightPreferred = num
            } else if inputTextField?.text?.isEmpty != false {
                Settings.patientWeightPreferred = nil
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
            if let w = Settings.patientWeightPreferred {
                textField.text = "\(w)"
            }
            inputTextField = textField
         })

        vc.present(prompt, animated: true, completion: nil)
    }
    
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
                    if let weight = Settings.patientWeightPreferred {
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
    
    public static func injectJavascriptSetup(into webView: WKWebView) {
        return
        webView.evaluateJavaScript(
            """
            var doseConvList = [];
            function setupDynamicDose() {
                if (document.body.innerText.match(/{.*}/g) == null) {
                    doseConvList = [];
                    return {"present": false}
                }
                if (document.getElementsByClassName("dynamicDoseLabel") == [] && document.body.innerText.match(/{.*}/g).length >= 0) {
                    
                    doseConvList = document.body.innerText.match(/{.*}/g);
                
                    for (var i = 0; i < doseConvList.length; i++) {
                        var terms = doesConvList[i].split(" ");
                        doesConvList[i] = {"value": terms[0] - 0, "unit/kg": terms[1]};
                    }

                    document.body.innerHTML = document.body.innerHTML.replace(/{.*}/g, "<b><span class='dynamicDoseLabel'></span></b>");
                    
                    updateDynamicDoses();
                    return {"present": true}
                }
            }
            
            function updateDynamicDoses(value) {
                var eles = document.getElementsByClassName("dynamicDoseLabel");
                if (value == undefined || value == null) {
                    for (var i = 0; i < eles.length; i++) {
                        eles.innerText = doseConvList[i]["value"] + " " + doseConvList[i]["value"]["unit"] + "/kg";
                    }
                } else {
                    for (var i = 0; i < eles.length; i++) {
                        eles.innerText = doseConvList[i]["value"]*value + " " + doseConvList[i]["value"]["unit"];
                    }
                }
                return {"result": true}
            }

            setupDynamicDose();
            """
        ) { (res, err) in
            if err != nil {
                print("ono js injection went wrong yeet")
                print(err!)
            } else {
                print("javascript \(res)")
            }
        }
    }
    public static func injectJavascriptUpdate(into webView: WKWebView, patientWeight: Double? = nil) {
        let input = patientWeight ?? Settings.patientWeightPreferred
        let inputStr = input != nil ? String(input!) : "null"
        let inputFunc = "updateDynamicDoses(\(inputStr));"
        webView.evaluateJavaScript(inputFunc) { (res, err) in
            if err != nil {
                print("ono js injection went wrong aaaa")
                print(err!)
            } else {
                print("javascript \(res)")
            }
        }
    }
}

