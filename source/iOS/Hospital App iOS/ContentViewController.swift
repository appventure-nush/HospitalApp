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

class ContentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UITextFieldDelegate {

    var topic: DataHandler.Section?
    var selectedSegmentIndexPath: IndexPath?
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var contentView: UIView!
    @IBOutlet var sectionPickerView: UIView!
    @IBOutlet var zoomStepper: UIStepper!
    var downView: DownView?
    
    @IBOutlet var searchAccessoryView: UIView!
    @IBOutlet var searchBar: UISearchBar!
    var activeSearchResultCount: Int?
    var activeSearchResultIndex: Int?
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var sectionPickerHeightConstraint: NSLayoutConstraint!
    
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
        self.zoomStepper.layer.cornerRadius = 8
        self.zoomStepper.value = Settings.contentMinimumTextSize
        
        guard let topic = topic else {return}
        topic.convertToSubsections()
        
        self.title = topic.title
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
                }
            }
            
            self.downView?.alpha = 0
            self.downView?.configuration.preferences.minimumFontSize = CGFloat(Settings.contentMinimumTextSize)
            
            self.contentView.addSubview(self.downView!)
            self.contentView.sendSubviewToBack(self.downView!)
            
            self.downView!.translatesAutoresizingMaskIntoConstraints = false
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
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateViews()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchBar.resignFirstResponder()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    // MARK: - View Zooming Config
    @IBAction func zoomStepperPressed(_ sender: UIStepper!) {
        downView?.configuration.preferences.minimumFontSize = CGFloat(sender.value)
        Settings.contentMinimumTextSize = sender.value
        print(Settings.contentMinimumTextSize)
    }
    
    // MARK: - Patient Weight Config
    @IBAction func weightConfigPressed(_ sender: UIBarButtonItem!) {
        WeightCalcHandler.showConfigurationPrompt(on: self, completion: {
            self.updateViews()
        })
    }
    
    // MARK: - Table View Delegate Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topic?.subsections.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let selected = indexPath == selectedSegmentIndexPath
        cell.textLabel?.text = topic!.subsections[indexPath.row].title
        cell.textLabel?.font = selected ? UIFont.boldSystemFont(ofSize: 20) : UIFont.systemFont(ofSize: 20)
        cell.accessoryType = selected ? .checkmark : .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer {
            //tableView.deselectRow(at: indexPath, animated: true)
            updateViews()
        }
        
        if let prevIndexPath = selectedSegmentIndexPath {
            let cell = tableView.cellForRow(at: prevIndexPath)
            cell?.accessoryType = .disclosureIndicator
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 20)
            if prevIndexPath == indexPath {
                selectedSegmentIndexPath = nil
                return
            }
        }
        let newCell = tableView.cellForRow(at: indexPath)
        newCell?.accessoryType = .checkmark
        newCell?.textLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        selectedSegmentIndexPath = indexPath
        
        return
    }
    
    // MARK: - Text field handling
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case searchBar.searchTextField:
            if let dw = downView,
                let sCount = activeSearchResultCount,
                let sIndex = activeSearchResultIndex,
                sCount >= 0 {
                
                let newIndex = (sIndex + 1) % sCount
                activeSearchResultIndex = newIndex
                
                webViewScrollToSearchResult(dw, index: newIndex)
                return true
            }
            return false
        default:
            break
        }
        
        return true
    }
    
    // MARK: - Search result handling
    @IBAction func searchToggle() {
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
            searchBar.text = ""
            searchAccessoryView.removeFromSuperview()
            if let dw = downView {
                webViewRemoveAllSearchHighlights(dw)
            }
            self.activeSearchResultCount = nil
            self.activeSearchResultIndex = nil
        } else {
            searchBar.inputAccessoryView = searchAccessoryView
            self.view.addSubview(searchAccessoryView)
            searchBar.delegate = self
            searchBar.searchTextField.returnKeyType = .next
            searchBar.searchTextField.delegate = self
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
        
        //Get contents to be displayed
        var contents: String?
        if let iP = selectedSegmentIndexPath {
            contents = topic.subsections[iP.row].asMarkdown()
        } else if topic.markdownContents.isEmpty == false {
            contents = topic.markdownContents
        } else if topic.subsections.count > 0 {
            selectedSegmentIndexPath = IndexPath(row: 0, section: 0)
            self.tableView.selectRow(at: selectedSegmentIndexPath, animated: true, scrollPosition: .middle)
            contents = topic.subsections[0].asMarkdown()
        }
        
        //Update markdown view
        do {
            if let downView = self.downView,
                let contents = contents {
                let contentsWDynDose = WeightCalcHandler.updateDynamicDosage(markdownContents: contents + "\n\n</br>")
                try downView.update(markdownString: contentsWDynDose, options: [.unsafe, .hardBreaks])
            }
        } catch (let e) {
            let alert = UIAlertController(title: "Something went wrong.", message: e.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            print("an error '\(e.localizedDescription)' has occured")
        }

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
                self.tableView.scrollToRow(at: iP, at: .middle, animated: true)
                self.sectionPickerHeightConstraint.constant = min(totalHeight * 0.3, 200 + bottomInset)
                self.sectionPickerView.layer.shadowRadius = 3
            } else {
                self.sectionPickerHeightConstraint.constant =
                    topic.markdownContents.isEmpty ? totalHeight : min(totalHeight * 0.35, 220 + bottomInset)
                
                self.sectionPickerView.layer.shadowRadius =
                    topic.markdownContents.isEmpty ? 0 : 3
            }
            
            self.view.layoutIfNeeded()
            
        }, completion: {(completed) in
            if let iP = self.selectedSegmentIndexPath {
                self.tableView.scrollToRow(at: iP, at: .middle, animated: true)
            }
            if let downView = self.downView, contents == nil && completed {
                try? downView.update(markdownString: "", options: [.unsafe, .hardBreaks])
            }
        })
        
        
    }
}

