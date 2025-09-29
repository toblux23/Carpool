//
//  Ride.swift
//  Briones_Carpool
//
//  Created by STUDENT on 9/29/25.
//
import Foundation

struct Ride: Identifiable {
    var id: String
    let fromLocation: String
    let toLocation: String
    let departureTime: String
    let arrivalTime: String
    let travelFee: Int
    let seatsAvailable: Int
    let timeToTravel: String
    let driverId: String
    var driverName: String?
    var driverImageData: Data?
}
