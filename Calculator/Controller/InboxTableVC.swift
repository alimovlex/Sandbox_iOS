/*
 * Copyright (C) 2023 Recompile.me.
 * All rights reserved.
 */

import UIKit
import MailCore

class InboxTableVC: UITableViewController {
    
    var mailMessagesArray = Array<MCOIMAPMessage>();
    let session = MCOIMAPSession();
    var mailFoldersArray = Array<MCOIMAPFolder>();
    let inboxFolder = "INBOX";
    let uids = MCOIndexSet(range: MCORange(location: 1, length: UInt64.max));
    
    override func viewDidLoad() {
        super.viewDidLoad()
        session.hostname = mailServerHostname
        session.port = UInt32(imapPort);
        session.username = mailLogin;
        session.password = mailPassword;
        session.connectionType = .TLS;
        connect(hostname: session.hostname, port: session.port, username: session.username, password: session.password, connectionType: session.connectionType);
    }
    
    func connect(hostname: String, port: UInt32, username: String, password: String, connectionType: MCOConnectionType) {
        
        if let accountCheck = session.checkAccountOperation() {
            accountCheck.start { err in
                if let error = err {
                    log.error(error.localizedDescription);
                    self.displayErrorMessage(error: error.localizedDescription);
                } else {
                    log.info("Successful IMAP connection!");
                    self.listAvailableFolders();
                }
            }
        }
    }
    
    func listAvailableFolders() {
        if let fetchFoldersOperation = session.fetchAllFoldersOperation() {
            fetchFoldersOperation.start { err, folderList in
                if let error = err {
                    log.error(error.localizedDescription);
                    self.displayErrorMessage(error: error.localizedDescription);
                }
                
                if let folders = folderList {
                    // log.info("Listed all IMAP Folders: \(folders.debugDescription)");
                    self.mailFoldersArray = folders;
                    for folder in self.mailFoldersArray {
                        log.info(folder.path)
                        if folder.path == self.inboxFolder {
                            self.fetchMessageHeadersFromFolder(folder: folder.path, uids: self.uids);
                        }
                    }
                }
                
            }
            
        }
    }
    
    func fetchMessageHeadersFromFolder(folder: String, uids: MCOIndexSet?) {
        
        if let fetchOperation = session.fetchMessagesOperation(withFolder: folder, requestKind: .headers, uids: uids) {
            fetchOperation.start { err, fetchedMessages, vanishedMessages in
                if let error = err {
                    log.error("Error downloading message headers: \(error.localizedDescription)");
                    self.displayErrorMessage(error: error.localizedDescription);
                } else {
                    if let inboxMessages = fetchedMessages {
                        print("The post man delivered: \(fetchedMessages.debugDescription)");
                        self.mailMessagesArray = inboxMessages;
                        self.tableView.reloadData();
                    } else {
                        log.warning("The Inbox mail folder is empty!!!");
                    }
                    
                }
            }
        }
        
    }
    
    func displayErrorMessage(error: String) {
        let error = UIAlertController(title: "Error fetching messages from the mail server.", message: error, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "Ok", style: .default);
        error.addAction(confirm);
        self.present(error, animated: true) //showing the URL entrance message
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return mailMessagesArray.count;
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if mailMessagesArray.isEmpty {
            log.warning("The Inbox folder is empty!!!");
            //Print this in the caption of the TableView
            return UITableViewCell();
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mailCell", for: indexPath);
            let message = mailMessagesArray.reversed()[indexPath.row];
            cell.textLabel?.text = message.header.subject.description;
            cell.detailTextLabel?.text = message.header.sender.mailbox;
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = mailMessagesArray[indexPath.row];
        performSegue(withIdentifier: "MessageContentsVC", sender: message.uid);
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "MessageContentsVC" {
            if let destination = segue.destination as? MailContentsVC, let messageId = sender as? UInt32 {
                for mailFolder in mailFoldersArray where mailFolder.path == inboxFolder {
                    destination.useImapFetchContent(session: self.session, folder: mailFolder, uidToFetch: messageId);
                }
                //log.info(sender.debugDescription);
            } else {
                log.warning("The UI sender with messageId is nil");
                self.displayErrorMessage(error: "The UI sender with messageId is nil");
            }
            
        }
    }
    
    @IBAction func refreshInboxTable(_ sender: UIRefreshControl) {
        
        mailMessagesArray.removeAll();
        sender.endRefreshing();
        connect(hostname: session.hostname, port: session.port, username: session.username, password: session.password, connectionType: session.connectionType);
        
    }
    
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
