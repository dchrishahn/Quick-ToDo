//
//  TodayViewController.swift
//  Quick-ToDoExtension
//
//  Created by Chris Hahn on 5/1/18.
//  Copyright © 2018 Chris Hahn. All rights reserved.
//

import UIKit
import NotificationCenter
import Firebase

class TodayViewController: UITableViewController, NCWidgetProviding {
    
    private var databaseHandle: DatabaseHandle!
    var ref : DatabaseReference!
    var listsRef : DatabaseReference!
    
    var list: List?
    var task: Task?
    var lists: [List] = []
    var tasks: [Task] = []
    var listArray: [String] = []
    var sortNum = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // to show "more" in widget screen to expand
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        
        FirebaseApp.configure()
        
        ref = Database.database().reference()
        listsRef = Database.database().reference(withPath: "lists")
        
        fetchLists()
        
        let whatisToday = self.formattedDate()
        print("...what is the formatted date before the task sortval statement ....")
        print(whatisToday)
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    // MARK: - Table View settings ...
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        print(" ... cell for row at initiated, printing value for list.name .......")
        //print("")
        //let list = lists[indexPath.row]
        let task = tasks[indexPath.row]
        
        //cell.textLabel?.text = list.name
        cell.textLabel?.text = task.taskName
        //print(list.name as Any)
        return cell
    }
    
    // function to adjust size of widget screen when expanded
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            self.preferredContentSize = maxSize
        } else if activeDisplayMode == .expanded {
            self.preferredContentSize = CGSize(width: maxSize.width, height: 320)
        }
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    /*
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    */
    
} // end of main class

// Extension

extension TodayViewController {
    func fetchLists() {
        let sortValRef = ref.child("lists").queryOrdered(byChild: "sortVal")  // ... for sort change
        sortValRef.observe(.childAdded, with: { (DataSnapshot) in             // ... for sort change
            //if DataSnapshot.childrenCount > 0 {
            
            //self.lists.removeAll()
            
            if let dataValues = DataSnapshot.value as? [String: AnyObject] {
                let key = DataSnapshot.key
                let list = List()
                
                list.id = (dataValues["id"] as? String)
                list.name = (dataValues["name"] as? String)
                list.sortVal = (dataValues["sortVal"] as? Int)
                list.key = key
                
                self.lists.append(list)
                print("...print name from the fetchList extension")
                print(list.name as Any)
                print("")
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
                let pKey = list.key
                let todayDate = self.formattedDate()
                //let tSortValRef = Database.database().reference().child("lists").child(pKey!).child("tasks").queryOrdered(byChild: "tSortVal")
                let tSortValRef = Database.database().reference().child("lists").child(pKey!).child("tasks").queryOrdered(byChild: "taskDate").queryEqual(toValue: todayDate)
                tSortValRef.observe(.childAdded, with: { (DataSnapshot) in
                    if let dataValues = DataSnapshot.value as? [String: AnyObject] {
                        let tkey = DataSnapshot.key
                        let task = Task()
                        
                        task.tid = (dataValues["tid"] as? String)
                        task.taskDate = (dataValues["taskDate"] as? String)
                        task.taskName = (dataValues["taskName"] as? String)
                        task.tSortVal = (dataValues["tSortVal"] as? Int)
                        task.key = tkey
                        
                        self.tasks.append(task)
                        //self.tableView.reloadData()
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                        print("............ task value buried in fetchlists ...")
                        print(task.taskName as Any)
                    }
                })
                
            }
            //self.tableView.reloadData()
            //}
        })
    }
}

extension TodayViewController {
    func formattedDate() -> String {
        let date = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        dateFormatter.dateStyle = .short
        return dateFormatter.string(from: date as Date)
    }
}
