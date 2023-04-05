/*
 * Copyright (C) 2023 Recompile.me.
 * All rights reserved.
 */

import UIKit
//import WebRTC

class LANDeviceSearchVC: UITableViewController, MMLANScannerDelegate {
    
    var lanScanner : MMLANScanner?
    private var viewReloadTimer: Timer?;
    var lanDeviceList = Set<MMDevice>();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //lanScanner?.delegate = self;
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            lanScanner = MMLANScanner(delegate:self);
            lanScanner?.start();
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        viewReloadTimer = Timer.scheduledTimer(timeInterval: 1,
                                               target: self,
                                             selector: #selector(reloadCells),
                                             userInfo: nil,
                                               repeats: true);
    }
    
    @objc private func reloadCells() {
        //if BLECommunicator.deviceList.isEmpty
        tableView.reloadData();
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return lanDeviceList.count;
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if lanDeviceList.isEmpty {
            log.info("The LAN device list is empty!!!");
            //Print this in the caption of the TableView
            return UITableViewCell();
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCell", for: indexPath);
            let peripherals = Array(lanDeviceList);
            let peripheral = peripherals[indexPath.row];
            cell.textLabel?.text = peripheral.hostname;
            cell.detailTextLabel?.text = "\(peripheral.ipAddress)";
            return cell
        }
    }
    

    //Refreshing the device table list HERE!!!
    @IBAction func refreshDeviceTable(_ sender: UIRefreshControl) {
        //Every time on refreshing the table, clear the cells!!!
        lanScanner?.stop();
        lanDeviceList.removeAll();
        sender.endRefreshing();
        lanScanner?.start();
    }
    func lanScanDidFindNewDevice(_ device: MMDevice!) {
        lanDeviceList.insert(device);
        let description = """
        Device brand: \(device.brand)
        Device hostname: \(device.hostname)
        Device ip address: \(device.ipAddress)
        Device mac address: \(device.macAddress)
        Device subnet mask: \(device.subnetMask)
        """
        log.info(description);
        
    }
    
    func lanScanDidFinishScanning(with status: MMLanScannerStatus) {
        log.info(status)
    }
    
    func lanScanDidFailedToScan() {
        log.info("Failed to scan")
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

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
