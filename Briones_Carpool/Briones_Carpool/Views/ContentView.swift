//
//  ContentView.swift
//  Briones_Carpool
//
//  Created by STUDENT on 9/2/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
            NavigationStack{
                VStack(spacing: 0) {
                    
                    HStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .resizable()
                            .frame(width: 48, height: 36)
                            .foregroundColor(.blue)
                        
                        HStack(spacing: 0) {
                            Text("U")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("RIDE")
                                .font(.headline)
                                .foregroundColor(Color(red: 128 / 255, green: 0 / 255, blue: 0 / 255))
                        }
                    }
                    .padding(.top, 32)
                    
                    VStack(alignment: .trailing) {
                        Text("Have fun sharing rides")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 24)
                            .padding(.leading, 18)
                        Text("Get to your destination with ease")
                            .font(.title3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 18)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                        
                        Text("sharing the road and saving together.")
                            .font(.title3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                    }
                    .padding(.top, 32)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        NavigationLink(destination:AuthContainerView().environmentObject(AuthViewModel())
) {
                            Text("Get Started")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .padding(.horizontal, 40)
                                .background(Color(red: 128 / 255, green: 0, blue: 0))
                                .cornerRadius(15)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 24)
                        .padding(.horizontal)
                    }
                    
                    Image("landing_image")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 500)
                        .padding(.bottom, 28)
            }
        }
    }
}

#Preview {
    ContentView()
}

