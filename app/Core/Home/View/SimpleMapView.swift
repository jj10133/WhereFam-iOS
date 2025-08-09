//
//  SimpleMapView.swift
//  WhereFam
//
//  Created by joker on 2025-08-08.
//

import MapLibre
import SwiftUI

struct SimpleMapView: UIViewRepresentable {
    @EnvironmentObject var ipcViewModel: IPCViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MLNMapView {
//        guard let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") else {
//            fatalError("Failed to find style.json in the app bundle.")
//        }
        
        let styleURL = URL(string: "https://tiles.openfreemap.org/styles/liberty")
        
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        return mapView
    }
    
    func updateUIView(_ uiView: MLNMapView, context: Context) {
       updateAnnotations(for: uiView)
    }
    
    private func updateAnnotations(for mapView: MLNMapView) {
        var newAnnotations = [MLNAnnotation]()
        for (id, locationUpdate) in ipcViewModel.updatedPeopleLocation {
            if let lat = locationUpdate.latitude, let lon = locationUpdate.longitude {
                let annotation = PersonAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                annotation.title = locationUpdate.name
                annotation.name = locationUpdate.name
                annotation.annotationID = id
                
                annotation.image = UIImage(systemName: "person.circle.fill")
                newAnnotations.append(annotation)
            }
        }
        
        if let existingAnnotations = mapView.annotations {
            mapView.removeAnnotations(existingAnnotations)
        }
        
        mapView.addAnnotations(newAnnotations)
    }
    
    class Coordinator: NSObject, MLNMapViewDelegate {
        var parent: SimpleMapView
        var hasCenteredOnce = false
        
        init(_ parent: SimpleMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MLNMapView, didUpdate userLocation: MLNUserLocation?) {
            if !hasCenteredOnce, let location = userLocation?.location {
                mapView.setCenter(location.coordinate, zoomLevel: 14.0, animated: true)
                hasCenteredOnce = true
            }
        }
        
        func mapView(_ mapView: MLNMapView, didChange mode: MLNUserTrackingMode, animated: Bool) {
            if mode != .follow {
                mapView.userTrackingMode = .none
            }
        }
        
        func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
            guard let annotation = annotation as? PersonAnnotation, let id = annotation.annotationID else {
                return nil
            }

            if let existingView = mapView.dequeueReusableAnnotationView(withIdentifier: id) {
                if let hostingController = existingView.subviews.first as? UIHostingController<AnnotationView> {
                    hostingController.rootView = AnnotationView(name: annotation.name, image: annotation.image)
                }
                return existingView
            }

            let hostingController = UIHostingController(
                rootView: AnnotationView(name: annotation.name, image: annotation.image)
            )

            let size = hostingController.view.intrinsicContentSize

            let annotationView = MLNAnnotationView(reuseIdentifier: id)
            annotationView.frame = CGRect(origin: .zero, size: size)

            hostingController.view.frame = annotationView.bounds
            hostingController.view.backgroundColor = .clear

            annotationView.addSubview(hostingController.view)

            annotationView.centerOffset = CGVector(dx: 0, dy: -size.height / 2)

            return annotationView
        }
    }
}

struct AnnotationView: View {
    let name: String?
    let image: UIImage?

    var body: some View {
        VStack(spacing: 4) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
            if let name = name {
                Text(name)
                    .font(.caption)
                    .foregroundColor(.black)
                    .padding(.horizontal, 4)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(5)
            }
        }
    }
}

class PersonAnnotation: MLNPointAnnotation {
    var name: String?
    var image: UIImage?
    var annotationID: String?
}
