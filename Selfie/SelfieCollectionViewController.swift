//
//  SelfieCollectionViewController.swift
//  Selfie
//
//  Created by Behera, Subhransu on 29/8/14.
//  Copyright (c) 2014 subhb.org. All rights reserved.
//

import UIKit


let reuseIdentifier = "SelfieCollectionViewCell"

class SelfieCollectionViewController: UICollectionViewController {
    var shouldFetchNewData = true
    var dataArray = [SelfieImage]()
    let httpHelper = HTTPHelper()
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if defaults.objectForKey("userLoggedIn") == nil {
            // if there is NO user credential stored in the app, i.e. they haven't signed it, go to Login screen
            
            if let loginController = self.storyboard?.instantiateViewControllerWithIdentifier("ViewController") as? ViewController {
                self.navigationController?.presentViewController(loginController, animated: true, completion: nil)
            }
        } else {
            // if there is user credential, check if API token has expired (authtoken_expiry)
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSZ"
            let userTokenExpiryDate: String? = KeychainAccess.passwordForAccount("Auth_Token_Expiry", service: "KeyChainService")
            let dateFromString: NSDate? = dateFormatter.dateFromString(userTokenExpiryDate!)
            let now = NSDate()
            let comparison = now.compare(dateFromString!)
            
            // check if should fetch new data
            if shouldFetchNewData {
                shouldFetchNewData = false
                self.setNavigationItems()
                loadSelfieData()
            }
            
            // if token is expired, logout and ask user to sign in again
            if comparison != NSComparisonResult.OrderedAscending {
                self.logoutBtnTapped()
            }
        }
    }
    
    func setNavigationItems() {
        let logOutBtn = UIBarButtonItem(title: "logout", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(SelfieCollectionViewController.logoutBtnTapped))
        self.navigationItem.leftBarButtonItem = logOutBtn
        
        let navCameraBtn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Camera, target: self, action: #selector(SelfieCollectionViewController.cameraBtnTapped))
        self.navigationItem.rightBarButtonItem = navCameraBtn
    }
    
    // 1. Clears the NSUserDefaults flag
    func clearLoggedinFlagInUserDefaults() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey("userLoggedIn")
        defaults.synchronize()
    }
    
    // 2. Removes the data array
    func clearDataArrayAndReloadCollectionView() {
        dataArray.removeAll(keepCapacity: true)
        collectionView?.reloadData()
    }
    
    // 3. Clears API Auth token from Keychain
    func clearAPITokensFromKeyChain () {
        if let userToken = KeychainAccess.passwordForAccount("Auth_Token", service: "KeyChainService") {
            KeychainAccess.deletePasswordForAccount(userToken, account: "Auth_Token", service: "KeyChainService")
        }
        
        if let userTokenExpiryDate = KeychainAccess.passwordForAccount("Auth_Token_Expiry", service: "KeyChainService") {
            KeychainAccess.deletePasswordForAccount(userTokenExpiryDate, account: "Auth_Token_Expiry", service: "KeyChainService")
        }
    }
    
    // MARK: logoutBtnTapped
    func logoutBtnTapped() {
        
        clearLoggedinFlagInUserDefaults()
        clearDataArrayAndReloadCollectionView()
        clearAPITokensFromKeyChain()
        
        shouldFetchNewData = true
        self.viewDidAppear(true)
        
    }
    
    // MARK: cameraBtnTapped
    func cameraBtnTapped() {
        displayCameraControl()
    }
    
    
    // MARK: - HTTP GET request
    func loadSelfieData () {
        // 1. create HTTP request and set request body
        let httpRequest = httpHelper.buildRequest("get_photos", method: "GET", authType: HTTPRequestAuthType.HTTPTokenAuth)
        
        // 2. send HTTP request to load existing selfie
        httpHelper.sendRequest(httpRequest) { (data: NSData!, error: NSError!) in
            if error != nil {
                let errorMessage = self.httpHelper.getErrorMessage(error)
                let errorAlert = UIAlertView(title: "Error", message: errorMessage as String, delegate: nil, cancelButtonTitle: "OK")
                errorAlert.show()
                return
            }
            
            do {
                if let jsonDataArray = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? NSArray {
                    
                    // load the collection view with existing selfies
                    if jsonDataArray.count > 0 {
                        
                        print("-----jsonDataArray-----")
                        print(jsonDataArray)
                        
                        for imageDataDict in jsonDataArray {
                            // grab the json data and store it in a SelfieImage object
                            let selfieImgObj = SelfieImage()
                            
                            selfieImgObj.imageTitle = imageDataDict.valueForKey("title") as! String
                            selfieImgObj.imageId = imageDataDict.valueForKey("random_id") as! String
                            selfieImgObj.imageThumbnailURL = imageDataDict.valueForKey("image_url") as! String
                            
                            self.dataArray.append(selfieImgObj)
                        }
                        // when data saved successfully, reload collection view
                        self.collectionView?.reloadData()
                    }
                }
            } catch {
                print("loadSelfieData error: \(error)")
            }
        }
    }
    
    func removeObject<T:Equatable>(inout arr:Array<T>, object:T) -> T? {
        if let indexOfObject = arr.indexOf(object) {
            return arr.removeAtIndex(indexOfObject)
        }
        
        return nil
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! SelfieCollectionViewCell
        
        // configure the cell (in descending order of creation time)
        let rowIndex = self.dataArray.count - (indexPath.row + 1) // displays most recent data on top
        let selfieRowObj = self.dataArray[rowIndex] as SelfieImage
        
        cell.backgroundColor = UIColor.blackColor()
        cell.selfieTitle.text = selfieRowObj.imageTitle
        
        let imgURL: NSURL = NSURL(string: selfieRowObj.imageThumbnailURL)!
        
        // download an NSData representation of the image at the URL
        let request: NSURLRequest = NSURLRequest(URL: imgURL)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response: NSURLResponse?, data: NSData?, error: NSError?) in
            
            if error == nil {
                let image = UIImage(data: data!)
                dispatch_async(dispatch_get_main_queue(), {
                    cell.selfieImgView.image = image
                })
            } else {
                print("#####collectionView:cellForItemAtIndexPath Error: \(error?.localizedDescription)")
            }
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // fetch the Selfie Image Object
        let rowIndex = dataArray.count - (indexPath.row + 1)
        let selfieRowObj = dataArray[rowIndex] as SelfieImage
        
        pushDetailsViewControllerWithSelfieObject(selfieRowObj)
    }
}

// MARK: - Camera Extension

extension SelfieCollectionViewController : UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func displayCameraControl() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            imagePickerController.sourceType = UIImagePickerControllerSourceType.Camera
            
            if UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.Front) {
                imagePickerController.cameraDevice = UIImagePickerControllerCameraDevice.Front
            } else {
                imagePickerController.cameraDevice = UIImagePickerControllerCameraDevice.Rear
            }
        } else {
            imagePickerController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        }
        
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // dismiss the image picker controller window
        self.dismissViewControllerAnimated(true, completion: nil)
        
        var image: UIImage
        // fetch the selected image
        if picker.allowsEditing {
            image = info[UIImagePickerControllerEditedImage] as! UIImage
        } else {
            image = info[UIImagePickerControllerOriginalImage] as! UIImage
        }
        
        presentComposeViewControllerWithImage(image)
    }
}

// MARK: - Compose Selfie Extension

extension SelfieCollectionViewController : SelfieComposeDelegate {
    func presentComposeViewControllerWithImage(image:UIImage!) {
        
        // instantiate compose view controller to capture a caption
        if let composeVC: ComposeViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ComposeViewController") as? ComposeViewController {
            composeVC.composeDelegate = self
            composeVC.thumbImg = image
            
            // set the navigation controller of compose view controller
            let compaseNavVC = UINavigationController(rootViewController: composeVC)
            
            // present compose view controller
            self.navigationController?.presentViewController(compaseNavVC, animated: true, completion: nil)
            
        }
        
    }
    
    func reloadCollectionViewWithSelfie(selfieImgObject: SelfieImage) {
        
        dataArray.append(selfieImgObject)
        collectionView?.reloadData()
        
    }
}

// MARK: - Selfie Details Extension

extension SelfieCollectionViewController : SelfieEditDelegate {
    func pushDetailsViewControllerWithSelfieObject(selfieRowObj:SelfieImage!) {
        
        if let detailVC = self.storyboard?.instantiateViewControllerWithIdentifier("DetailViewController") as? DetailViewController {
            detailVC.editDelegate = self
            detailVC.selfieCustomObj = selfieRowObj
            
            // push detail view controller to the navigation stack
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    func deleteSelfieObjectFromList(selfieImgObject: SelfieImage) {
        
        if dataArray.contains(selfieImgObject) {
            dataArray.removeAtIndex(dataArray.indexOf(selfieImgObject)!)
            self.collectionView?.reloadData()
        }
        
    }
}
