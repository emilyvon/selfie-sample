//
//  ComposeViewController.swift
//  Selfie
//
//  Created by Subhransu Behera on 12/10/14.
//  Copyright (c) 2014 subhb.org. All rights reserved.
//

import UIKit

protocol SelfieComposeDelegate {
  func reloadCollectionViewWithSelfie(selfieImgObject: SelfieImage)
}

class ComposeViewController: UIViewController {
  @IBOutlet weak var thumbImgView: UIImageView!
  @IBOutlet weak var titleTextView: UITextView!
  @IBOutlet weak var activityIndicatorView: UIView!
  
  var thumbImg : UIImage!
  var composeDelegate:SelfieComposeDelegate! = nil
  let httpHelper = HTTPHelper()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // do any additional setup after loading the view
    titleTextView.becomeFirstResponder()
    thumbImgView.image = thumbImg
    automaticallyAdjustsScrollViewInsets = false
    activityIndicatorView.layer.cornerRadius = 10
    
    setNavigationItems()
    
  }
  
  func setNavigationItems() {
    self.title = "Compose"
    
    let cancelBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ComposeViewController.cancelBtnTapped))
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem
    
    let postBarButtonItem = UIBarButtonItem(title: "Post", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ComposeViewController.postBtnTapped))
    self.navigationItem.rightBarButtonItem = postBarButtonItem
  }
  
  func cancelBtnTapped() {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func displayAlertMessage(alertTitle:String, alertDescription:String) -> Void {
    // hide activityIndicator view and display alert message
    self.activityIndicatorView.hidden = true
    let errorAlert = UIAlertView(title:alertTitle, message:alertDescription, delegate:nil, cancelButtonTitle:"OK")
    errorAlert.show()
  }
  
  func postBtnTapped() {
    
    // resign the keyboard for the text view
    titleTextView.resignFirstResponder()
    activityIndicatorView.hidden = false
    
    // create multipart upload request
    let imgData: NSData = UIImagePNGRepresentation(thumbImg)!
    let httpRequest = httpHelper.uploadRequest("upload_photo", data: imgData, title: self.titleTextView.text)
    
    httpHelper.sendRequest(httpRequest) { (data: NSData!, error: NSError!) in
        if error != nil {
            let errorMsg = self.httpHelper.getErrorMessage(error)
            self.displayAlertMessage("Error", alertDescription: errorMsg as String)
            return
        }
        
        do {
        let jsonDataDict = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as! NSDictionary
        let selfieImgObjNew = SelfieImage()
            selfieImgObjNew.imageTitle = jsonDataDict.valueForKey("title") as! String
            selfieImgObjNew.imageId = jsonDataDict.valueForKey("random_id") as! String
            selfieImgObjNew.imageThumbnailURL = jsonDataDict.valueForKey("image_url") as! String
            
            self.composeDelegate.reloadCollectionViewWithSelfie(selfieImgObjNew)
            self.activityIndicatorView.hidden = true
            self.dismissViewControllerAnimated(true, completion: nil)
            
        
        } catch {
            print("postBtnTapped error: \(error)")
        }
        
    }
    
  }

}
