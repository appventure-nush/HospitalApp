//
//  ViewController.swift
//  Hospital App iOS
//
//  Created by Wern Jie Lim on 6/2/19.
//  Copyright © 2019 Wern Jie Lim. All rights reserved.
//

import UIKit
import WebKit
import Down

class SearchAccessoryView: UIView {
    @IBOutlet var searchBar: UISearchBar!
}
class ContentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UITextFieldDelegate, WKNavigationDelegate {

    var homepage: MainTableViewController?
    var topic: DataHandler.Section?
    var topicNo: Int?
    
    var cachedSelectedSegmentIndexPath       = IndexPath(row: 0, section: 0)
    var selectedSegmentIndexPath: IndexPath? = IndexPath(row: 0, section: 0) {
        didSet {
            if let iP = selectedSegmentIndexPath {
                cachedSelectedSegmentIndexPath = iP
            }
        }
    }
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var contentView: UIView!
    @IBOutlet var sectionPickerView: UIView!
    @IBOutlet var zoomStepper: UIStepper!
    var downView: DownView?
    
    @IBOutlet var searchAccessoryView: SearchAccessoryView!
    var searchBar: UISearchBar! {
        return searchAccessoryView?.searchBar
    }
    var activeSearchResultCount: Int?
    var activeSearchResultIndex: Int?
    
    var searchBarBottomConstraint: NSLayoutConstraint?
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var sectionPickerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var patientWeightConfigButton: UIBarButtonItem!
    
    @IBOutlet var warningLabel: UILabel!
    
    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = true
        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.sectionPickerView.clipsToBounds = false
        self.sectionPickerView.layer.cornerRadius = 8
        self.sectionPickerView.layer.shadowOffset = .zero
        self.sectionPickerView.layer.shadowOpacity = 0.2
        self.sectionPickerView.layer.shadowRadius = 3
        
        self.zoomStepper.clipsToBounds = true
        if #available(iOS 13.0, *) {
            self.zoomStepper.layer.cornerRadius = 8
        }
        self.zoomStepper.value = Settings.contentZoomLevel
        
        guard let topic = topic else {return}
        topic.convertToSubsections()
        
        self.title = (topicNo != nil ? "\(topicNo!). " : "") + topic.title
        do {
            let contents: String? = topic.markdownContents
            
            self.downView = try DownView(frame: .zero,
                                         markdownString: contents ?? "",
                                         templateBundle: Bundle.main,
                                         options: [.unsafe, .hardBreaks]) {
                UIView.animate(withDuration: 0.2, animations: {
                    self.downView?.alpha = 1
                }) { (completion) in
                    self.activityIndicator.stopAnimating()
                    self.downView?.navigationDelegate = self
                    self.downView?.evaluateJavaScript("document.body.style.zoom = '\(CGFloat(Settings.contentZoomLevel*100))%';[true];", completionHandler: nil)
                }
            }
            
            self.downView?.alpha = 0
            self.downView?.evaluateJavaScript("document.body.style.zoom = '\(CGFloat(Settings.contentZoomLevel*100))%';[true];", completionHandler: nil)
            
            self.contentView.addSubview(self.downView!)
            self.contentView.sendSubviewToBack(self.downView!)
            
            self.downView?.translatesAutoresizingMaskIntoConstraints = false
            let leadC = NSLayoutConstraint(item: downView!, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 0)
            let trailC = NSLayoutConstraint(item: downView!, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: 0)
            let topC = NSLayoutConstraint(item: downView!, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0)
            let bottomC = NSLayoutConstraint(item: downView!, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0)
            
            contentView.addConstraints([leadC, trailC, topC, bottomC])
            updateViews(animated: false)
        } catch (let e) {
            print("an error '\(e.localizedDescription)' has occured")
        }
        
        self.view.bringSubviewToFront(self.sectionPickerView)
        
        self.searchAccessoryView.isHidden = true
        if #available(iOS 13.0, *) {} else {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardWillShow),
                name: UIResponder.keyboardWillShowNotification,
                object: nil
            )
            self.view.addSubview(searchAccessoryView)
            searchAccessoryView.translatesAutoresizingMaskIntoConstraints = false
            searchBarBottomConstraint = NSLayoutConstraint(item: self.view!, attribute: .bottom, relatedBy: .equal, toItem: searchAccessoryView, attribute: .bottom, multiplier: 1, constant: 0)
            self.view.addConstraints(
                [searchBarBottomConstraint!,
                 NSLayoutConstraint(item: self.view!, attribute: .leading, relatedBy: .equal, toItem: searchAccessoryView!, attribute: .leading, multiplier: 1, constant: 0),
                 NSLayoutConstraint(item: self.view!, attribute: .trailing, relatedBy: .equal, toItem: searchAccessoryView!, attribute: .trailing, multiplier: 1, constant: 0)])
            self.view.bringSubviewToFront(self.searchAccessoryView)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchBar.resignFirstResponder()
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    // MARK: - Section Table Action Handler
    @IBAction func launchSectionView() {
        if let iP = selectedSegmentIndexPath {
            tableView(tableView, didSelectRowAt: iP)
        }
        updateViews()
    }
    
    // MARK: - View Zooming Config
    @IBAction func zoomStepperPressed(_ sender: UIStepper!) {
        Settings.contentZoomLevel = sender.value
        print(Settings.contentZoomLevel)
        
        self.downView?.evaluateJavaScript("document.body.style.zoom = '\(CGFloat(Settings.contentZoomLevel*100))%';[true];", completionHandler: nil)
    }
    
    // MARK: - Patient Weight Config
    @IBAction func weightConfigPressed(_ sender: UIBarButtonItem!) {
        WeightCalcHandler.showConfigurationPrompt(on: self, completion: {
            self.updateViews()
        })
    }
    
    // MARK: - Down View Navigation Delegate Methods
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        print("navigation action requested.")
        
        if webView == downView {
            if let url = navigationAction.request.url,
                url != Bundle.main.url(forResource: "index", withExtension: "html") {
                
                decisionHandler(.cancel)
                
                if url.lastPathComponent.starts(with: "page_"),
                    let pageNo = Int(url.lastPathComponent.replacingOccurrences(of: "page_", with: "")) {
                    
                    homepage?.autoOpenPage = pageNo + 1 //counterintuitively the page numbers in this document is zero-indexed
                    self.navigationController?.popViewController(animated: true)
                } else if url.lastPathComponent.starts(with: "media_") {
                    var filename = url.lastPathComponent
                    if filename.starts(with: "media_image") && url.pathExtension == "" {
                        filename += ".png"
                    }
                    if filename.starts(with: "media_video") && url.pathExtension == "" {
                        filename += ".mp4"
                    }
                    if let mediaUrl = Bundle.main.url(forResource: filename, withExtension: nil) {
                        QuickLookPreviewer(mediaUrl).present(over: self)
                    } else {
                        let a = UIAlertController(title: "Can't find document", message: "Cannot locate document '\(filename)'", preferredStyle: .alert)
                        a.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.present(a, animated: true, completion: nil)
                    }
                } else if UIApplication.shared.canOpenURL(url) {
                    let a = UIAlertController(title: "Open external link?", message: url.absoluteString, preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "Open", style: .default, handler: { action in
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    }))
                    a.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(a, animated: true, completion: nil)
                } else {
                    let a = UIAlertController(title: "The link is invalid", message: url.absoluteString, preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(a, animated: true, completion: nil)
                }
                
            } else {
                downView?.webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        if webView == downView {
            downView?.webView(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView == downView {
            downView?.webView(webView, didFinish: navigation)
        }
    }
    
    // MARK: - Table View Delegate Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topic?.subsections.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let selected = indexPath == selectedSegmentIndexPath
        cell.textLabel?.text = topic?.subsections[indexPath.row].title
        cell.textLabel?.font = selected ? UIFont.italicSystemFont(ofSize: 18) : UIFont.systemFont(ofSize: 18)
        cell.accessoryType = selected ? .checkmark : .disclosureIndicator
        cell.setSelected(selected, animated: false)
        return cell
    }
    
    var selectRowDate: Date = Date()
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer {
            selectRowDate = Date()
            updateViews()
        }
        
        if let prevIndexPath = selectedSegmentIndexPath {
            let cell = tableView.cellForRow(at: prevIndexPath)
            cell?.accessoryType = .checkmark
            cell?.textLabel?.font = UIFont.italicSystemFont(ofSize: 18)
            tableView.deselectRow(at: prevIndexPath, animated: true)
            if prevIndexPath == indexPath {
                selectedSegmentIndexPath = nil
                return
            }
        }
        let oldCell = tableView.cellForRow(at: cachedSelectedSegmentIndexPath)
        let newCell = tableView.cellForRow(at: indexPath)
        
        tableView.deselectRow(at: cachedSelectedSegmentIndexPath, animated: true)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
        
        oldCell?.accessoryType = .disclosureIndicator
        oldCell?.textLabel?.font = UIFont.systemFont(ofSize: 18)
        
        newCell?.accessoryType = .checkmark
        newCell?.textLabel?.font = UIFont.italicSystemFont(ofSize: 18)
        
        selectedSegmentIndexPath = indexPath
        
        
        return
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == tableView && -selectRowDate.timeIntervalSinceNow > 0.3 {
            launchSectionView()
        }
    }
    
    // MARK: - Text field handling
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let dw = downView,
            let sCount = activeSearchResultCount,
            let sIndex = activeSearchResultIndex,
            sCount >= 0 {
            
            let newIndex = (sIndex + 1) % sCount
            activeSearchResultIndex = newIndex
            
            webViewScrollToSearchResult(dw, index: newIndex)
        }
    }
    
    // MARK: - Search result handling
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            self.searchBarBottomConstraint?.constant = keyboardHeight
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func searchToggle() {
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
            searchBar.text = ""
            if #available(iOS 13.0, *) {
                searchAccessoryView.removeFromSuperview()
            } else {
                self.searchBarBottomConstraint?.constant = 0
                self.view.layoutIfNeeded()
            }
            if let dw = downView {
                webViewRemoveAllSearchHighlights(dw)
            }
            self.activeSearchResultCount = nil
            self.activeSearchResultIndex = nil
            self.searchAccessoryView.isHidden = true
        } else {
            self.searchAccessoryView.isHidden = false
            if #available(iOS 13.0, *) {
                searchBar.inputAccessoryView = searchAccessoryView
                self.view.addSubview(searchAccessoryView)
            }
            searchBar.delegate = self
            searchBar.becomeFirstResponder()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let dw = downView {
            webViewSearchAndHighlightAllOccurencesOfString(dw, str: searchText) { count in
                self.activeSearchResultCount = count
                self.activeSearchResultIndex = count == 0 ? nil : 0
                if count > 0 {
                    self.webViewScrollToSearchResult(dw, index: 0)
                } else {
                    self.webViewRemoveAllSearchHighlights(dw)
                }
            }
        }
        
    }
    
    func webViewSearchAndHighlightAllOccurencesOfString(_ webView: WKWebView, str: String, resultCount: @escaping (Int) -> ()) {
        guard
            let path = Bundle.main.path(forResource: "webViewSearch", ofType: "js"),
            let jsCode = try? String(contentsOfFile: path)
            else {resultCount(0); return}
        
        let startSearch = "webView_HighlightAllOccurencesOfString('\(str)')"
        let result = "webView_SearchResultCount"
        
        print("performing search highlights")
        webView.evaluateJavaScript(jsCode + ";" + startSearch + ";[" + result + "]",
                                   completionHandler: { (res, err) in
            if err == nil,
                let res = res as? Array<Int> {
                let count = res[0]
                resultCount(count)
            } else {
                print(err!)
                resultCount(0)
            }
        })
    }

    func webViewScrollToSearchResult(_ webView: WKWebView, index:Int)  {
        print("attempting scroll to search highlight at index \(index)")
        webView.evaluateJavaScript("webView_ScrollToSearch(\(index))", completionHandler: {res, err in if let err = err {print(err)}})

    }

    func webViewRemoveAllSearchHighlights(_ webView: WKWebView) {
        print("removing search highlights")
        webView.evaluateJavaScript("webView_RemoveAllHighlights()", completionHandler: {res, err in if let err = err {print(err)}})
    }
    
    
    // MARK: - Overall view updates
    func updateViews(animated: Bool = true) {
        guard let topic = topic else {return}
        
        print("update views called.")
        
        //Get contents to be displayed
        var contents: String?
        if let iP = selectedSegmentIndexPath {
            contents = topic.subsections[iP.row].asMarkdown()
        } else if !topic.markdownContents.isEmpty {
            contents = topic.markdownContents
        }
        
        //Update markdown view
        do {
            if let downView = self.downView,
                let contents = contents {
                let contentsWDynDose = WeightCalcHandler.updateDynamicDosage(markdownContents: contents + "\n\n</br>")
                try downView.update(markdownString: contentsWDynDose, options: [.unsafe, .hardBreaks])
            }
        } catch (let e) {
            let alert = UIAlertController(title: "Warning: Something went wrong.", message: e.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            print("an error '\(e.localizedDescription)' has occured")
        }
        
        self.warningLabel.text = Settings.preferredPatientWeight != nil ?
            "Patient Weight set: \(Settings.preferredPatientWeight!) kg" : nil

        //Animate possible table view changes
        UIView.animate(withDuration: animated ? 0.3 : 0.0, delay: 0, options: [.curveEaseInOut], animations: {
            let totalHeight =
                    self.contentView.bounds.height +
                    self.sectionPickerView.bounds.height
            
            var bottomInset = CGFloat(0)
            if #available(iOS 11.0, *) {
                bottomInset = self.view.safeAreaInsets.bottom
            }
            
            if let iP = self.selectedSegmentIndexPath {
                self.tableView.selectRow(at: iP, animated: true, scrollPosition: .middle)
                self.sectionPickerHeightConstraint.constant = min(totalHeight * 0.3, 120 + bottomInset)
                self.sectionPickerView.layer.shadowRadius = 3
            } else {
                self.sectionPickerHeightConstraint.constant = min(totalHeight * 0.6, 400 + bottomInset)
                
                self.sectionPickerView.layer.shadowRadius =
                    topic.markdownContents.isEmpty ? 0 : 3
            }
            
            self.view.layoutIfNeeded()
            
        }, completion: {(completed) in
            if let iP = self.selectedSegmentIndexPath {
                self.tableView.scrollToRow(at: iP, at: .middle, animated: true)
            }
            /*if let downView = self.downView, contents == nil && completed {
                try? downView.update(markdownString: "", options: [.unsafe, .hardBreaks])
            }*/
        })
        
        
    }
}

