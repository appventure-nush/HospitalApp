//
//  QuickLookPreviewer.swift
//
//  Copyright © 2020 Lim Wern Jie. All rights reserved.
//

import UIKit
import QuickLook


public class QuickLookPreviewer : NSObject , QLPreviewControllerDelegate , QLPreviewControllerDataSource {
    
    private var controller: QLPreviewController?
    
    public var url: URL!
    
    init(_ url: URL) {
        super.init()
        
        self.url = url
        
        controller = QLPreviewController()
        controller?.delegate = self
        controller?.dataSource = self
    }
    
    public func present(over controller: UIViewController) {
        controller.present(self.controller!, animated: true, completion: nil)
    }
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return url as QLPreviewItem
    }
    
    public var dismissHandler: (() -> ())?
    public func previewControllerDidDismiss(_ controller: QLPreviewController) {
        dismissHandler?()
    }
}
