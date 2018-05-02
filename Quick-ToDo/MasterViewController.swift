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

class MasterViewController: UITableViewController {
    
    // ... Firebase ...
    private var databaseHandle: DatabaseHandle!
    var ref : DatabaseReference!
    var listsRef : DatabaseReference!
    
    var lists: [List] = []
    var listArray: [String] = []
    var sortNum = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl?.addTarget(self, action: #selector(MasterViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData(_:)), name: NSNotification.Name(rawValue: "DataEntryViewControllerDidSaveData"), object: nil)
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        // ... Firebase ...
        ref = Database.database().reference()
        listsRef = Database.database().reference(withPath: "lists")
        
        fetchLists()
        
        // ... to allow the selection of a cell, even in edit mode
        tableView.allowsSelectionDuringEditing = true
        
        // clear empty cells at bottom of tableview
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    @objc func reloadTableData(_ notification: Notification) {
        self.tableView.reloadData()
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.tableView.reloadData()
        refreshControl.endRefreshing()
        print("........  MasterVC,  handleRefresh executed ..............")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshControl?.addTarget(self, action: #selector(MasterViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        //return .fullScreen
        return .none
    }
    
    @IBAction func newListButton(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: "Add List", message: "", preferredStyle: .alert)
        
        alertController.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
            textField.placeholder = "enter list description"
        })
        
        let confirmAction = UIAlertAction(title: "Save", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            if let name = alertController.textFields?[0].text {
                self.createList(title: name)
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
        
    }
    
    func createList(title: String) {                            // called from newListButton
     
        if !title.isEmpty {
        
            let listsRef = Database.database().reference().child("lists")
            let key = listsRef.childByAutoId().key
            let listsRefbyKey = listsRef.child(key)
     
            let newListVal = ["name": title, "id":key, "sortVal":sortNum] as [String : Any]
            listsRefbyKey.setValue(newListVal)
     
            updateSortVals()
        
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } else {
            showTextMessage()
        }
    }
    
    func updateSortVals() {
        var i = 0
        for listObj in lists {
            listObj.sortVal = i
            i = i + 1
        }
        let ref = Database.database().reference()
        for listObj in lists {
            let key = listObj.key
            let sortVal = String(listObj.sortVal!)
            ref.child("lists").child(key!).updateChildValues(["sortVal": sortVal])
        }
    }
    
    func showTextMessage() {
        let alertController = UIAlertController(title: "Data required", message: "Save button not allowed with blank data. Tap new list again and insure data is entered before tapping save.", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Close", style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
        
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

    // Override to support rearranging the table view. just tapping on the move bars in the view does this entire
    // moveRowAt which also calls the rearrangeFBLists and does an updateChildValues in Firebase
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        
        let listObj = lists[fromIndexPath.row]
        lists.remove(at: fromIndexPath.row)
        lists.insert(listObj, at: to.row)
        
        var i = 0
        for listObj in lists {
            listObj.sortVal = i
            i = i + 1
        }
        
        rearrangeFBLists()
    }
    
    func rearrangeFBLists() {
        let ref = Database.database().reference()
        for listObj in lists {
            let key = listObj.key
            let sortVal = String(listObj.sortVal!)
            ref.child("lists").child(key!).updateChildValues(["sortVal": sortVal])
        }
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        
        updateSortVals()
        
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
        
        let sortValRef = ref.child("lists").queryOrdered(byChild: "sortVal")  //...get keys by sortVal
        sortValRef.observeSingleEvent(of: .value, with: { (snapshot) in       //...get keys by sortVal
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
            self.navigationItem.rightBarButtonItem!.isEnabled = false
        } else {
            tableView.setEditing(false, animated: true)
            self.navigationItem.rightBarButtonItem!.isEnabled = true
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     
        if tableView.isEditing {
     
            let list = lists[indexPath.row]
            let alertController = UIAlertController(title:list.name, message:"Give new value to update list", preferredStyle:.alert)
            
            let updateAction = UIAlertAction(title: "Update", style:.default){(_) in
                let key = list.key
                let name = alertController.textFields?[0].text
                
                self.updateList(key: key!,name: name!)
            }
        
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
            alertController.addTextField{(textField) in
                textField.text = list.name
            }
        
            alertController.addAction(updateAction)
            alertController.addAction(cancelAction)
        
            present(alertController, animated: true, completion: nil)
            
     
        } else {
            performSegue(withIdentifier: "showDetail", sender: nil)
        }
    
    }
    
    
    // updateList called from didSelectRowAt popup
    
    func updateList(key: String, name: String) {
        listsRef.child(key).updateChildValues(["name": name])
        
        updateSortVals()
        
        DispatchQueue.main.async {
            //self.lists.removeAll()              // these two statements do a refresh to show changes
            //self.fetchLists()                   // but later show multiple entries when creating a new item
            self.tableView.reloadData()
        }
    }
    
    
}   // end of main class ................

// Extensions ...
/*
extension MasterViewController: DataEntryControllerDelegate {
    func didAddNewData() {
    }
}
*/

extension MasterViewController {
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
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    //self.tableView.reloadData()
                }
                //self.tableView.reloadData()
            //}
        })
    }
}

extension MasterViewController {
    func fetchListsByName() {
        let nameSort = ref.child("lists").queryOrdered(byChild: "name")     // ... added for name sorting
        nameSort.observe(.childAdded, with: { (DataSnapshot) in             // ... changed for name sorting
            
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
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                //self.tableView.reloadData()
            }
            //self.tableView.reloadData()
            //}
        })
    }
}
