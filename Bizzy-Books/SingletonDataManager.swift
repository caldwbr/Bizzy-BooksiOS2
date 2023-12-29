//
//  SingletonDataManager.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 12/22/23.
//

import Foundation
class SingletonDataManager {
    static let shared = SingletonDataManager()
    //var data: [YourDataType] = []

    private init() {} // Private initializer to ensure singleton usage

    func fetchData() {
        // Firebase fetch logic here
    }
}
