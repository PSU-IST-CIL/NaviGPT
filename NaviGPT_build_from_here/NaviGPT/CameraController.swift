//
//  CameraController.swift
//  Intern1
//
//  Created by Albert He ZHANG on 9/24/24.
//
import Foundation
import Combine

class CameraController: ObservableObject {
    var coordinator: LiDARCameraView.Coordinator?
    
    func capturePhoto() {
        coordinator?.capturePhoto()
    }
}

