import Foundation
import Combine
import CoreLocation
import MapKit

@MainActor
final class ClinicSearchService: NSObject, ObservableObject {

    // MARK: - Stan aplikacji

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var userLocation: CLLocation?
    @Published private(set) var clinics: [MKMapItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let locationManager = CLLocationManager()
    private var pendingNearbySearch = false

    // MARK: - Inicjalizacja

    override init() {
        authorizationStatus = locationManager.authorizationStatus

        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - Pomocnicze właściwości

    var hasLocationPermission: Bool {
        authorizationStatus == .authorizedWhenInUse ||
        authorizationStatus == .authorizedAlways
    }

    var locationPermissionDenied: Bool {
        authorizationStatus == .denied ||
        authorizationStatus == .restricted
    }

    // MARK: - Lokalizacja użytkownika

    func searchNearUser() {
        errorMessage = nil
        
        switch locationManager.authorizationStatus {

        case .notDetermined:
            pendingNearbySearch = true
            locationManager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            pendingNearbySearch = true
            isLoading = true
            locationManager.requestLocation()

        case .denied, .restricted:
            pendingNearbySearch = false
            errorMessage = "Brak dostępu do lokalizacji. Możesz wyszukać gabinety po nazwie miasta."

        @unknown default:
            errorMessage = "Nieznany status uprawnienia lokalizacji."
        }
    }

    // MARK: - Ręczne wyszukiwanie po mieście

    func searchInCity(_ city: String) async {
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCity.isEmpty else {
            errorMessage = "Wpisz nazwę miasta."
            return
        }

        pendingNearbySearch = false
        locationManager.stopUpdatingLocation()

        isLoading = true
        errorMessage = nil
        clinics = []

        defer {
            isLoading = false
        }

        do {
            // Najpierw ustalamy położenie miasta.
            let cityRequest = MKLocalSearch.Request()
            cityRequest.naturalLanguageQuery = trimmedCity
            cityRequest.resultTypes = .address

            let cityResponse = try await MKLocalSearch(
                request: cityRequest
            ).start()

            guard let cityItem = cityResponse.mapItems.first else {
                errorMessage = "Nie znaleziono podanego miasta."
                return
            }

            let region = MKCoordinateRegion(
                center: cityItem.location.coordinate,
                latitudinalMeters: 12000,
                longitudinalMeters: 12000
            )

            try await searchClinics(in: region)

        } catch {
            errorMessage = "Nie udało się wyszukać gabinetów: \(error.localizedDescription)"
        }
    }

    // MARK: - Wyszukiwanie gabinetów

    private func searchClinics(
        in region: MKCoordinateRegion
    ) async throws {

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "dermatolog"
        request.region = region
        request.resultTypes = .pointOfInterest

        let response = try await MKLocalSearch(
            request: request
        ).start()

        clinics = response.mapItems

        if clinics.isEmpty {
            errorMessage = "Nie znaleziono gabinetów dermatologicznych w wybranym obszarze."
        }
    }

    // MARK: - Czyszczenie komunikatów

    func clearError() {
        errorMessage = nil
    }
}

// MARK: - CLLocationManagerDelegate

extension ClinicSearchService: @preconcurrency CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {

        case .authorizedWhenInUse, .authorizedAlways:
            if pendingNearbySearch {
                isLoading = true
                manager.requestLocation()
            }

        case .denied, .restricted:
            pendingNearbySearch = false
            isLoading = false
            errorMessage = "Odmówiono dostępu do lokalizacji. Wyszukaj gabinety ręcznie."

        case .notDetermined:
            break

        @unknown default:
            pendingNearbySearch = false
            isLoading = false
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard pendingNearbySearch,
              let location = locations.last else {
            return
        }

        pendingNearbySearch = false
        userLocation = location
        isLoading = true

        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )

        Task {
            defer {
                isLoading = false
            }

            do {
                try await searchClinics(in: region)
            } catch {
                errorMessage = "Błąd wyszukiwania gabinetów: \(error.localizedDescription)"
            }
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        pendingNearbySearch = false
        isLoading = false
        errorMessage = "Nie udało się ustalić lokalizacji: \(error.localizedDescription)"
    }
}
