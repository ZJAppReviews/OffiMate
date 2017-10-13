//
//  MainViewController.swift
//  SingleSignUp
//
//  Created by Carlos Martin on 21/08/17.
//  Copyright © 2017 Carlos Martin. All rights reserved.
//

import UIKit
import Firebase

enum MainSection: Int {
    case createNewChannel = 0
    case currentChannel
}

class MainViewController: UITableViewController {

    var channels:           [Channel] = []
    var senderDisplayName:  String?
    var spinner:            SpinnerLoader?
    var newChannel:         Channel?
    var newChannelButton:   UIButton?
    var newChannelIsHide:   Bool = true
    var lastContentOffset:  CGFloat = 0
    
    var stopLoading: Bool! {
        didSet {
            if self.stopLoading! { self.spinner?.stop() } else { self.spinner?.start() }
        }
    }
    
    var startLoading: Bool! {
        set { self.stopLoading = (newValue != nil ? !(newValue!) : true) }
        get { return !(self.stopLoading!) }
    }
    
    @IBOutlet weak var emptyChannelsLabel: UILabel!
    
    //Firebase variables
    private lazy var channelRef:        DatabaseReference = Database.database().reference().child("channels")
    private      var channelRefHandle:  DatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initUI()
        self.observeChannels()
    }
    
    deinit {
        if let refHandle = channelRefHandle {
            channelRef.removeObserver(withHandle: refHandle)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let split = self.splitViewController {
            self.clearsSelectionOnViewWillAppear = split.isCollapsed
        }
        super.viewWillAppear(animated)
        
        var counter = channels.count
        if counter > 0 {
            //self.spinner?.start()
            self.startLoading = true
            for i in channels {
                self.updateCounter(i, completion: { (num: Int) in
                    i.num = num
                    counter -= 1
                    if counter == 0 {
                        self.tableView.reloadData()
                        //self.spinner?.stop()
                        self.stopLoading = true
                    }
                })
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func onboardActionButton(_ sender: Any) {
        Tools.goToProfile(vc: self)
    }
    
    func menuActionButton(_ sender: Any) {
        guard let vc = UIStoryboard(name: "Coworkers", bundle: nil).instantiateViewController(withIdentifier: "Coworkers") as? CoworkersViewController else {
            let message = "Could not instantiate view controller with identifier of type CoworkersViewController"
            Alert.showFailiureAlert(message: message)
            return
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK:- Init and Fetching Data Functions
    
    private func initUI() {
        let profileButton = UIBarButtonItem(
            image: UIImage(named: "user"),
            style: .plain,
            target: self,
            action: #selector(onboardActionButton(_:)))
        
        let menuButton = UIBarButtonItem(
            image: UIImage(named: "coworkers"),
            style: .plain,
            target: self,
            action: #selector(menuActionButton(_:)))
        
        self.navigationItem.rightBarButtonItem = menuButton
        self.navigationItem.leftBarButtonItem = profileButton
        self.navigationItem.title = "OffiMate"
        self.spinner = SpinnerLoader(view: self.view)//self.splitViewController!.view)
        self.emptyChannelsLabel.isHidden = true
    }
    
    //MARK:- Firebase related methods
    
    private func observeChannels() {
        //self.spinner?.start()
        self.startLoading = true
        channelRefHandle = channelRef.observe(.childAdded, with: { (snapshot: DataSnapshot) in
            //self.spinner?.stop()
            self.stopLoading = true
            if let channelData = snapshot.value as? Dictionary<String, AnyObject> {
                let id = snapshot.key
                if let name = channelData["name"] as! String!, let creator = channelData["creator"] as! String!, name.characters.count > 0 {
                    let channel = Channel(id: id, name: name, creator: creator)
                    self.updateCounter(channel, completion: { (counter: Int) in
                        channel.num = counter
                        self.channels.append(channel)
                        self.tableView.reloadData()
                    })
                }
            }
        })
        channelRef.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            if snapshot.childrenCount == 0 {
                //self.spinner?.stop()
                self.stopLoading = true
                self.emptyChannelsLabel.isHidden = (self.emptyChannelsLabel.isHidden ? false : true)
            }
        }
    }
    
    private func updateCounter(_ channel: Channel, completion: @escaping (_ num: Int) -> Void) {
        self.channelRef.child(channel.id).child("messages").observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            completion(Int(snapshot.childrenCount))
        }
    }
    
    func createChannel(_ sender: UITextField) {
        if !(sender.text!.isEmpty) {
            let name = sender.text!
            let newChannelRef = channelRef.childByAutoId()
            let channelItem = [
                "name":     name,
                "creator":  CurrentUser.user!.uid
            ]
            newChannelRef.setValue(channelItem)
            sender.text! = ""
        } else {
            Tools.textFieldErrorAnimation(textField: sender)
        }
    }
    
    func deleteChannel(_ sender: Channel, completion: @escaping (_ error: Error?) -> Void) {
        let toRemoveChannelRef = channelRef.child(sender.id)
        print(toRemoveChannelRef)
        toRemoveChannelRef.removeValue { (error: Error?, ref: DatabaseReference) in
            completion(error)
        }
    }
    
    //MARK:- Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                var controller: ChatViewController
                if let navigationController = segue.destination as? UINavigationController {
                    controller = navigationController.topViewController as! ChatViewController
                } else {
                    controller = segue.destination as! ChatViewController
                }
                let channel = self.channels[indexPath.row]
                controller.channel = channel
                controller.channelRef = channelRef.child(channel.id)
                controller.auto = false
                controller.totalMessages = channel.num
            }
        }
    }
    
    //MARK:- Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let currentSection: MainSection = MainSection(rawValue: section) {
            switch currentSection {
            case .createNewChannel:
                return (self.newChannelIsHide ? 0 : 1)
            case .currentChannel:
                return self.channels.count
            }
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let currentSection: MainSection = MainSection(rawValue: section) {
            switch currentSection {
            case .createNewChannel:
                return 0.1
            case .currentChannel:
                return (self.channels.isEmpty ? 0.1 : 30.0)
            }
        } else {
            return 0.1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let currentSection: MainSection = MainSection(rawValue: section) {
            switch currentSection {
            case .createNewChannel:
                return nil
            case .currentChannel:
                return (self.channels.isEmpty ? nil : "Channels")
            }
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let currentSection: MainSection = MainSection(rawValue: indexPath.section) {
            switch currentSection {
            case .createNewChannel:
                let cell = self.tableView.dequeueReusableCell(withIdentifier: "NewChannelCell", for: indexPath) as? NewChannelViewCell
                cell?.newChannelTextField.delegate = self
                cell?.newChannelTextField.placeholder = "Create a New Channel"
                cell?.selectionStyle = .none
                return cell!
            case .currentChannel:
                let cell = self.tableView.dequeueReusableCell(withIdentifier: "MainCell", for: indexPath) as? MainViewCell
                let channel = self.channels[indexPath.row]
                cell?.label.text = channel.name
                cell?.counter.text = String(channel.num)
                cell?.counter.textColor = UIColor.lightGray
                cell?.counter.layer.backgroundColor = UIColor.white.cgColor
                cell?.counter.layer.cornerRadius = 9
                cell?.counter.layer.borderWidth = 0.5
                cell?.counter.layer.borderColor = UIColor.lightGray.cgColor

                return cell!
            }
        } else {
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let currentSection: MainSection = MainSection(rawValue: indexPath.section) {
            switch currentSection {
            case .createNewChannel:
                return false
            case .currentChannel:
                let row = indexPath.row
                if self.channels[row].creator == CurrentUser.user!.uid {
                    return true
                } else {
                    return false
                }
            }
        } else {
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let channel = self.channels[indexPath.row]
            let title   = "Do you wanna continue?"
            let message = "You are gonna delete \"\(channel.name)\" channel"
            
            Alert.showAlertOptions(title: title, message: message, okAction: { (_) in
                self.deleteChannel(channel, completion: { (error: Error?) in
                    if error == nil {
                        self.channels.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.left)
                        self.tableView.reloadData()
                    } else {
                        Alert.showFailiureAlert(error: error!)
                    }
                })
            }, cancelAction: { (_) in
                print("Deleting channel canceled")
            })
        }
    }
    
    //MARK:- ScrollView
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
        let actualPosition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if actualPosition.y > 0 && self.newChannelIsHide {
            // Dragging down
            self.newChannelIsHide = false
            self.tableView.reloadSections(IndexSet(integer: 0), with: .bottom)
            
        } else if actualPosition.y < 0 && !self.newChannelIsHide {
            // Dragging up
            self.newChannelIsHide = true
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            
        }
    }

}

extension MainViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //TODO: add action to create a channel
        self.createChannel(textField)
        self.view.endEditing(true)
        return true
    }
}
