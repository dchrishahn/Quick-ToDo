//
//  MasterViewController.swift
//  Quick-ToDo
//
//  Created by Chris Hahn on 4/11/18.
//  Copyright © 2018 Chris Hahn. All rights reserved.
//

import UIKit
import Foundation
import Firebase

class MasterViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    // ... Firebase ...
    private var databaseHandle: DatabaseHandle!
    var ref : DatabaseReference!
    var listsRef : DatabaseReference!
    
    //var lists = [List]()
    //var lists = List()
    var lists: [List] = []
    var listArray: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl?.addTarget(self, action: #selector(MasterViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData(_:)), name: NSNotification.Name(rawValue: "DataEntryViewControllerDidSaveData"), object: nil)
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        // ... Firebase ...
        ref = Database.database().reference()
        listsRef = Database.database().reference(withPath: "lists")
        fetchLists()
        
        //tableView.allowsSelectionDuringEditing = true         // ... to allow the selection of a cell, even in edit mode
        
    }
    
    @objc func reloadTableData(_ notification: Notification) {
        //fetchLists()
        self.tableView.reloadData()
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshControl?.addTarget(self, action: #selector(MasterViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        //fetchLists()
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        //return .fullScreen
        return .none
    }
    
    @IBAction func newListButton(_ sender: UIBarButtonItem) {
    
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "DataEntryController") as! UINavigationController
        
        let dataEntryController = viewController.viewControllers.last as! DataEntryController
        dataEntryController.delegate = self
        
        viewController.modalPresentationStyle = .popover
        let popover: UIPopoverPresentationController = viewController.popoverPresentationController!
        
        popover.barButtonItem = sender
        popover.delegate = self
        
        present(viewController, animated: true, completion:nil)
        
    }
    
    // MARK: - Segue to the DetailViewController
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let viewController = (segue.destination as! UINavigationController).topViewController as! DetailViewController
            let selectedIndexPath = tableView.indexPathForSelectedRow
            let list = lists[(selectedIndexPath?.row)!]
            viewController.list = list
        
        }
    }

    // MARK: - Table View settings ...
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let list = lists[indexPath.row]
        cell.textLabel?.text = list.name
        
        return cell
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let listObj = lists[fromIndexPath.row]
        lists.remove(at: fromIndexPath.row)
        lists.insert(listObj, at: to.row)
        
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            getAllKeys()
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when, execute: {
                self.listsRef?.child(self.listArray[indexPath.row]).removeValue()
                self.lists.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.listArray = []
            })
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    func getAllKeys() {
        listsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let key = snap.key
                self.listArray.append(key)
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
    
    
    
    // possible method to update or delete objects ... conflicts with segue to DetailVC when tapping on the cell
    /*
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let list = lists[indexPath.row]
        let alertController = UIAlertController(title:list.name, message:"Give new value to update list", preferredStyle:.alert)
        let updateAction = UIAlertAction(title: "Update", style:.default){(_) in
            let id = list.id
            let name = alertController.textFields?[0].text
            self.updateList(id: id!, name: name!)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addTextField{(textField) in
            textField.text = list.name
        }
        
        alertController.addAction(updateAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    // updateList called from didSelectRowAt popup
    
    func updateList(id: String, name: String) {
        let list = ["id": id, "name": name]
        listsRef.child(id).setValue(list)
            //labelMessage.text = "List updated"    // ... umm.. labelMessage not active??
        }
    
    */
        
    

    
}   // end of main class ................

// Extensions ...

extension MasterViewController: DataEntryControllerDelegate {
    func didAddNewData() {
        self.tableView.reloadData()
    }
}


extension MasterViewController {
    func fetchLists() {
        //let listsRef = Database.database().reference().child("lists")
        listsRef.observe(.childAdded, with: { (DataSnapshot) in
        //listsRef.observe(DataEventType.value, with: { (DataSnapshot) in       ... did not work
        //listsRef.observeSingleEvent(of: .value, with: { (DataSnapshot) in     ... did not work

            //if DataSnapshot.childrenCount > 0 {
                
                //self.lists.removeAll()
                
                if let dataValues = DataSnapshot.value as? [String: AnyObject] {
                    let list = List()
                    
                    list.id = (dataValues["id"] as? String)
                    list.name = (dataValues["name"] as? String)
                
                    self.lists.append(list)
                    self.tableView.reloadData()
                }
            
            //}
        })
    }
}

