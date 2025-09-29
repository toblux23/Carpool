//
//  UserProfile.swift
//  Briones_Carpool
//
//  Created by STUDENT on 9/24/25.
//
import SwiftData
import Foundation

@Model
class UserProfile {
    @Attribute var id: UUID
    @Attribute var userId: String
    @Attribute var profileImageData: Data?
    @Attribute var licenseImageData: Data?

    init(id: UUID = UUID(), userId: String, profileImageData: Data?, licenseImageData: Data?) {
        self.id = id
        self.userId = userId
        self.profileImageData = profileImageData
        self.licenseImageData = licenseImageData
    }
}
