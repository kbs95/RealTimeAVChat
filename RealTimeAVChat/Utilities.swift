//
//  Utilities.swift
//  RealTimeAVChat
//
//  Created by Abhishar Jangir on 01/09/18.
//  Copyright © 2018 Karan. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth

enum RegisterButtonTitles:String{
    case signUp = "SIGN UP"
    case login = "LOGIN"
}

extension UIViewController{
    func showAlert(title:String,message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

class SpinnerView{
    static let shared = SpinnerView()
    let activityIndicator:UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    let transparentView:UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        view.alpha = 0.5
        return view
    }()
    
    func showSpinnerOn(view:UIView){
        view.addSubview(transparentView)
        
        transparentView.centerXAnchor.constraint(equalTo: view.superview?.centerXAnchor ?? view.centerXAnchor).isActive = true
        transparentView.centerYAnchor.constraint(equalTo: view.superview?.centerYAnchor ?? view.centerYAnchor).isActive = true
        transparentView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        transparentView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        transparentView.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: transparentView.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: transparentView.centerYAnchor).isActive = true
        activityIndicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
        activityIndicator.startAnimating()
    }
    
    func removeSpinnerFrom(view:UIView){
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
        transparentView.removeFromSuperview()
    }
}

func setStatusForCurrentUser(isOnline:Bool){
    guard let uId = Auth.auth().currentUser?.uid else{
        return
    }
    Database.database().reference().child("RLTUser").child(uId).updateChildValues(["isOnline":isOnline])
}





// barcode util
//
//  BarCodeScannerViewController.swift
//  PipeTrak
//
//  Created by Ankit  Chaudhary on 18/07/17.
//  Copyright © 2017 abcplsud. All rights reserved.
//
//import UIKit
//import AVFoundation
//import RealmSwift
//import React
//
//
//class BarCodeScannerViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate {
//
//    @IBOutlet weak var scanLabel: CustomizedLabel!
//    @IBOutlet weak var searchBar: UISearchBar!
//    @IBOutlet weak var cameraView: UIView!
//    var barCodeSession:AVCaptureSession?
//    var barCodePreviewLayer:AVCaptureVideoPreviewLayer?
//    var captureDevice:AVCaptureDevice?
//    var captureInput:AVCaptureDeviceInput?
//    var captureOutput:AVCaptureMetadataOutput?
//    @IBOutlet weak var scanLayerView: UIView!
//    var resultTableView:UITableView!
//    var searchResults:Results<DynamicObject>?
//    var selectedPipe:RMPipeDetails?
//    let realm = try! Realm()
//    var popUpTableView:UITableView!
//    var popupResults:Results<DynamicObject>?
//    var transparentView = UIView()
//    var selectedItem:DynamicObject?
//    var listInputParamsJSON = ""
//    var listInputParamDictionary = [String:Any]()
//    var businessValidation:[[String:Any]] = []
//    var selectedObj:DynamicObject!
//    var isEventTrigger:Bool = false
//    var dynamicParams:[String:Any] = [:]
//    @IBOutlet weak var barMessageHeight: NSLayoutConstraint!
//    @IBOutlet weak var barMessageLabel: UILabel!
//    @IBOutlet weak var searchDefaultResultLabel: CustomizedLabel!
//    var initFormName = ""
//    let reactVc = UIViewController()
//    var multiSelectedData:[DynamicObject] = []
//    var isMultiSelect = false
//    var maxSelect = 0
//
//    var inputParamValues = (dataSource:"",searchAttributes:[""],displayAttributes:[""],navigatingToForm:"",navigatingToSection:"",placeHolderKey:"")
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        searchBar.layer.borderWidth = 0.5
//        searchBar.layer.borderColor = COLOR_SEARCH_BAR.cgColor
//        searchBar.delegate = self
//        resultTableView = UITableView(frame: CGRect(x: 0, y: searchBar.frame.maxY, width: UIScreen.main.bounds.width, height: 0))
//        resultTableView.register(UINib(nibName:"PipeResultsTableViewCell",bundle:nil), forCellReuseIdentifier: "PipeResultsCellIdentifier")
//        resultTableView.delegate = self
//        resultTableView.dataSource = self
//        resultTableView.separatorStyle = .none
//
//        popUpTableView = UITableView(frame: CGRect(x: Int(UIScreen.main.bounds.width/2), y: Int(UIScreen.main.bounds.height/2 - 64), width: 0, height: 0))
//        popUpTableView.register(UINib(nibName:"BarcodePopUpHeaderTableViewCell",bundle:nil), forCellReuseIdentifier: "BarcodePopupHeaderTableViewCellIdentifier")
//        popUpTableView.backgroundColor = PT_GREY
//        popUpTableView.delegate = self
//        popUpTableView.dataSource = self
//        popUpTableView.separatorStyle = .none
//        popUpTableView.tag = 2
//
//        transparentView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
//        transparentView.backgroundColor = .black
//        transparentView.alpha = 0.6
//
//        self.view.addSubview(resultTableView)
//        barMessageLabel.text = ""
//        barMessageHeight.constant = 0
//        NotificationCenter.default.addObserver(self, selector: #selector(setUpSession), name: NSNotification.Name(rawValue: "startSession"), object: nil)
//
//    }
//
//
//    func fetchInputParams(){
//        initFormName = realm.objects(FormDefinitionJson.self).filter("formId = \(ActiveTab.instance?.activePTMenuItem.rawValue ?? 0) AND defaultForm = true").first?.formName ?? ""
//        let activityId = ActiveTab.instance?.activePTMenuItem.rawValue ?? 0
//        if !dynamicParams.isEmpty{
//            parsingJSONToTuple(jsonString: JSONParser.convertDictionaryToJSON(dictionary: dynamicParams) ?? "")
//            let activityLips = realm.objects(FormDefinitionJson.self).filter("formId == \(activityId)").first?.ListInputParams ?? ""
//            businessValidation =   JSONParser.convertJSONToDictionary(JSONstring: activityLips)!["BusinessValidation"] as? [[String:Any]] ?? []
//            changeUIAccordingToParams()
//            return
//        }
//        listInputParamsJSON = realm.objects(FormDefinitionJson.self).filter("formId == \(activityId)").first?.ListInputParams ?? ""
//        parsingJSONToTuple(jsonString: listInputParamsJSON)
//        let placeholder =  (listInputParamDictionary["placeholderKey"] as? String ?? "")
//        searchBar.placeholder = placeholder
//        businessValidation = listInputParamDictionary["BusinessValidation"] as? [[String:Any]] ?? []
//    }
//
//    func changeUIAccordingToParams(){
//        setBackButton(showPopup: false)
//        multiSelectedData = []
//        let title = (listInputParamDictionary["Title"] as? String ?? "").uppercased()
//        let barMessage = (listInputParamDictionary["BarMessage"] as? String ?? "")
//        let searchText = (listInputParamDictionary["SearchDefaultResultText"] as? String ?? "")
//        let placeholder =  (listInputParamDictionary["placeholderKey"] as? String ?? "")
//        isMultiSelect =  (listInputParamDictionary["isMultiple"] as? Bool ?? false)
//        maxSelect =  (listInputParamDictionary["maxMultiSelect"] as? Int ?? 0)
//        barMessageLabel.text = barMessage
//        barMessage.isEmpty ? (barMessageHeight.constant = 0) : (barMessageHeight.constant = 25)
//        searchDefaultResultLabel.text = searchText
//        setCustomTitle(title: title, color: .black)
//        searchBar.placeholder = placeholder
//        // add done button for mutliselect
//        self.navigationItem.rightBarButtonItem = nil
//        if isMultiSelect{
//            let selectedIdString = (listInputParamDictionary["multiSelectData"] as? String ?? "")
//            if !selectedIdString.isEmpty{
//                let selectedIds = selectedIdString.components(separatedBy: ",")
//                multiSelectedData = Array(realm.dynamicObjects(inputParamValues.dataSource).filter("\(DynamicUtils.getPrimaryKeyFor(schemaName: inputParamValues.dataSource)) IN %@",selectedIds))
//            }
//            let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(multiSelectDone))
//            self.navigationItem.rightBarButtonItem = doneButton
//        }
//        setUpSession()
//
//    }
//
//    func multiSelectDone(){
//        if multiSelectedData.isEmpty{
//            self.navigationController?.view.showAlertBanner(title: "", message: "Select atleast one!", duration: 3)
//            return
//        }
//        self.navigationController?.popViewController(animated: true)
//        var dataDictionary:[String:Any] = [:]
//        dataDictionary["multiSelectData"] = multiSelectedData.map({return $0.toDictionary()})
//        dataDictionary["ctrlId"] = listInputParamDictionary["id"] as? String ?? ""
//        ReactNativeBridge.shared.sendEventWith(data: dataDictionary)
//    }
//
//
//    func parsingJSONToTuple(jsonString:String){
//        if let paramDictionary = JSONParser.convertJSONToDictionary(JSONstring: jsonString){
//            listInputParamDictionary = paramDictionary
//            inputParamValues.dataSource = paramDictionary["DataSource"] as? String ?? ""
//            inputParamValues.placeHolderKey = paramDictionary["PlaceHolderKey"] as? String ?? ""
//            inputParamValues.navigatingToSection = paramDictionary["NavigatingToSection"] as? String ?? ""
//            inputParamValues.navigatingToSection = paramDictionary["NavigatingToForm"] as? String ?? ""
//            inputParamValues.searchAttributes = (paramDictionary["SearchAttributes"] as? [String])?.map({ (data) -> String in
//                return data
//            }) ?? []
//            inputParamValues.displayAttributes = (paramDictionary["DisplayResultAttributes"] as? [String])?.map({ (data) -> String in
//                return data
//            }) ?? []
//        }
//    }
//
//    @IBAction func backFromNewReceiptViewController(segue: UIStoryboardSegue) {
//
//    }
//    func resignResponder(){
//        searchBar.resignFirstResponder()
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        parent?.setBatchCount()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//
//        transparentView.removeFromSuperview()
//        popUpTableView.removeFromSuperview()
//        UIApplication.shared.keyWindow?.addSubview(transparentView)
//        UIApplication.shared.keyWindow?.addSubview(popUpTableView)
//
//        dismissPopupTableView()
//        parent?.setBatchCount()
//        fetchInputParams()
//        self.resultTableView.frame = CGRect(x: 0, y: Int(searchBar.frame.maxY + barMessageHeight.constant), width: Int(UIScreen.main.bounds.width), height: 0)
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        searchBar.text = ""
//        searchBar.resignFirstResponder()
//        UIView.animate(withDuration: 0.4, animations: {
//            self.resultTableView.frame = CGRect(x: 0, y: Int(UIScreen.main.bounds.height/2 - 64), width: 0, height: 0)
//        })
//        if TARGET_IPHONE_SIMULATOR == 0{
//            barCodeSession?.stopRunning()
//        }
//    }
//
//    func setUpSession() {
//        if let _ = barCodeSession{
//            if let visible = listInputParamDictionary["ScannerVisible"] as? Bool{
//                if !visible{
//                    return
//                }
//            }
//            barCodeSession?.startRunning()
//        }else{
//            setUpBarCodeSession()
//        }
//
//    }
//
//    func setUpBarCodeSession(){
//
//        // CAMERA SESSION CREATION
//        barCodeSession = AVCaptureSession()
//
//        // SELECTING DEVICE
//        captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
//
//        // CREATE AND ADDING INPUT TO SESSION
//        do{
//            captureInput = try AVCaptureDeviceInput(device: captureDevice)
//        } catch{
//            print("capture device not working properly")
//            return
//        }
//        if (barCodeSession?.canAddInput(captureInput))!{
//            barCodeSession?.addInput(captureInput)
//        }else{
//            print("Cant find camera in your device")
//        }
//
//        //CREATING AND ADDING OUTPUT TO SESSION
//        captureOutput = AVCaptureMetadataOutput()
//        if (barCodeSession?.canAddOutput(captureOutput))!{
//            barCodeSession?.addOutput(captureOutput)
//            captureOutput?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
//            captureOutput?.metadataObjectTypes = [AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeUPCECode,AVMetadataObjectTypeCode93Code,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode128Code, AVMetadataObjectTypePDF417Code,AVMetadataObjectTypeQRCode]
//        }else{
//            print("Cant scan barcodes from this device")
//            return
//        }
//        setUpBarcodeScanningArea()
//
//    }
//
//    func setUpBarcodeScanningArea(){
//
//        // BARCODES WILL BE SCANNED WITHIN THIS SCAN LAYER VIEW
//        scanLayerView.setNeedsDisplay()
//        scanLayerView.setNeedsFocusUpdate()
//        scanLayerView.backgroundColor = UIColor.clear
//        scanLayerView?.layer.borderWidth = 2
//        scanLayerView?.layer.borderColor = UIColor.clear.cgColor
//
//
//        let frame = CGRect(x: 20, y: HEIGHT_OF_THE_SCREEN/2 - 140, width: WIDTH_OF_THE_SCREEN - 40, height: 180)
//
//        //SETUP CAMERA LAYER AND START THE SESSION
//        barCodePreviewLayer = AVCaptureVideoPreviewLayer(session: barCodeSession)
//        barCodePreviewLayer?.frame = view.layer.bounds
//        barCodePreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
//        captureOutput?.rectOfInterest = (barCodePreviewLayer?.metadataOutputRectOfInterest(for: frame))!
//        cameraView.layer.addSublayer(barCodePreviewLayer!)
//        cameraView.bringSubview(toFront: scanLayerView!)
//
//
//        // ADDING TRANSPARENT MASK LAYER
//        let overlayPath = UIBezierPath(rect: view.frame)
//        let scanPath = UIBezierPath(rect: frame)
//        overlayPath.append(scanPath)
//        let maskLayer = CAShapeLayer()
//        maskLayer.path = overlayPath.cgPath
//        maskLayer.fillRule = kCAFillRuleEvenOdd
//        maskLayer.opacity = 0.5
//        cameraView.layer.addSublayer(maskLayer)
//        cameraView.bringSubview(toFront: scanLabel)
//
//        if let visible = listInputParamDictionary["ScannerVisible"] as? Bool{
//            if !visible{
//                return
//            }
//        }
//        barCodeSession?.startRunning()
//    }
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//    }
//
//    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
//
//        // FETCHING BARCODE DATA HERE
//
//        if let barCodeData = metadataObjects.first{
//            connection.isEnabled = false
//            let stringValue = barCodeData as? AVMetadataMachineReadableCodeObject
//            if stringValue != nil{
//                let number = stringValue?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
//
//                let result = DynamicUtils.getRegisteredId(barCode: number ?? "")
//                if result.count == 1{
//                    self.barCodeSession?.stopRunning()
//                    listInputParamDictionary["DataSource"] = result[0].Group
//                    listInputParamDictionary["ResultKey"] = result[0].Attribute
//                    listInputParamDictionary["ResultValue"] = result[0].ItemId
//                    if isEventTrigger{
//                        if !validateDuplicateItem(){
//                            self.navigationController?.view.showAlertBanner(title:"", message: "Item already exists in report", duration:3)
//                            self.barCodeSession?.startRunning()
//                            connection.isEnabled = true
//                            return
//                        }
//                        if let id = listInputParamDictionary["NotContains"] as? String,id != ""{
//                            if (listInputParamDictionary["ResultValue"] as? String ?? "") == id{
//                                self.navigationController?.view.showAlertBanner(title: "", message: "Downstream and Upstream items can't be same", duration: 4)
//                                self.barCodeSession?.startRunning()
//                                connection.isEnabled = true
//                                return
//                            }
//                        }
//                        if let datObj = realm.dynamicObjects("\(listInputParamDictionary["DataSource"] as? String ?? "")").filter("\(listInputParamDictionary["ResultKey"] as? String ?? "") = '\(listInputParamDictionary["ResultValue"] as? String ?? "")'").first{
//                            self.navigationController?.popViewController(animated: true)
//                            var dataDictionary = datObj.toDictionary() as? [String:Any] ?? [:]
//                            dataDictionary["ctrlId"] = listInputParamDictionary["id"] as? String ?? ""
//                            ReactNativeBridge.shared.sendEventWith(data: dataDictionary)
//                            connection.isEnabled = true
//                            return
//                        }
//                    }
//                    loadReactForm()
//                }else if result.count > 1{
//                    self.barCodeSession?.stopRunning()
//                    listInputParamDictionary["DataSource"] = result[0].Group
//                    listInputParamDictionary["ResultKey"] = result[0].Attribute
//                    popupResults = realm.dynamicObjects(listInputParamDictionary["DataSource"] as? String ?? "").filter("\(listInputParamDictionary["ResultKey"] as? String ?? "") IN %@",result.map({ (rid) -> String in
//                        return rid.ItemId
//                    }))
//                    if popupResults?.count == 0{
//                        listInputParamDictionary["ResultValue"] = result[0].ItemId
//                        if isEventTrigger{
//                            self.navigationController?.popViewController(animated: true)
//                            var dataDictionary = popupResults?[0].toDictionary() as? [String:Any] ?? [:]
//                            dataDictionary["ctrlId"] = listInputParamDictionary["id"] as? String ?? ""
//                            ReactNativeBridge.shared.sendEventWith(data: dataDictionary)
//                            connection.isEnabled = true
//                            return
//                        }
//                        loadReactForm()
//                    }else{
//                        animatePopupTableView()
//                    }
//                }else{
//                    if !Banner.isVisible{
//                        self.navigationController?.view.showAlertBanner(title: "", message:"Invalid Pipe No." , duration:2)
//                    }
//                }
//            }
//            connection.isEnabled = true
//        }
//
//    }
//
//    func validateDuplicateItem()->Bool{
//        if listInputParamDictionary["DataSource"] as? String != "items"{
//            return true
//        }
//        let data = businessValidation[0]
//        let entitiyName = data["entitiyName"] as? String ?? ""
//        let params = data["params"] as? [String:Any] ?? [:]
//        let mapping = params["controlMapping"] as? [[String:Any]] ?? []
//        var attributes:[[String:Any]] = []
//        mapping.forEach { (keyVal) in
//            var json = [String:Any]()
//            json = keyVal
//            json["value"] = listInputParamDictionary["ResultValue"] as? String ?? ""
//            attributes.append(json)
//        }
//        let entityRow = realm.dynamicObjects(entitiyName).filter(DynamicPredicates.createKeyValueAndPredicateOR(attributes: attributes))
//
//        if entityRow.count > 0{
//            return false
//        }
//        return true
//    }
//
//    func fetchPipeDataFromRealm(searchText:String){
//
//        if let dependency = listInputParamDictionary["DependencyOn"] as? [[String:Any]]{
//            dependency.count > 0 ? (searchResults = handleDependency(obj: dependency[0]).filter(DynamicPredicates.createFilterPredicateArray(attributes: inputParamValues.searchAttributes,searchText: searchText))) : (searchResults = realm.dynamicObjects(inputParamValues.dataSource).filter(DynamicPredicates.createFilterPredicateArray(attributes: inputParamValues.searchAttributes,searchText: searchText)))
//        }else{
//            searchResults = realm.dynamicObjects(inputParamValues.dataSource).filter(DynamicPredicates.createFilterPredicateArray(attributes: inputParamValues.searchAttributes,searchText: searchText))
//        }
//
//        if searchResults?.count == 0{
//            if let navigation = self.navigationController{
//                navigation.view.showAlertBanner(title:"", message: "Data does not exist", duration:1)
//            }else{
//                self.parent?.navigationController?.view.showAlertBanner(title:"", message: "Pipe does not exist", duration:1)
//            }
//        }
//        animateTableView()
//    }
//
//    func handleDependency(obj:[String:Any])->Results<DynamicObject>{
//        return DynamicUtils.invokeFunctionForDependency(data: obj)!
//    }
//
//    func animatePopupTableView(){
//        transparentView.frame = CGRect(x: 0, y: 0, width: WIDTH_OF_THE_SCREEN, height: HEIGHT_OF_THE_SCREEN)
//        popUpTableView.reloadData()
//        let contentSize:CGFloat = CGFloat(((popupResults?.count)! + 1) * 66)
//        UIView.animate(withDuration: 0.4) {
//            if self.popupResults?.count == 0{
//                self.popUpTableView.frame = CGRect(x: 15, y: 50, width: Int(UIScreen.main.bounds.width - 30), height: 0)
//            }else{
//                self.popUpTableView.frame = CGRect(x: 15, y: 50, width: Int(UIScreen.main.bounds.width - 30), height: Int(contentSize >= UIScreen.main.bounds.height - 50 ? UIScreen.main.bounds.height - 100 : contentSize))
//            }
//        }
//    }
//
//    func dismissPopupTableView(){
//        transparentView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
//        popUpTableView.frame = CGRect(x: Int(UIScreen.main.bounds.width/2), y: Int(UIScreen.main.bounds.height/2 - 64), width: 0, height: 0)
//        self.barCodeSession?.startRunning()
//    }
//
//    func animateTableView(){
//        self.resultTableView.setContentOffset(CGPoint(x:0,y:0), animated: false)
//        self.resultTableView.reloadData()
//        self.view.bringSubview(toFront: self.resultTableView)
//        UIView.animate(withDuration: 0.4) {
//            if self.searchResults?.count == 0{
//                self.popUpTableView.frame = CGRect(x: 15, y: 50, width: Int(UIScreen.main.bounds.width - 30), height: 0)
//            }else{
//                self.resultTableView.frame = CGRect(x: 0, y: Int(self.searchBar.frame.maxY + self.barMessageHeight.constant), width: Int(UIScreen.main.bounds.width), height: Int(self.resultTableView.contentSize.height >= UIScreen.main.bounds.height - 50 ? UIScreen.main.bounds.height - 100 : self.resultTableView.contentSize.height))
//            }
//        }
//    }
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // clear damage dictionary first
//        //        NewReceiptDamgeViewController.damageDictionary = []
//        //
//        //        if ActiveTab.instance?.activePTMenuItem == PTMenuItem.Receipt {
//        //            let vc = segue.destination as? NewReceiptContainerViewController
//        //            vc?.pipeData = selectedPipe
//        //        }
//        //
//        //        if ActiveTab.instance?.activePTMenuItem == PTMenuItem.Dispatch {
//        //            let vc = segue.destination as? NewDispatchViewController
//        //            vc?.pipeData = selectedPipe
//        //        }
//        //
//        //        if ActiveTab.instance?.activePTMenuItem == PTMenuItem.MaterialInspeciton {
//        //            let vc = segue.destination as? MaterialInspectionContainerViewController
//        //            vc?.pipeData = selectedPipe
//        //        }
//        //
//        //        if ActiveTab.instance?.activePTMenuItem == PTMenuItem.DamageReturn {
//        //            let vc = segue.destination as? NewDispatchViewController
//        //            vc?.pipeData = selectedPipe
//        //        }
//        //
//        //        if ActiveTab.instance?.activePTMenuItem == PTMenuItem.DamageInspection {
//        //            let vc = segue.destination as? DamageInspectionContainerViewController
//        //            vc?.pipeData = selectedPipe
//        //        }
//        //
//        //        if ActiveTab.instance?.activePTMenuItem == PTMenuItem.Stringing {
//        //            let vc = segue.destination as? StringingAddPipeViewController
//        //            vc?.pipeData = selectedPipe
//        //        }
//    }
//
//}
//
//extension BarCodeScannerViewController:UISearchBarDelegate{
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        if searchText == ""{
//            UIView.animate(withDuration: 0.4, animations: {
//                self.resultTableView.frame = CGRect(x: 0, y: Int(self.searchBar.frame.maxY + self.barMessageHeight.constant), width: Int(UIScreen.main.bounds.width), height: 0)
//            })
//            return
//        }
//
//        fetchPipeDataFromRealm(searchText: searchText)
//    }
//
//
//    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
//        if searchBar.text == ""{
//            UIView.animate(withDuration: 0.4, animations: {
//                self.resultTableView.frame = CGRect(x: 0, y: Int(self.searchBar.frame.maxY + self.barMessageHeight.constant), width: Int(UIScreen.main.bounds.width), height: 0)
//            })
//        }
//    }
//}
//
//extension BarCodeScannerViewController:UITableViewDelegate,UITableViewDataSource{
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if tableView.tag == 2{
//            return popupResults == nil ? 0 : (popupResults?.count)!
//        }
//
//        if searchResults == nil{
//            return 0
//        }
//        return (searchResults?.count)!
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        // multi select
//        if isMultiSelect{
//            if !multiSelectedData.contains(searchResults![indexPath.row]){
//                if maxSelect == multiSelectedData.count{
//                    self.navigationController?.view.showAlertBanner(title: "", message: "Can't Select more than that!", duration: 3)
//                    return
//                }
//                multiSelectedData.append((searchResults?[indexPath.row])!)
//                tableView.reloadRows(at: [indexPath], with: .bottom)
//            }else{
//                multiSelectedData.remove(at: multiSelectedData.index(of: searchResults![indexPath.row]) ?? 0)
//                tableView.reloadRows(at: [indexPath], with: .top)
//            }
//            return
//        }
//        if tableView.tag == 2{
//            dismissPopupTableView()
//            selectedObj = popupResults?[indexPath.row]
//        }else{
//            selectedObj = searchResults?[indexPath.row]
//        }
//        listInputParamDictionary["ResultValue"] = (selectedObj.value(forKey: listInputParamDictionary["ResultKey"] as? String ?? "") as? String ?? "")
//        if !validateDuplicateItem(){
//            self.navigationController?.view.showAlertBanner(title:"", message: "Item already exists in report", duration:3)
//            self.barCodeSession?.startRunning()
//            return
//        }
//        if isEventTrigger{
//            if let id = listInputParamDictionary["NotContains"] as? String,id != ""{
//                if (selectedObj[listInputParamDictionary["ResultKey"] as? String ?? ""] as? String ?? "") == id{
//                    self.navigationController?.view.showAlertBanner(title: "", message: "Downstream and Upstream items can't be same", duration: 4)
//                    return
//                }
//            }
//            if (self.navigationController?.viewControllers.count ?? 0) > 1 {
//                self.navigationController?.popViewController(animated: true)
//            }else{
//                self.navigationController?.dismiss(animated: true, completion: nil)
//            }
//
//            var dataDictionary = selectedObj.toDictionary() as? [String:Any] ?? [:]
//            dataDictionary["ctrlId"] = listInputParamDictionary["id"] as? String ?? ""
//            ReactNativeBridge.shared.sendEventWith(data: dataDictionary)
//            return
//        }
//        autoreleasepool {
//            loadReactForm()
//        }
//    }
//
//    func loadReactForm(){
//        if !validateDuplicateItem(){
//            self.parent?.navigationController?.view.showAlertBanner(title:"", message: "Item already exists in report", duration:3)
//            self.barCodeSession?.startRunning()
//            return
//        }
//        var finalProps = [String:Any]()
//        finalProps["initFormName"] = initFormName
//        finalProps["ListInputParams"] = listInputParamDictionary
//        let rootReactView = RCTRootView(bridge: AppDelegate.sharedReactBridge, moduleName: "pipetrakv2", initialProperties: finalProps)
//        let activityLoader = UIActivityIndicatorView(activityIndicatorStyle: .gray)
//        activityLoader.startAnimating()
//        rootReactView?.loadingView = activityLoader
//
//        reactVc.view = rootReactView
//        self.present(reactVc, animated: true, completion: nil)
//    }
//
//    func checkIFpipeExistsForStringing()-> Bool{
//        let currentReportId = (UserDefaults.standard.value(forKey: UserDefaultKeys.ReportId.rawValue) as? Int64)!
//        let pipe = selectedPipe!
//        let results = realm.objects(RMStringingAudit.self).filter("ActivityHeaderPKID == \(currentReportId)")
//        let finalResults = results.filter { (data) -> Bool in
//            if data.SAPipeClassAudits[0].PipeFromId == pipe.PipeId{
//                return true
//            }
//            return false
//        }
//        if finalResults.count > 0{
//            self.parent?.navigationController?.view.showAlertBanner(title:"", message: "PipeNo/ItemNo: \(pipe.PipeNo) with Heat No: \(pipe.HeatNo) already exists in current Report", duration:3)
//            return true
//        }
//        return false
//    }
//
//
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        if tableView.tag == 2{
//            return 66
//        }
//        return 0
//    }
//
//
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        if tableView.tag == 2{
//            let cell = tableView.dequeueReusableCell(withIdentifier: "BarcodePopupHeaderTableViewCellIdentifier") as? BarcodePopUpHeaderTableViewCell
//            cell?.contentView.backgroundColor = PT_GREY
//            return cell?.contentView
//        }
//        return UIView()
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if tableView.tag == 2{
//            let cell = tableView.dequeueReusableCell(withIdentifier: "BarcodePopupHeaderTableViewCellIdentifier") as? BarcodePopUpHeaderTableViewCell
//            cell?.selectionStyle = .none
//            cell?.pipenumberLabel.text = ""
//            cell?.heatNumberLabel.text = ""
//            cell?.diameterLabel.text = ""
//            cell?.thicknessLabel.text = ""
//            if inputParamValues.displayAttributes.count > 0{
//                if let doubleValue = popupResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[0]) as? Double{
//                    cell?.pipenumberLabel.text = doubleValue.description
//                }
//                if let intValue = popupResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[0]) as? Int{
//                    cell?.pipenumberLabel.text = intValue.description
//                }
//                if let stringValue = popupResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[0]) as? String{
//                    cell?.pipenumberLabel.text = stringValue
//                }
//            }
//            if inputParamValues.displayAttributes.count > 1{
//                if let doubleValue = popupResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[1]) as? Double{
//                    cell?.heatNumberLabel.text = doubleValue.description
//                }
//                if let intValue = popupResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[1]) as? Int{
//                    cell?.heatNumberLabel.text = intValue.description
//                }
//                if let stringValue = popupResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[1]) as? String{
//                    cell?.heatNumberLabel.text = stringValue
//                }
//            }
//            if inputParamValues.displayAttributes.count > 2{
//                if let doubleValue = popupResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[2]) as? Double{
//                    cell?.diameterLabel.text = doubleValue.description
//                }
//                if let intValue = popupResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[2]) as? Int{
//                    cell?.diameterLabel.text = intValue.description
//                }
//                if let stringValue = popupResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[2]) as? String{
//                    cell?.diameterLabel.text = stringValue
//                }
//            }
//            if inputParamValues.displayAttributes.count > 3{
//                if let doubleValue = popupResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[3]) as? Double{
//                    cell?.thicknessLabel .text = doubleValue.description
//                }
//                if let intValue = popupResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[3]) as? Int{
//                    cell?.thicknessLabel .text = intValue.description
//                }
//                if let stringValue = popupResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[3]) as? String{
//                    cell?.thicknessLabel .text = stringValue
//                }
//            }
//            return cell!
//        }
//        let cell = tableView.dequeueReusableCell(withIdentifier: "PipeResultsCellIdentifier") as? PipeResultsTableViewCell
//        cell?.selectionStyle = .none
//        cell?.pipeNumberLabel.text = ""
//        cell?.pipeHeatNumberLabel.text = ""
//        if inputParamValues.displayAttributes.count > 0{
//            if let doubleValue = searchResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[0]) as? Double{
//                cell?.pipeHeatNumberLabel.text = doubleValue.description
//            }
//            if let intValue = searchResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[0]) as? Int{
//                cell?.pipeHeatNumberLabel.text = intValue.description
//            }
//            if let stringValue = searchResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[0]) as? String{
//                cell?.pipeHeatNumberLabel.text = stringValue
//            }
//        }
//        if inputParamValues.displayAttributes.count > 1{
//            if let doubleValue = searchResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[1]) as? Double{
//                cell?.pipeNumberLabel.text = doubleValue.description
//            }
//            if let intValue = searchResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[1]) as? Int{
//                cell?.pipeNumberLabel.text = intValue.description
//            }
//            if let stringValue = searchResults?[indexPath.row].value(forKey: inputParamValues.displayAttributes[1]) as? String{
//                cell?.pipeNumberLabel.text = stringValue
//            }
//        }
//        // multiselect
//        if isMultiSelect{
//            cell?.accessoryView?.tintColor = .black
//            multiSelectedData.contains(searchResults![indexPath.row]) ? (cell?.accessoryType = UITableViewCellAccessoryType.checkmark) : (cell?.accessoryType = UITableViewCellAccessoryType.none)
//        }
//
//        return cell!
//    }
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if tableView.tag == 2{
//            return 66
//        }
//        return 58
//    }
//
//}

