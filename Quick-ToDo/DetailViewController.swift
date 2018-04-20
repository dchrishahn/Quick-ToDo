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
        
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        
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
    }
    
    // Add task descriptions via UIAlertController ...
    @IBAction func newTaskButton(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: "Add Task", message: "", preferredStyle: .alert)
        
        alertController.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
            textField.placeholder = "enter task description"
        })
        
        let confirmAction = UIAlertAction(title: "Save", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            if let taskName = alertController.textFields?[0].text {
                self.createTask(title: taskName)
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    func createTask(title: String) {                            // called from newTaskButton
        
        let parentId = self.list?.id
        let taskRef = Database.database().reference().child("lists").child(parentId!).child("tasks")
        
        let taskKey = taskRef.childByAutoId().key
        let taskRefbyKey = taskRef.child(taskKey)
        let newTaskVal = ["taskName": title, "tid":taskKey]
        taskRefbyKey.setValue(newTaskVal)
 
        self.tableView.reloadData()
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
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
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
        taskRef.observeSingleEvent(of: .value, with: { (snapshot) in
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
    
    // Override to support rearranging the table view.  in previous versions was moveRowAtIndexPath
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destIndexPath: IndexPath) {
        
        let taskObj = tasks[sourceIndexPath.row]
        tasks.remove(at: sourceIndexPath.row)
        tasks.insert(taskObj, at: destIndexPath.row)
    }
    
    // Override to support conditional rearranging of the table view.  in previous versions was canMoveRowAtIndexPath
    override func tableView(_ tableview: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        //fetchTasks()
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // method to update or delete objects ... both encountered errors in MasterVC
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     
        let task = tasks[indexPath.row]
        let alertController = UIAlertController(title:task.taskName, message:"Give new value to update list", preferredStyle:.alert)
    
        let updateAction = UIAlertAction(title: "Update", style:.default){(_) in
            let tid = task.tid
            let taskName = alertController.textFields?[0].text
            self.updateTask(tid: tid!, taskName: taskName!)
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
    
    func updateTask(tid: String, taskName: String) {            // updateTask called from didSelectRowAt popup
        let task = ["tid": tid, "taskName": taskName]
        taskRef.child(tid).setValue(task)
        self.tasks.removeAll()
        fetchTasks()
        self.tableView.reloadData()
        
        //labelMessage.text = "Task updated"    // ?? labelMessage not current or active??
        }
    
} // End of main class ........


// Extensions ......

extension DetailViewController {
    func fetchTasks() {
        let parentId = self.list?.id
        let taskRef = Database.database().reference().child("lists").child(parentId!).child("tasks")
        taskRef.observe(.childAdded, with: { (DataSnapshot) in
        //listsRef.child("tasks").observe(.childAdded, with: { (DataSnapshot) in
 
            
            if let dataValues = DataSnapshot.value as? [String: AnyObject] {
                let task = Task()
 
                task.tid = (dataValues["tid"] as? String)
                task.taskName = (dataValues["taskName"] as? String)
 
                self.tasks.append(task)
                self.tableView.reloadData()
                }
        })
    }
}

