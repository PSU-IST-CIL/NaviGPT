import SwiftUI
import MapKit
import AVFoundation
import Foundation

class MapsManager: NSObject, ObservableObject, CLLocationManagerDelegate, MKMapViewDelegate {
    @Published var oldDestination: String = ""
    @Published var userRegion = MKCoordinateRegion()
    @Published var directions: [MKRoute.Step] = []
    @Published var routePolyline: MKPolyline?
    private var locationManager = CLLocationManager()
    private var geocoder = CLGeocoder()
    private var lastLocation: CLLocation?
    private var initialUpdate = true
    var currentStepIndex = 0
    var navigationTimer: Timer?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        userRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            // 提示用户去设置中开启位置权限
            let utterance = AVSpeechUtterance(string: "Please enable location permissions in the settings to use the navigation function.")
            utterance.voice = AVSpeechSynthesisVoice(language: "en") // Set language if needed
            SpeechManager.shared.speak(utterance)
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        lastLocation = newLocation
        
        DispatchQueue.main.async {
            self.userRegion = MKCoordinateRegion(
                center: newLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        if !directions.isEmpty {
            checkNavigationProgress(currentLocation: newLocation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to update location: \(error.localizedDescription)")
    }
    
    func getAddress(from location: CLLocation, completion: @escaping (String?) -> Void) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            let address = placemarks?.first.map { placemark in
                [
                    placemark.name
                ].compactMap { $0 }.joined(separator: ", ")
            }
            
            DispatchQueue.main.async {
                completion(address)
            }
        }
    }
    
    func getDirections(to destination: String) {
            guard let userLocation = lastLocation else {
                return
            }

            if destination.isEmpty {
                let utterance = AVSpeechUtterance(string: "Please provide a destination address.")
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                SpeechManager.shared.speak(utterance)
                return
            }

            if self.oldDestination == destination {
                let utterance = AVSpeechUtterance(string: "\(destination) is already in navigation.")
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                SpeechManager.shared.speak(utterance)
                return
            }

            geocoder.geocodeAddressString(destination) { [self] placemarks, error in
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.speechResponse(message: destination)
                    }
                    return
                }

                guard let placemark = placemarks?.first, let destinationLocation = placemark.location else {
                    DispatchQueue.main.async {
                        self.speechResponse(message: destination)
                    }
                    return
                }

                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationLocation.coordinate))
                request.transportType = .walking
                let directions = MKDirections(request: request)
                directions.calculate { response, error in
                    if let error = error {
                        print("Directions error: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.speechResponse(message: destination)
                        }
                        return
                    }

                    guard let route = response?.routes.first else {
                        DispatchQueue.main.async {
                            self.speechResponse(message: destination)
                        }
                        return
                    }

                    DispatchQueue.main.async {
                        self.directions = route.steps.filter { !$0.instructions.isEmpty }
                        self.routePolyline = route.polyline
                        self.userRegion = MKCoordinateRegion(
                            center: userLocation.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                        let utterance = AVSpeechUtterance(string: "Starting walking navigation to \(destination).")
                        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                        SpeechManager.shared.speak(utterance)
                        self.oldDestination = destination
                        self.currentStepIndex = 0
                        self.startNavigationUpdates()
                    }
                }
            }
        }
    
    func speechResponse(message: String) {
            let utterance = AVSpeechUtterance(string: "Unable to find \(message).")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            SpeechManager.shared.speak(utterance)
        }
    
    func getCurrentStepInstruction() -> String? {
        if directions.indices.contains(currentStepIndex) {
            return directions[currentStepIndex].instructions
        }
        return nil
    }
    
    func startNavigationUpdates() {
        navigationTimer?.invalidate()
        navigationTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.provideNavigationInstructions()
        }
    }
    
    func provideNavigationInstructions() {
        if let instruction = getCurrentStepInstruction() {
            let utterance = AVSpeechUtterance(string: instruction)
            SpeechManager.shared.speak(utterance)
        }
    }
    
    func checkNavigationProgress(currentLocation: CLLocation) {
        guard currentStepIndex < directions.count else {
            navigationTimer?.invalidate()
            let utterance = AVSpeechUtterance(string: "You have arrived at your destination.")
            SpeechManager.shared.speak(utterance)
            return
        }
        
        let step = directions[currentStepIndex]
        let stepCoordinates = step.polyline.coordinate
        let distance = currentLocation.distance(from: CLLocation(latitude: stepCoordinates.latitude, longitude: stepCoordinates.longitude))
        
        if distance < 10 { // 10 米的阈值
            currentStepIndex += 1
            provideNavigationInstructions()
        }
    }
}
