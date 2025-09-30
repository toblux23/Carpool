//
//  Ride_Request.swift
//  Briones_Carpool
//
//  Created by STUDENT on 9/30/25.
//
import Foundation
struct RideRequest: Identifiable {
    let id: String
    let riderId: String
    let requesterName: String
    let requesterImageData: Data?
    let requestedAt: Date
    let rideId: String
    let status: String
}
