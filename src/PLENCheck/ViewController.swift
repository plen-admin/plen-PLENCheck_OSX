//
//  ViewController.swift
//  PLENCheck
//
//  Created by PLEN on 2015/09/08.
//  Copyright (c) 2015年 PLEN Project Company Ltd. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ViewController: NSViewController, PlenCommDelegate {

    @IBOutlet var btnConnect: NSButton!
    @IBOutlet var btnDisConnect: NSButton!
    @IBOutlet var btnMax: NSButton!
    @IBOutlet var btnMin: NSButton!
    @IBOutlet var btnHome: NSButton!
    @IBOutlet var btnUp: NSButton!
    @IBOutlet var btnDown: NSButton!
    @IBOutlet var btnPortUpDate: NSButton!
    @IBOutlet var labelValue: NSTextField!
    @IBOutlet var labelLog: NSTextField!
    @IBOutlet var radioBtns: NSMatrix!
    @IBOutlet var slider: NSSlider!
    @IBOutlet var cmbBoxSerial: NSComboBox!
    @IBOutlet var cmbBoxConnect: NSComboBox!
    
    let USB = "USB"
    let BLE = "BLE"
    let JOINT_TAG_MAP = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 12, 13, 14, 15, 16, 17, 18, 19, 20 ]
    
    var bleProcess = BLEProcess()
    var usbProcess: SerialPort?
    var connectProcess:ConnectProcess!
    var isConnected = false
    
    var checkedBtnNum = 0
    
    var settings: [(min:Int, max:Int, home:Int, now:Int)] =
        [( 250, 1550, 900,  900  ),
        ( 250, 1550, 1150, 1150 ),
        ( 250, 1550, 1200, 1200 ),
        ( 250, 1550, 800,  800  ),
        ( 250, 1550, 800,  800  ),
        ( 250, 1550, 850,  850  ),
        ( 250, 1550, 1400, 1400 ),
        ( 250, 1550, 1200, 1200 ),
        ( 250, 1550, 850,  850  ),
        ( 250, 1550, 900,  900  ),
        ( 250, 1550, 950,  950  ),
        ( 250, 1550, 600,  600  ),
        ( 250, 1550, 1100, 1100 ),
        ( 250, 1550, 1000, 1000 ),
        ( 250, 1550, 1100, 1100 ),
        ( 250, 1550, 400,  400  ),
        ( 250, 1550, 580,  580  ),
        ( 250, 1550, 1000, 1000 )]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        bleProcess.delegate = self
        
        radioBtns_Clicked(self)
        cmbBoxSerial_Init()
        // Do any additional setup after loading the view.
    }
    

    override var representedObject: AnyObject? {
        
        didSet {
        // Update the view, if already loaded.
        }
    }

    /*----- シリアルポート一覧コンボボックス初期化 -----*/
    func cmbBoxSerial_Init() {
        // 「$ ls /dev/tty.usb*」の結果をpipeに格納，受け取ったtty.usb一覧をコンボボックスに表示する
/*        let task = NSTask()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "ls /dev/tty.usb*"]
        
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = NSString(data: data, encoding: NSUTF8StringEncoding) {
            let ports = output.componentsSeparatedByString("\n")
            cmbBoxSerial.removeAllItems()
            for port in ports {
                if port as! String != "" {
                    cmbBoxSerial.addItemWithObjectValue(port)
                }
            }
            if cmbBoxSerial.objectValues.count > 0 {
                cmbBoxSerial.selectItemAtIndex(0)
            }
        }
        task.waitUntilExit()
*/    }
    @IBAction func btnConnect_Clicked(sender: AnyObject) {
        // BLE通信
        if (cmbBoxConnect.objectValueOfSelectedItem as? String) == BLE {
            if bleProcess.centralManager.state != CBCentralManagerState.PoweredOn {
                let alert = NSAlert()
                alert.messageText = "error : BLE isn't available. (\(bleProcess.centralManager.state.toString))    \n"
                alert.runModal()
                return
            }
            connectProcess = bleProcess
        }
        else {
            let alert = NSAlert()
            alert.messageText = "error : choose the communication method. (\(bleProcess.centralManager.state.toString))    \n"
            alert.runModal()
            return
        }
            // USB通信
 /*       else {
            if cmbBoxSerial.objectValueOfSelectedItem == nil {
                let alert = NSAlert()
                alert.messageText = "error : シリアルポートを選択してください．\n"
                alert.runModal()
                return
            }
            
            usbProcess = SerialPort(delegate: self, devicePath: cmbBoxSerial.objectValueOfSelectedItem as! String)
            
            
            if usbProcess?.serialPort == nil {
                let alert = NSAlert()
                alert.messageText = "error : 選択されたシリアルポートが利用できません．\n"
                alert.runModal()
                return
            }
            connectProcess = usbProcess!
        }
*/
        btnConnect.enabled = false
        btnDisConnect.enabled = true
        btnPortUpDate.enabled = false
        cmbBoxConnect.enabled = false
        cmbBoxSerial.enabled = false
        connectProcess.PlenConnect()
        
    }
    @IBAction func btnDisConnect_Clicked(sender: AnyObject) {
        connectProcess.PlenDisconnect()
        btnConnect.enabled = true
        btnDisConnect.enabled = false
        cmbBoxConnect.enabled = true
        cmbBoxConnect_SelectedItemChanged(self)
        isConnected = false
    }
    @IBAction func btnPortUpdate_Click(sender: AnyObject) {
        cmbBoxSerial.deselectItemAtIndex(cmbBoxSerial.indexOfSelectedItem)
        cmbBoxSerial.removeAllItems()
        cmbBoxSerial_Init()
    }
    @IBAction func cmbBoxConnect_SelectedItemChanged(sender: AnyObject) {
        if (cmbBoxConnect.objectValueOfSelectedItem as? String) == USB {
            cmbBoxSerial.enabled = true
            btnPortUpDate.enabled = true
        }
        else {
            cmbBoxSerial.enabled = false
            btnPortUpDate.enabled = false
        }
    }
    @IBAction func radioBtns_Clicked(sender: AnyObject) {
        checkedBtnNum = radioBtns.selectedCell().tag()
        
        btnMax.title = "Max : " + String(settings[checkedBtnNum].max)
        btnMin.title = "Min : " + String(settings[checkedBtnNum].min)
        btnHome.title = "Home : " + String(settings[checkedBtnNum].home)
        labelValue.stringValue = String(settings[checkedBtnNum].now)
        
        slider.integerValue = settings[checkedBtnNum].now
        
    }
    @IBAction func slider_ValueChanged(sender: AnyObject) {
        settings[checkedBtnNum].now = slider.integerValue
        labelValue.stringValue = String(slider.integerValue)
        
        if isConnected == true {
            connectProcess.PlenSendCommand("#SA" + String(format: "%02hx%03hx", JOINT_TAG_MAP[checkedBtnNum], settings[checkedBtnNum].now))
        }
    }
    
    @IBAction func btnMax_Clicked(sender: AnyObject) {
        settings[checkedBtnNum].max = settings[checkedBtnNum].now
        radioBtns_Clicked(self)
        
        if isConnected == true {
            connectProcess.PlenSendCommand("#MA" + String(format: "%02hx%03hx", JOINT_TAG_MAP[checkedBtnNum], settings[checkedBtnNum].now))
        }
    }
    @IBAction func btnMin_Clicked(sender: AnyObject) {
        settings[checkedBtnNum].min = settings[checkedBtnNum].now
        radioBtns_Clicked(self)
        
        if isConnected == true {
            connectProcess.PlenSendCommand("#MI" + String(format: "%02hx%03hx", JOINT_TAG_MAP[checkedBtnNum], settings[checkedBtnNum].now))
        }
    }
    @IBAction func btnHome_Clicked(sender: AnyObject) {
        settings[checkedBtnNum].home = settings[checkedBtnNum].now
        radioBtns_Clicked(self)
        
        if isConnected == true {
            connectProcess.PlenSendCommand("#HO" + String(format: "%02hx%03hx", JOINT_TAG_MAP[checkedBtnNum], settings[checkedBtnNum].now))
        }
    }
    @IBAction func btnUp_Clicked(sender: AnyObject) {
        if settings[checkedBtnNum].now < settings[checkedBtnNum].max {
            settings[checkedBtnNum].now++
            radioBtns_Clicked(self)
            
            if isConnected == true {
                connectProcess.PlenSendCommand("#SA" + String(format: "%02hx%03hx", JOINT_TAG_MAP[checkedBtnNum], slider.integerValue))
            }
        }
    }
    @IBAction func btnDown_Clicked(sender: AnyObject) {
        if settings[checkedBtnNum].now > settings[checkedBtnNum].min{
            settings[checkedBtnNum].now--
            radioBtns_Clicked(self)
            
            if isConnected == true {
                connectProcess.PlenSendCommand("#SA" + String(format: "%02hx%03hx", JOINT_TAG_MAP[checkedBtnNum], slider.integerValue))
            }
        }
    }
}

extension ViewController {
    func BLEStateUpdated(state: CBCentralManagerState) {
        cmbBoxConnect.removeAllItems()
        cmbBoxConnect.stringValue = ""
        // BLE使用可能時はコンボボックスにBLE，USBを，それ以外の場合はUSBのみ表示する
        if state == CBCentralManagerState.PoweredOn {
            cmbBoxConnect.addItemWithObjectValue(BLE)
            cmbBoxConnect.selectItemAtIndex(0)
        }
        //cmbBoxConnect.addItemWithObjectValue(USB)
        

        cmbBoxConnect_SelectedItemChanged(self)
    }
    
    func MessageFromCommProcess(message: String!) {
        labelLog.stringValue = message
    }
    
    func PlenConnected(isError: Bool) {
        isConnected = true
    }
    
    func PlenCommandSended() {

    }


}

