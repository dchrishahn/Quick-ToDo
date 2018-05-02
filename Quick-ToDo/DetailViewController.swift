//
//  DetailViewController.swift
//  Quick-ToDo
//
//  Created by Chris Hahn on 4/11/18.
//  Copyright © 2018 Chris Hahn. All rights reserved.
//

import UIKit
import Foundation
import Firebase

class DetailViewController: UITableViewController {
    
    // ... Firebase ...
    private var databaseHandle: DatabaseHandle!
    var ref : DatabaseReference!
    var listsRef : DatabaseReference!
    var taskRef : DatabaseReference!
    
    var list: List?
    var tasks: [Task] = []
    var taskArray: [String] = []
    var sortNum = 0
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshControl?.addTarget(self, action: #selector(DetailViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl?.addTarget(self, action: #selector(DetailViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
        
        self.clearsSelectionOnViewWillAppear = false
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // show detail data on iPad in either portrait or landscape mode
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        
        // clear empty cells at bottom of tableview
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        if let detailList = self.list{
            navigationItem.title = detailList.name
        }
        
        // ... Firebase
        ref = Database.database().reference()
        let pId = self.list?.id
        if pId != nil {
            taskRef = Database.database().reference().child("lists").child((pId)!).child("tasks")
            fetchTasks()
            } else {
            }
        
        //to allow the selection of a cell, even in edit mode
        tableView.allowsSelectionDuringEditing = true
    
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        //self.tasks.removeAll()
        //fetchTasks()
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    // Add task descriptions via UIAlertController ...
    @IBAction func newTaskButton(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: "Add Task", message: "", preferredStyle: .alert)
        
        alertController.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
            textField.placeholder = "enter task description"
        })
        alertController.addTextField(configurationHandler: {(_ dateField: UITextField) -> Void in
            dateField.placeholder = "enter due date"
        })
        
        let confirmAction = UIAlertAction(title: "Save", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            /*
            if let taskName = alertController.textFields?[0].text {
                self.createTask(title: taskName)
            }
            */
            let taskName = alertController.textFields?[0].text
            let taskDate = alertController.textFields?[1].text
            self.createTask(title: taskName!, subtitle: taskDate!)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    func createTask(title: String, subtitle: String) {                            // called from newTaskButton
        
        if !title.isEmpty {
        
            let parentId = self.list?.id
        
            let taskRef = Database.database().reference().child("lists").child(parentId!).child("tasks")
            let taskKey = taskRef.childByAutoId().key
            let taskRefbyKey = taskRef.child(taskKey)
        
            let newTaskVal = ["taskName": title, "taskDate": subtitle, "tid":taskKey, "tSortVal":sortNum] as [String : Any]
            taskRefbyKey.setValue(newTaskVal)
        
            updateTsortVals()
 
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } else {
            showTextMessage()
        }
    }

    func updateTsortVals() {
        var i = 0
        for taskObj in tasks {
            taskObj.tSortVal = i
            i = i + 1
        }
        let parentId = self.list?.id
        let ref = Database.database().reference().child("lists").child(parentId!)
        for taskObj in tasks {
            let key = taskObj.key
            let tSortVal = String(taskObj.tSortVal!)
            ref.child("tasks").child(key!).updateChildValues(["tSortVal": tSortVal])
        }
    }
    
    func showTextMessage() {
        let alertController = UIAlertController(title: "Data required", message: "Save button not allowed with blank data. Tap new task again and insure data is entered before tapping save.", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Close", style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
        
    }
    
    // MARK: - Table View settings ...
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return list?.tasks.count ?? 0
        return tasks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellTwo", for: indexPath)
        let task = tasks[indexPath.row]
        cell.textLabel?.text = task.taskName
        cell.detailTextLabel?.text = task.taskDate
        
        return cell
    }
    
    // Override to support rearranging the table view.  in previous versions was moveRowAtIndexPath
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destIndexPath: IndexPath) {
        let taskObj = tasks[sourceIndexPath.row]
        tasks.remove(at: sourceIndexPath.row)
        tasks.insert(taskObj, at: destIndexPath.row)
        
        var i = 0
        for taskObj in tasks {
            taskObj.tSortVal = i
            i = i + 1
        }
        
        rearrangeFBTasks()
    }
    
    func rearrangeFBTasks() {
        let parentId = self.list?.id
        let ref = Database.database().reference().child("lists").child(parentId!)
        for taskObj in tasks {
            let key = taskObj.key
            let tSortVal = String(taskObj.tSortVal!)
            ref.child("tasks").child(key!).updateChildValues(["tSortVal": tSortVal])
        }
    }
    
    // Override to support conditional rearranging of the table view.  in previous versions was canMoveRowAtIndexPath
    override func tableView(_ tableview: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        updateTsortVals()
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            getAllKeys()
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when, execute: {
                self.taskRef?.child(self.taskArray[indexPath.row]).removeValue()
                self.tasks.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.taskArray = []
            })
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    func getAllKeys() {
        let parentId = self.list?.id
        let tSortVal = Database.database().reference().child("lists").child(parentId!).child("tasks").queryOrdered(byChild: "tSortVal")
        tSortVal.observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let key = snap.key
                self.taskArray.append(key)
            }
        })
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            tableView.setEditing(true, animated: true)
        } else {
            tableView.setEditing(false, animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // method to update or delete objects ... both encountered errors in MasterVC
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     
        let task = tasks[indexPath.row]
        let alertController = UIAlertController(title:task.taskName, message:"Give new value to update task", preferredStyle:.alert)
    
        let updateAction = UIAlertAction(title: "Update", style:.default){(_) in
            let key = task.key
            let taskName = alertController.textFields?[0].text
            self.updateTask(key: key!, taskName: taskName!)
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addTextField{(textField) in
            textField.text = task.taskName
        }
     
        alertController.addAction(updateAction)
        alertController.addAction(cancelAction)
     
        present(alertController, animated: true, completion: nil)
        
        self.tableView.reloadData()
    }
    

    func updateTask(key: String, taskName: String) {
        taskRef.child(key).updateChildValues(["taskName": taskName])
        
        updateTsortVals()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
    }
    
} // End of main class ........


// Extensions ......

extension DetailViewController {
    func fetchTasks() {
        let parentId = self.list?.id
        let tSortValRef = Database.database().reference().child("lists").child(parentId!).child("tasks").queryOrdered(byChild: "tSortVal")     // ... sort by tSortVal
        tSortValRef.observe(.childAdded, with: { (DataSnapshot) in                                                                             // ... sort by tSortVal
            
            if let dataValues = DataSnapshot.value as? [String: AnyObject] {
                let key = DataSnapshot.key
                let task = Task()
 
                task.tid = (dataValues["tid"] as? String)
                task.taskDate = (dataValues["taskDate"] as? String)
                task.taskName = (dataValues["taskName"] as? String)
                task.tSortVal = (dataValues["tSortVal"] as? Int)
                task.key = key
                
                self.tasks.append(task)
                //self.tableView.reloadData()
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            self.tableView.reloadData()
        })
    }
}

/*
extension MasterViewController {
    func fetchLists() {
        let sortValRef = ref.child("lists").queryOrdered(byChild: "sortVal")  // ... for sort change
        sortValRef.observe(.childAdded, with: { (DataSnapshot) in             // ... for sort change

            if let dataValues = DataSnapshot.value as? [String: AnyObject] {
                let key = DataSnapshot.key
                let list = List()
 
                list.id = (dataValues["id"] as? String)
                list.name = (dataValues["name"] as? String)
                list.sortVal = (dataValues["sortVal"] as? Int)
                list.key = key
 
                self.lists.append(list)
 
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
    }
 }
 
*/
