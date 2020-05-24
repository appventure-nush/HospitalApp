//
//  MainTableViewController.swift
//  Hospital App iOS
//
//  Created by Wern Jie Lim on 6/2/19.
//  Copyright © 2019 Wern Jie Lim. All rights reserved.
//

import UIKit

class MainTableViewController: UITableViewController {

    var dataHandler: DataHandler?
    
    var autoOpenPage: Int?
    var autoOpenPageCachedSender: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
            self.navigationItem.largeTitleDisplayMode = .always
        }
        
        if let url = Bundle.main.url(forResource: "info", withExtension: "md"),
            let str = try? String(contentsOf: url, encoding: .utf8) {
                
            dataHandler = DataHandler(rawContents: str)
            for topic in dataHandler?.sectionList ?? [] {
                topic.convertToSubsections()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Auto deselect
        if let selectedRowIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRowIndexPath, animated: true)
        }
            
        //Prepare for auto page open
        if let pageNo = autoOpenPage,
            let dataHandler = dataHandler {
        
            var tmpCount = 0
            var tmpSectionIdx = 0
            for section in dataHandler.sectionList {
                if section.subsections.count + tmpCount < pageNo {
                    tmpCount += section.subsections.count
                    tmpSectionIdx += 1
                } else {
                    autoOpenPage = nil
                    let tmpSubsectionIdx = pageNo - tmpCount - 1
                    
                    tableView.selectRow(at: IndexPath(row: tmpSubsectionIdx, section: tmpSectionIdx),
                                        animated: true,
                                        scrollPosition: .none)
                    
                    autoOpenPageCachedSender = ["topic": section.subsections[tmpSubsectionIdx], "no": pageNo]
                    print("successfully prepared for automatic page open to page no \(pageNo)")
                    break
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let sender = autoOpenPageCachedSender {
            autoOpenPageCachedSender = nil
            print("performatic automatic page open")
            self.performSegue(withIdentifier: "showContents", sender: sender)
        }
    }
    
    @IBAction func weightConfigPressed(_ sender: UIBarButtonItem!) {
        WeightCalcHandler.showConfigurationPrompt(on: self, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataHandler?.sectionList.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataHandler?.sectionList[section].title ?? "?"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataHandler?.sectionList[section].subsections.count ?? 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let no = dataHandler!.sectionList[0..<indexPath.section].reduce(0, { $0 + $1.subsections.count }) + indexPath.row + 1
        let title = dataHandler!.sectionList[indexPath.section].subsections[indexPath.row].title
        
        cell.textLabel?.text = "\(no). \(title)"
        cell.tag = no
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showContents",
                          sender: [
                            "topic": dataHandler!
                                .sectionList[indexPath.section]
                                .subsections[indexPath.row],
                            "no": tableView.cellForRow(at: indexPath)?.tag ?? 0
        ])
    }
    

    /*
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    */

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showContents",
            let vc = segue.destination as? ContentViewController,
            let dict = sender as? [String: Any],
            let subsection = dict["topic"] as? DataHandler.Section {
            var no = dict["no"] as? Int
            
            vc.homepage = self
            vc.topic = subsection
            if no != 0 { vc.topicNo = no }
        }
    }

}
