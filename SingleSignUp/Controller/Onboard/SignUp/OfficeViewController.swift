//
//  OfficeViewController.swift
//  SingleSignUp
//
//  Created by Carlos Martin on 31/10/2017.
//  Copyright © 2017 Carlos Martin. All rights reserved.
//

import UIKit
import Firebase

class OfficeViewController: UITableViewController {

    var username: String?
    var email:    String?
    var officeId: String?
    
    var offices: [Office] = []
    
    var spinner : SpinnerLoader!
    
    // MARK: - View functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.spinner = SpinnerLoader(view: self.view)
        self.observeOffice()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "What's your Sigma Office?"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.offices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = self.tableView.dequeueReusableCell(withIdentifier: "selectOfficeCell", for: indexPath) as? OfficeViewCell {
            cell.officeNameLabel.text = self.offices[indexPath.row].name
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.officeId = self.offices[indexPath.row].id
        self.tableView.deselectRow(at: indexPath, animated: true)
        do {
            try Auth.auth().signOut()
            print("[OfficeViewController] Signed Out!")
        } catch {
            print("[OfficeViewController] Error Signing Out!")
        }
        performSegue(withIdentifier: "toPassword", sender: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPassword", let nextScene = segue.destination as? PasswordViewController {
            nextScene.username = self.username
            nextScene.email =    self.email
            nextScene.officeId = self.officeId
        }
    }
    
    // MARK: - Firebase
    func observeOffice() {
        self.spinner.start()
        Auth.auth().signIn(withEmail: ADMIN_NAME, password: ADMIN_PASS, completion: { (user: User?, error: Error?) in
            if let _ = error {
                let title = "Error"
                let message = "Oops! Something goes wrong. Try again later."
                Alert.showFailiureAlert(title: title, message: message, handler: nil)
                self.spinner.stop()
            } else {
                Tools.fetchAllOffices { (offices: [Office]) in
                    self.offices = offices
                    self.tableView.reloadData()
                    Tools.removeChannelObserver()
                    self.spinner.stop()
                }
            }
        })
    }
}
