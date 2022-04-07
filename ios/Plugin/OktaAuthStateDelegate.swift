//
//  OktaAuthStateDelegate.swift
//  CapacitorOkta
//
//  Created by Rubén Panadero Navarrete on 6/4/22.
//

protocol OktaAuthStateDelegate {
    func onOktaAuthStateChange(authState: [String:Any])
}
