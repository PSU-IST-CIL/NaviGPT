import SwiftUI
import MapKit

struct MapsView: View {
    @Binding var userLocation: String?
    @Binding var searchQuery: String
    @ObservedObject var mapsManager: MapsManager

    var body: some View {
        Group {
            if mapsManager.userRegion.center.latitude != 0 && mapsManager.userRegion.center.longitude != 0 {
                PolylineOverlay(polyline: mapsManager.routePolyline, userLocation: $mapsManager.userRegion.center)
                    .onAppear {
                        mapsManager.requestLocation()
                    }
            } else {
                Text("Loading location...")
                    .onAppear {
                        mapsManager.requestLocation()
                    }
            }
        }
        .onChange(of: mapsManager.userRegion) { oldRegion, newRegion in
            let location = CLLocation(latitude: newRegion.center.latitude, longitude: newRegion.center.longitude)
            mapsManager.getAddress(from: location) { address in
                DispatchQueue.main.async {
                    userLocation = address
                }
            }
        }
    }
}

// Include PolylineOverlay here or ensure it's accessible
struct PolylineOverlay: UIViewRepresentable {
    var polyline: MKPolyline?
    @Binding var userLocation: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()

        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.showsUserLocation = true
        mapView.mapType = .standard  // Adjust map type as needed

        let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: false)
        mapView.delegate = context.coordinator

        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)

        mapView.removeOverlays(mapView.overlays)
        if let polyline = polyline {
            mapView.addOverlay(polyline, level: .aboveRoads)
            let rect = polyline.boundingMapRect
            mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25), animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.cyan
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
