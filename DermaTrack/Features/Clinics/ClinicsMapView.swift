
import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct ClinicsMapView: View {

    @StateObject private var clinicService = ClinicSearchService()

    @State private var cityName = ""
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Wyszukiwanie

            VStack(spacing: 12) {

                HStack {
                    TextField("Wpisz miasto, np. Katowice", text: $cityName)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                        .onSubmit {
                            searchByCity()
                        }

                    Button("Szukaj") {
                        searchByCity()
                    }
                    .disabled(
                        cityName.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty || clinicService.isLoading
                    )
                }

                Button {
                    clinicService.searchNearUser()
                } label: {
                    Label(
                        "Znajdź gabinety w pobliżu",
                        systemImage: "location.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(clinicService.isLoading)

                if clinicService.isLoading {
                    ProgressView("Wyszukiwanie gabinetów...")
                }

                if let error = clinicService.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        if clinicService.locationPermissionDenied {
                            Button("Otwórz ustawienia lokalizacji") {
                                openAppSettings()
                            }
                            .font(.footnote)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()

            // MARK: - Mapa

            Map(position: $cameraPosition) {
                UserAnnotation()

                ForEach(clinicService.clinics, id: \.self) { clinic in
                    Marker(
                        clinic.name ?? "Gabinet dermatologiczny",
                        systemImage: "cross.case.fill",
                        coordinate: clinic.location.coordinate
                    )
                    .tint(.red)
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .frame(minHeight: 260)

            // MARK: - Lista gabinetów

            if clinicService.clinics.isEmpty {
                ContentUnavailableView(
                    "Wyszukaj gabinety",
                    systemImage: "cross.case",
                    description: Text(
                        "Możesz użyć lokalizacji lub wpisać miasto ręcznie."
                    )
                )
            } else {
                List {
                    Section(
                        "Znalezione gabinety (\(clinicService.clinics.count))"
                    ) {
                        ForEach(clinicService.clinics, id: \.self) { clinic in
                            VStack(alignment: .leading, spacing: 8) {

                                Text(
                                    clinic.name ?? "Gabinet dermatologiczny"
                                )
                                .font(.headline)

                                if let phone = clinic.phoneNumber {
                                    Text(phone)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                HStack {
                                    Button("Pokaż na mapie") {
                                        showOnMap(clinic)
                                    }
                                    .buttonStyle(.bordered)

                                    Button("Trasa") {
                                        openDirections(to: clinic)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Gabinety dermatologiczne")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: clinicService.clinics) { _, clinics in
            guard let first = clinics.first else { return }
            showOnMap(first)
        }
    }

    // MARK: - Wyszukiwanie po mieście

    private func searchByCity() {
        Task {
            await clinicService.searchInCity(cityName)
        }
    }

    // MARK: - Ustawienie mapy

    private func showOnMap(_ clinic: MKMapItem) {
        let region = MKCoordinateRegion(
            center: clinic.location.coordinate,
            latitudinalMeters: 8000,
            longitudinalMeters: 8000
        )

        withAnimation {
            cameraPosition = .region(region)
        }
    }

    // MARK: - Nawigacja Apple Maps

    private func openDirections(to clinic: MKMapItem) {
        clinic.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey:
                    MKLaunchOptionsDirectionsModeDriving
            ]
        )
    }

    // MARK: - Ustawienia iOS

    private func openAppSettings() {
        guard let url = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }

        UIApplication.shared.open(url)
    }
}
