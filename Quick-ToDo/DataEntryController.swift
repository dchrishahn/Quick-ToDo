//
//  DataEntryController.swift
//  Quick-ToDo
//
//  Created by Chris Hahn on 4/11/18.
//  Copyright © 2018 Chris Hahn. All rights reserved.
//
//  Popover presentation controller to enter new list objects

import UIKit
import Foundation
import Firebase

protocol DataEntryControllerDelegate: class {
    func didAddNewData()
}

class DataEntryController: UIViewController, UITableViewDelegate, UIPopoverPresentationControllerDelegate {

    private var databaseHandle: DatabaseHandle!
    var ref : DatabaseReference!
    
    var delegate: DataEntryControllerDelegate?
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        //return .fullScreen
        return .none
    }
    
    @IBOutlet weak var listTitleInputField: UITextField!
    
    var lists = [List]()
    var listTitleValue = ""
    
    @IBAction func saveData(_ sender: Any) {
    
        if let listTitleValue = listTitleInputField.text, !listTitleValue.isEmpty {
     
            if let delegate = delegate {
                delegate.didAddNewData()
            }
            
            NSLog("Writing to db ...")
            
            let listsRef = Database.database().reference().child("lists")
            let key = listsRef.childByAutoId().key              // ... gen random keyval for new list
            let listsRefbyKey = listsRef.child(key)             // ... create new child holder based off of previous key
            let newListVal = ["name":listTitleValue, "id":key]  // ... create val for new child list from entered title and key
            
            //listsRef.childByAutoId().setValue(listTitleValue) // ... this results in the key followed by the entered value without
                                                                // ... the next layer of "name"; so keyvalue: newly entered text
            //listsRef.child(key).setValue(newListVal)
            listsRefbyKey.setValue(newListVal)                  // ... create the new fb entry from previous definition of the newListVal
            
            /*  ... use this for the tasks ??????????????
            let newRef = listsRefbyKey.child(key)
            let newKey = newRef.childByAutoId().key
            let newTaskVal = ["taskName": "", "tid":newKey]
            newRef.setValue(newTaskVal)
            */
            
            //let newTasksVal = listsRef.child(key).setValue(newListVal)
            //let tasksRef = listsRef.child(newTasksVal)
            
            NSLog("Reading from db ...")
            
            listsRef.child(key).observe(DataEventType.value, with: { (DataSnapshot) in
            //listsRef.observe(DataEventType.value, with: { (DataSnapshot) in
                print("key is  ... ")
                print(key)
                print("datasnapshot is ...")
                print(DataSnapshot)
            })
            
            /*
            listsRefbyKey.updateChildValues(newListVal, withCompletionBlock: {
                (err, reff) in
                if err != nil {
                    print(err ?? "no error print")
                    return
                }
            })
            */
            
            ClearText()
     
        } else {
     
            showTextMessage()
     
        }
 
    }
    
    func showTextMessage() {
        let alertController = UIAlertController(title: "Data required", message: "All fields require data entry before saving is permitted", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Close", style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
        
    }
    
    func ClearText() {
        listTitleInputField.text = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    

}
