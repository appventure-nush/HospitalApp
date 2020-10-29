//
//  Extensions.swift
//  Hospital App iOS
//
//  Created by Lim Wern Jie on 06/12/2019.
//  Copyright © 2019 Wern Jie Lim. All rights reserved.
//

import Foundation
import UIKit

extension Bundle {
    static func loadView<T>(fromNib name: String, withType type: T.Type) -> T {
        if let view = Bundle.main.loadNibNamed(name, owner: nil, options: nil)?.first as? T {
            return view
        }

        fatalError("Could not load view with type " + String(describing: type))
    }
}

extension NSAttributedString {
    func changedTextSize(by amount: CGFloat) -> NSAttributedString {
        let attributedString = self.mutableCopy() as? NSMutableAttributedString
        
        do {
            attributedString?.beginEditing()
            
            attributedString?.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedString?.length ?? 0), options: [], using: { value, range, stop in
                
                var font = (value as? UIFont)
                let fontSize = (font?.pointSize ?? UIFont.systemFontSize) + amount
                
                font = font?.withSize(fontSize)
                
                attributedString?.removeAttribute(.font, range: range)
                if let font = font {
                    attributedString?.addAttribute(.font, value: font as Any, range: range)
                }
            })
            
            attributedString?.endEditing()
        }
        
        return (attributedString?.copy() as? NSAttributedString) ?? attributedString ?? self
    }
}
