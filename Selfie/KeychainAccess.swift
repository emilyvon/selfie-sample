//
//  KeychainAccess.swift
//  Jupp
//
//  Created by dasdom on 16.08.14.
//  Copyright (c) 2014 Dominik Hauser. All rights reserved.
//

import Foundation

public class KeychainAccess {
  private class func secClassGenericPassword() -> String {
    return NSString(format: kSecClassGenericPassword) as String
  }
  
  private class func secClass() -> String {
    return NSString(format: kSecClass) as String
  }
  
  private class func secAttrService() -> String {
    return NSString(format: kSecAttrService) as String
  }
  
  private class func secAttrAccount() -> String {
    return NSString(format: kSecAttrAccount) as String
  }
  
  private class func secValueData() -> String {
    return NSString(format: kSecValueData) as String
  }
  
  private class func secReturnData() -> String {
    return NSString(format: kSecReturnData) as String
  }
  
  public class func setPassword(password: String, account: String, service: String = "keyChainDefaultService") {
    let secret: NSData = password.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    let objects: Array = [secClassGenericPassword(), service, account, secret]
    
    let keys: Array = [secClass(), secAttrService(), secAttrAccount(), secValueData()]
    
    let query = NSDictionary(objects: objects, forKeys: keys)
    
    SecItemDelete(query as CFDictionaryRef)
    
    let status = SecItemAdd(query as CFDictionaryRef, nil)
  }
  
  public class func passwordForAccount(account: String, service: String = "keyChainDefaultService") -> String? {
    let queryAttributes = NSDictionary(objects: [secClassGenericPassword(), service, account, true], forKeys: [secClass(), secAttrService(), secAttrAccount(), secReturnData()])
    
//    var dataTypeRef : Unmanaged<AnyObject>?
    
    var dataTypeRef: AnyObject?
    
    let status = SecItemCopyMatching(queryAttributes, &dataTypeRef)
    
//    let status = SecItemCopyMatching(queryAttributes, dataTypeRef as! UnsafeMutablePointer<AnyObject?>)

    if dataTypeRef == nil {
      return nil
    }
    
//    let retrievedData : NSData = dataTypeRef!.takeRetainedValue() as! NSData
    
    let retrievedData: NSData = dataTypeRef as! NSData
    
    let password = NSString(data: retrievedData, encoding: NSUTF8StringEncoding)
    
    return (password as! String)
  }
  
  public class func deletePasswordForAccount(password: String, account: String, service: String = "keyChainDefaultService") {
    let secret: NSData = password.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    let objects: Array = [secClassGenericPassword(), service, account, secret]
    
    let keys: Array = [secClass(), secAttrService(), secAttrAccount(), secValueData()]
    let query = NSDictionary(objects: objects, forKeys: keys)
    
    SecItemDelete(query as CFDictionaryRef)
  }
}