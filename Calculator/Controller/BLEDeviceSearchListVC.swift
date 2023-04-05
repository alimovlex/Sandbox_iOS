/*
 * Copyright (C) 2023 Recompile.me.
 * All rights reserved.
 */

import UIKit
import CoreBluetooth

class BLEDeviceSearchListVC: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var viewReloadTimer: Timer?;
    var bleDeviceList = Set<CBPeripheral>();
    
    // The BLE antenna state manager.
    var centralManager: CBCentralManager?;
    
    // The BLE peripheral manager.
    var peripheral: CBPeripheral?;
    
    // The array of the peripherals' UUID services discovered.
    var servicesUuid = Array<CBUUID>();
    
    // The path for the saved file received over BLE
    private let filePath = NSHomeDirectory() + "/Documents/" + "video.bin";
    private let fileManager = FileManager.default;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        //tableView.reloadData();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        connect();
        
        viewReloadTimer = Timer.scheduledTimer(timeInterval: 1,
                                               target: self,
                                             selector: #selector(reloadCells),
                                             userInfo: nil,
                                               repeats: true);
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        viewReloadTimer?.invalidate();
        centralManager?.stopScan();
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
        return bleDeviceList.count;
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if bleDeviceList.isEmpty {
            log.warning("The BLE device list is empty!!!");
            //Print this in the caption of the TableView
            return UITableViewCell();
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCell", for: indexPath);
            let peripherals = Array(bleDeviceList);
            let peripheral = peripherals[indexPath.row];
            cell.textLabel?.text = peripheral.name;
            cell.detailTextLabel?.text = "\(peripheral.identifier)";
            // Configure the cell...
            if indexPath == selectedIndexPath {
                cell.accessoryType = .checkmark;
                } else {
                    cell.accessoryType = .none;
                }
            return cell
        }
    }
    
    var selectedIndexPath = IndexPath(row: 0, section: 0);
    
    //Configure the TableViewCell for connection to the single device!!!
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true); // animated to true makes the grey fade out, set to false for it to immediately go away
            let newCell = tableView.cellForRow(at: indexPath);
            if newCell?.accessoryType == .none {
            newCell?.accessoryType = .checkmark
            }
            let oldCell = tableView.cellForRow(at: selectedIndexPath)
            if oldCell?.accessoryType == .checkmark {
            oldCell?.accessoryType = .none
            }

            selectedIndexPath = indexPath; // save the selected index path
            let peripherals = Array(bleDeviceList);
            let peripheral = peripherals[indexPath.row];
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark;
            centralManager?.stopScan();
            self.peripheral = peripheral;
            self.peripheral?.delegate = self;
            log.info("Connecting to the peripheral.");
            centralManager?.connect(peripheral, options: nil);
    }
      
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none;
        disconnect();
    }
    //Refreshing the device table list HERE!!!
    @IBAction func refreshDeviceTable(_ sender: UIRefreshControl) {
        //Every time on refreshing the table, clear the cells!!!
        bleDeviceList.removeAll();
        centralManager?.stopScan();
        sender.endRefreshing();
        connect();
    }
    
    
    // Connect to the BLE device.
    func connect() {
        centralManager = CBCentralManager(delegate: self, queue: .global(qos: .userInteractive));
        centralManager?.scanForPeripherals(withServices: nil, options: nil);
        
    }
    
    /// Invalidate the current BLE connection.
    func disconnect() {
        if let device = peripheral {
            centralManager?.cancelPeripheralConnection(device);
            peripheral = nil;
        } else {
            log.info("Nothing to disconnect.");
        }
    }
    
    /// Reading incoming binary packet from BLE characteristic and collecting header prefix with payload size
    /// - Parameter dataCharacteristic: The RXTX data flow peripheral's CBCharacteristic
    /// - Returns: Protobuf binary message
    private func read(dataCharacteristic: CBCharacteristic) -> Data? {
        let dataBuffer = dataCharacteristic.value
        print("Reading the incoming binary package");
        if let messageBuffer = dataBuffer, let messageString = String(data: messageBuffer, encoding: .utf8) {
            log.info(messageString)
        } else {
            log.info("Unable to decode the binary message into string");
        }
        return dataBuffer;
    }
    
    /// Sending the Protobuf serialized message consisting of header prefix and payload size.
    /// - Parameter data: final serialized protobuf binary message
    /// - Returns: the status of sent packet. If the peripheral is connected, the method returns true, otherwise-false.
    public func send(data: Data) -> Bool {
        if peripheral?.state == CBPeripheralState.connected { //, let characteristic = fcCharacteristic
            var package = Data();
            package.append(data);
            //peripheral?.writeValue(package, for: characteristic, type: CBCharacteristicWriteType.withResponse);
            return true;
        } else {
            log.warning("Unable to send data over BLE.");
            return false;
        }
        //print(package.map { String(format: "%02x", $0) }.joined());
    }
    
    /// Collecting the binary packages into the file stored regarding filepath property
    /// - Parameter data: binary packet, usually from the input data stream.
    func dumpBinaryToFile(data: Data) {
        
        if fileManager.fileExists(atPath: filePath), let fileHandle = FileHandle(forWritingAtPath: filePath) {
            fileHandle.seekToEndOfFile();
            fileHandle.write(data);
            fileHandle.closeFile();
        } else {
            log.warning("Warning!!! The file doesn't exist.");
        }
        
    }
    
    /// The BLE connection status events handler.
    /// - Parameter central: The BLE antenna state manager.
    func handler(central: CBCentralManager) {
        
        switch central.state {
        case .poweredOff:
            log.info("The Bluetooth state is currently switched off. Please turn it on to use it.");
        case .poweredOn:
            log.info("The Central manager is scanning for peripherals now");
            centralManager?.scanForPeripherals(withServices: servicesUuid, options: nil);
        case .unauthorized:
            log.warning("This application is not authorized to use the Bluetooth Low Energy! Please allow the usage of BLE in the application settings.");
        case .unknown:
            log.warning("The unknown event occured.");
        case .resetting:
            log.info("The BLE Manager is resetting. A state update is pending.");
        case .unsupported:
            log.warning("This device does not support the Bluetooth Low Energy technology. Please consider switching to another one.");
        default:
            log.warning("The unknown event occured.");
        }
        
    }
    
    //------------------------------------THE CENTRAL MANAGER SECTION--------------------------------------------
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        log.info("The Central manager state update");
        handler(central: central);
    }
    
    // This method handles the result of the scan.
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let description = """
        Accessory name: \(peripheral.name)
        Description: \(peripheral.description)
        Identifier: \(peripheral.identifier)
        Services: \(peripheral.services)
        State: \(peripheral.state)
        Signal strength: \(RSSI.decimalValue)
        """
        print(description);
        bleDeviceList.insert(peripheral);
        for (key, value) in advertisementData.enumerated() {
            log.info("\(key) -> \(value)");
        }
    }
    
    // The handler if we do connect succesfully
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            log.info("Connected to BLE device");
            peripheral.discoverServices(servicesUuid);
        } else {
            log.error("Error occured during device connection!!!");
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.error(error?.localizedDescription);
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == self.peripheral {
            log.info("Disconnected");
            self.peripheral = nil;
            // Start scanning again
            log.info("The Central manager is scanning for BLE devices now.");
            centralManager?.scanForPeripherals(withServices: servicesUuid, options: nil);
        } else {
            log.error(error?.localizedDescription);
        }
    }
    
    //------------------------------------THE PERIPHERAL SECTION--------------------------------------------
    
    // Handles discovery event
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services  { //let fc = fcUuid, let rxtx = rxtxUuid
            for service in services {
                log.info("The BLE device services have been discovered! \(service)");
                peripheral.discoverCharacteristics(servicesUuid, for: service);
            }
        } else {
            print(error?.localizedDescription);
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let services = service.characteristics  {
            log.info("There are \(services.count) BLE device characteristics found:");
            for characteristic in services {
                print(characteristic.uuid);
                peripheral.setNotifyValue(true, for: characteristic);
                peripheral.readValue(for: characteristic);
            }
        } else {
            log.error(error?.localizedDescription);
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = read(dataCharacteristic: characteristic) {
            log.info(data.map { String(format: "%02x", $0) }.joined());
            
        } else {
            log.error(error?.localizedDescription);
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        peripheral.readRSSI();
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            log.info("Message sent: \(data.map { String(format: "%02x", $0) }.joined(separator: ""))");
        }
        print(error?.localizedDescription);
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.isNotifying {
            log.info("Subscribed. Notification has begun for: \(characteristic.uuid)");
        } else {
            log.error(error?.localizedDescription);
        }
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
