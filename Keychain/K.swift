//
//  K.swift
//  Keychain
//
//  Created by Fahed Al-Ahmad on 7/29/20.
//  Copyright © 2020 Fahed Al-Ahmad. All rights reserved.
//

import Foundation
import Security

enum KeychainErrors:Error {
    case notFound
    case notAvailable
    case defaultErr
}

class Keychain {
    
    enum KeychainAccounts: String {
        case password
        case token
        case userIdentifier
    }
    
//    private let service = "fahed.com".data(using: .utf8)!
    private let service = "fahed.com"
    private let account:KeychainAccounts
//    private var privateKey:SecKey?
    
    init(account:KeychainAccounts) {
        self.account = account
//        do {
//            let privateKey = try loadPrivateKey()
//            guard privateKey == nil else {
//                self.privateKey = privateKey
//                return
//            }
//            try setprivateKey()
//        } catch let err {
//            print(err)
//        }
    }
    
//    private func setprivateKey() throws {
//        let attributes: [String: Any] =
//            [kSecAttrKeyType as String:            kSecAttrKeyTypeRSA,
//             kSecAttrKeySizeInBits as String:      2048,
//             kSecPrivateKeyAttrs as String:
//                [kSecAttrIsPermanent as String:    true,
//                 kSecAttrApplicationTag as String: tag]
//        ]
//        var error: Unmanaged<CFError>?
//        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
//            throw error!.takeRetainedValue() as Error
//        }
//        self.privateKey = privateKey
//
//        let addquery: [String: Any] = [
//            kSecClass as String: kSecClassGenericPassword,
//            kSecAttrApplicationTag as String: tag,
//            kSecValueRef as String: privateKey
//        ]
//
//        SecItemAdd(addquery as CFDictionary, nil)
//    }
//
//    private func loadPrivateKey() throws -> SecKey? {
//        let getquery: [String: Any] = [kSecClass as String: kSecClassKey,
//        kSecAttrApplicationTag as String: tag,
//        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
//        kSecReturnRef as String: true]
//
//        var item: CFTypeRef?
//        let status = SecItemCopyMatching(getquery as CFDictionary, &item)
//        guard status == errSecSuccess else {
//            return nil
//        }
//        let key = item as! SecKey
//        return key
//    }
    
    private func getQuery()->[String:Any] {
        return [
            kSecClass as String             : kSecClassGenericPassword,
            kSecAttrAccount as String       : account.rawValue,
            kSecAttrService as String       : service,
            kSecAttrSynchronizable as String: kCFBooleanTrue!
        ]
    }
    
    func save(dataToInsert: String) throws {
        let data = dataToInsert.data(using: .utf8)!
        var query = getQuery()
        var status:OSStatus = noErr
        do {
            let _ = try load()
            var attributesToUpdate = [String: AnyObject]()
            attributesToUpdate[kSecValueData as String] = data as AnyObject?
            status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        } catch {
            query[kSecValueData as String] = data as AnyObject?
            status = SecItemAdd(query as CFDictionary, nil)
        }
        
        switch status {
        case noErr:
            print("Success")
            return
        default:
            print(status)
            throw KeychainErrors.defaultErr
        }
    }

    func load() throws -> String? {
        var query = getQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        switch status {
        case errSecNotAvailable:
            throw KeychainErrors.notAvailable
        case errSecItemNotFound:
            throw KeychainErrors.notFound
        case noErr:
            guard let existingItem = queryResult as? [String: AnyObject] else { return nil }
            guard let data = existingItem[kSecValueData as String] as? Data else { return nil }
            return String(data: data, encoding: String.Encoding.utf8)
        default:
            print(status)
            throw KeychainErrors.defaultErr
        }
    }
    
    func delete() throws {
        let query = getQuery()
        var status:OSStatus = noErr
        
        SecItemDelete(query as CFDictionary)
        
        switch status {
        case noErr:
            print("Success")
            return
        default:
            print(status)
            throw KeychainErrors.defaultErr
        }
    }
}
