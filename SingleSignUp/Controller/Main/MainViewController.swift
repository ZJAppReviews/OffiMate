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
    
    var firstAccess: Bool = true
    
    var senderDisplayName:  String?
    var newChannel:         Channel?
    var newChannelButton:   UIButton?
    var newChannelIsHide:   Bool = true
    var lastContentOffset:  CGFloat = 0
    
    var stopLoading: Bool! {
        didSet {
            if self.firstAccess {
                if self.stopLoading! {
                    self.spinnerView.isHidden = true
                    self.spinnerView.stopAnimating()
                } else {
                    self.spinnerView.isHidden = false
                    self.spinnerView.startAnimating()
                }
            } else {
                if self.stopLoading! { self.spinner?.stop() } else { self.spinner?.start() }
            }
        }
    }
    
    var startLoading: Bool! {
        set { self.stopLoading = (newValue != nil ? !(newValue!) : true) }
        get { return !(self.stopLoading!) }
    }
    
    //UI
    var spinner: SpinnerLoader?
    @IBOutlet weak var emptyChannelsLabel: UILabel!
    @IBOutlet weak var spinnerView: UIActivityIndicatorView!
    
    //Firebase variables
    private lazy var channelRef:        DatabaseReference = Database.database().reference().child("channels")
    private      var channelRefHandle:  DatabaseHandle?
    private      var messageRefHandle:  DatabaseHandle?
    private      var deletedRefHandle:  DatabaseHandle?
    
    override func viewDidLoad() {
        self.initUI()
        self.observeChannels()
        self.observeChannelsChanges()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.spinner == nil {
            self.spinner = SpinnerLoader(view: self.navigationController!.view, alpha: 0.1)
        }
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.spinner = nil
        self.firstAccess = false
    }
    
    deinit {
        if let refChannelHandle = channelRefHandle {
            channelRef.removeObserver(withHandle: refChannelHandle)
        }
        if let refMessageHandle = messageRefHandle {
            channelRef.removeObserver(withHandle: refMessageHandle)
        }
        if let refDeletedHandle = deletedRefHandle {
            channelRef.removeObserver(withHandle: refDeletedHandle)
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
        self.firstAccess = true
        
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
        self.emptyChannelsLabel.isHidden = true
        self.spinner = SpinnerLoader(view: self.navigationController!.view, alpha: 0.1)
    }
    
    //MARK:- Firebase related methods
    
    private func observeChannels() {
        self.startLoading = true
        self.channelRefHandle = channelRef.observe(.childAdded, with: { (snapshot: DataSnapshot) in
            self.stopLoading = true
            if let channelData = snapshot.value as? Dictionary<String, AnyObject> {
                let id = snapshot.key
                if let name = channelData["name"] as! String!, let creator = channelData["creator"] as! String! {
                    let channel: Channel
                    if let messages = channelData["messages"] as! Dictionary<String, AnyObject>! {
                        channel = Channel(id: id, name: name, creator: creator, messages: messages)
                    } else {
                        channel = Channel(id: id, name: name, creator: creator)
                    }
                    if self.getChannelIndex(channel: channel) == nil {
                        CurrentUser.addChannel(channel: channel)
                        self.tableView.reloadData()
                    }
                }
            }
        })
        
        channelRef.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            if snapshot.childrenCount == 0 {
                self.stopLoading = true
                self.emptyChannelsLabel.isHidden = (self.emptyChannelsLabel.isHidden ? false : true)
            }
        }
    }
    
    private func observeChannelsChanges() {
        self.messageRefHandle = channelRef.observe(.childChanged, with: { (snapshot: DataSnapshot) in
            if let channelData = snapshot.value as? Dictionary<String, AnyObject> {
                let id = snapshot.key
                if let name = channelData["name"] as! String!, let creator = channelData["creator"] as! String!, let messages = channelData["messages"] as! Dictionary<String, AnyObject>! {
                    let channel = Channel(id: id, name: name, creator: creator, messages: messages)
                    if let index = self.getChannelIndex(channel: channel) {
                        if CurrentUser.channels[index].messages.count != messages.count {
                            CurrentUser.updateChannel(channel: channel)
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        })
        
        self.deletedRefHandle = channelRef.observe(.childRemoved, with: { (snapshot: DataSnapshot) in
            if let channelData = snapshot.value as? Dictionary<String, AnyObject> {
                let id = snapshot.key
                if let name = channelData["name"] as! String!, let creator = channelData["creator"] as! String! {
                    let channel = Channel(id: id, name: name, creator: creator)
                    if let index = self.getChannelIndex(channel: channel) {
                        let indexPath = IndexPath(row: index, section: MainSection.currentChannel.rawValue)
                        self.removeChannel(indexPath: indexPath)
                    }
                }
            }
        })
    }
    
    private func getChannelIndex (channel: Channel) -> Int? {
        var index: Int = 0
        var fond: Bool = false
        for i in CurrentUser.channels {
            if i.id == channel.id {
                fond = true
                break
            }
            index += 1
        }
        if fond {
            return index
        } else {
            return nil
        }
    }
    
    func createChannelFB(_ sender: UITextField) {
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
    
    func deleteChannelFB(_ sender: Channel, completion: @escaping (_ error: Error?) -> Void) {
        let toRemoveChannelRef = channelRef.child(sender.id)
        //print(toRemoveChannelRef)
        toRemoveChannelRef.removeValue { (error: Error?, ref: DatabaseReference) in
            completion(error)
        }
    }
    
    func removeChannel(indexPath: IndexPath) {
        if indexPath.row < CurrentUser.channels.count {
            CurrentUser.removeChannel(index: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.left)
            self.tableView.reloadData()
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
                let channel = CurrentUser.channels[indexPath.row]
                //channel.num = CurrentUser.channelsCounter[indexPath.row]
                controller.channel = channel
                controller.channelRef = channelRef.child(channel.id)
                controller.totalMessages = channel.messages.count
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
                return CurrentUser.channels.count
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
                return (CurrentUser.channels.isEmpty ? 0.1 : 30.0)
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
                return (CurrentUser.channels.isEmpty ? nil : "Channels")
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
                let channel = CurrentUser.channels[indexPath.row]
                let lastAccess = CurrentUser.channelsLastAccess[indexPath.row]
                cell?.label.text = channel.name
                
                let counter = channel.getUnread(from: lastAccess)
                //print("[\(indexPath.row)]: \(counter)")
                if counter == 0 {
                    cell?.counter.isHidden = true
                } else {
                    cell?.counter.isHidden = false
                    cell?.counter.text = String(counter)
                    cell?.counter.textColor = UIColor.white
                    cell?.counter.layer.backgroundColor = UIColor.red.cgColor
                    cell?.counter.layer.cornerRadius = 9
                    cell?.counter.layer.borderWidth = 0.5
                    cell?.counter.layer.borderColor = UIColor.white.cgColor
                }
                
                
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
                if CurrentUser.channels[row].creator == CurrentUser.user!.uid {
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
            let channel = CurrentUser.channels[indexPath.row]
            let title   = "Do you wanna continue?"
            let message = "You are gonna delete \"\(channel.name)\" channel"
            
            Alert.showAlertOptions(title: title, message: message, okAction: { (_) in
                self.deleteChannelFB(channel, completion: { (error: Error?) in
                    if error == nil {
                        self.removeChannel(indexPath: indexPath)
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
        self.createChannelFB(textField)
        self.view.endEditing(true)
        return true
    }
}
