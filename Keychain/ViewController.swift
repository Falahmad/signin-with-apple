//
//  ViewController.swift
//  Keychain
//
//  Created by Fahed Al-Ahmad on 9/22/19.
//  Copyright © 2019 Fahed Al-Ahmad. All rights reserved.
//

import UIKit
import LocalAuthentication
import AuthenticationServices

class ViewController: UIViewController {
    
    private lazy var authButton:ASAuthorizationAppleIDButton = {
        let btn = ASAuthorizationAppleIDButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress(_:)), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkUserAuth()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupAutolayouts()
    }
    
    private func setupViews() {
        view.addSubview(authButton)
    }
    
    private func setupAutolayouts() {
        NSLayoutConstraint.activate([
            authButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            authButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            authButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            authButton.heightAnchor.constraint(equalToConstant: 58)
        ])
    }
    
    func checkUserAuth() {
        do {
            guard let userIdentifier = try Keychain(account: .userIdentifier).load() else { return }
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: userIdentifier) { (credentialState, error) in
                switch credentialState {
                case .authorized:
                    print("Auth")
                case .revoked:
                    print("Revoked")
                case .notFound:
                    print("Not found")
                default:
                    break
                }
            }
        } catch let err {
            print(err)
        }
    }
}

// MARK:- Actions
extension ViewController {
    @objc private func handleAuthorizationAppleIDButtonPress(_ sender:ASAuthorizationAppleIDButton) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension ViewController: ASAuthorizationControllerDelegate {
    /// - Tag: did_complete_authorization
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            
            // Create an account in your system.
            let userIdentifier = appleIDCredential.user
            
            do {
                try Keychain.init(account: .userIdentifier).save(dataToInsert: userIdentifier)
                if let fullName = appleIDCredential.fullName, let firstName = fullName.givenName, let lastName = fullName.familyName {
                    let name = firstName + " " + lastName
                    UserDefaults.standard.set(name, forKey: "UserFullName")
                    UserDefaults.standard.synchronize()
                }
                if let emailAddress = appleIDCredential.email {
                    UserDefaults.standard.set(emailAddress, forKey: "UserEmailAddress")
                    UserDefaults.standard.synchronize()
                }
            } catch let err {
                print(err)
            }
            
        default:
            break
        }
    }
}

extension ViewController: ASAuthorizationControllerPresentationContextProviding {
    /// - Tag: provide_presentation_anchor
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
