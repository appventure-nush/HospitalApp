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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
            self.navigationItem.largeTitleDisplayMode = .always
        }
        
        if let url = Bundle.main.url(forResource: "transcript", withExtension: "md"),
            let str = try? String(contentsOf: url, encoding: .utf8) {
                
            dataHandler = DataHandler(rawContents: str)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataHandler?.topicList.count ?? 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.textLabel?.text = dataHandler!.topicList[indexPath.row].title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.performSegue(withIdentifier: "showContents", sender: dataHandler!.topicList[indexPath.row])
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
            let topic = sender as? DataHandler.Topic {
            
            vc.topic = topic
        }
    }

}
