//
//  Settings.swift
//  Hospital App iOS
//
//  Created by Wern Jie Lim on 20/3/20.
//  Copyright © 2020 Wern Jie Lim. All rights reserved.
//

import Foundation

public class Settings {
    public static var contentMinimumTextSize: Double {
        get {
            UserDefaults.standard.object(forKey: "contentMinimumTextSize") as? Double ?? 1.0
        }
        set (x) {
            UserDefaults.standard.set(x, forKey: "contentMinimumTextSize")
        }
    }
    public static var preferredPatientWeight: Double?
}
