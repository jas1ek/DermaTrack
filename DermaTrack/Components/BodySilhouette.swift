
import SwiftUI

enum BodySilhouetteStyle: String, CaseIterable, Identifiable {
    case male = "male"
    case female = "female"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: return "Męska"
        case .female: return "Damska"
        }
    }
}

struct BodySilhouette: Shape {
    var style: BodySilhouetteStyle = .male

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height

        func area(
            _ x: CGFloat,
            _ y: CGFloat,
            _ width: CGFloat,
            _ height: CGFloat
        ) -> CGRect {
            CGRect(
                x: rect.minX + x * w,
                y: rect.minY + y * h,
                width: width * w,
                height: height * h
            )
        }

        // Głowa
        path.addEllipse(
            in: area(0.41, 0.025, 0.18, 0.15)
        )

        // Szyja
        path.addRoundedRect(
            in: area(0.465, 0.16, 0.07, 0.075),
            cornerSize: CGSize(width: 5, height: 5)
        )

        switch style {
        case .male:
            // Szersze barki i tułów
            path.addRoundedRect(
                in: area(0.32, 0.22, 0.36, 0.31),
                cornerSize: CGSize(width: 20, height: 20)
            )

            // Biodra
            path.addRoundedRect(
                in: area(0.345, 0.49, 0.31, 0.11),
                cornerSize: CGSize(width: 12, height: 12)
            )

            // Ramiona
            path.addRoundedRect(
                in: area(0.205, 0.235, 0.105, 0.33),
                cornerSize: CGSize(width: 15, height: 15)
            )

            path.addRoundedRect(
                in: area(0.69, 0.235, 0.105, 0.33),
                cornerSize: CGSize(width: 15, height: 15)
            )

        case .female:
            // Nieco węższe barki
            path.addRoundedRect(
                in: area(0.345, 0.22, 0.31, 0.29),
                cornerSize: CGSize(width: 22, height: 22)
            )

            // Szersze biodra
            path.addRoundedRect(
                in: area(0.325, 0.48, 0.35, 0.13),
                cornerSize: CGSize(width: 18, height: 18)
            )

            // Ramiona
            path.addRoundedRect(
                in: area(0.225, 0.245, 0.105, 0.32),
                cornerSize: CGSize(width: 15, height: 15)
            )

            path.addRoundedRect(
                in: area(0.67, 0.245, 0.105, 0.32),
                cornerSize: CGSize(width: 15, height: 15)
            )
        }

        // Nogi - wspólny układ współrzędnych
        path.addRoundedRect(
            in: area(0.35, 0.56, 0.13, 0.39),
            cornerSize: CGSize(width: 15, height: 15)
        )

        path.addRoundedRect(
            in: area(0.52, 0.56, 0.13, 0.39),
            cornerSize: CGSize(width: 15, height: 15)
        )

        // Stopy
        path.addRoundedRect(
            in: area(0.335, 0.93, 0.15, 0.045),
            cornerSize: CGSize(width: 8, height: 8)
        )

        path.addRoundedRect(
            in: area(0.515, 0.93, 0.15, 0.045),
            cornerSize: CGSize(width: 8, height: 8)
        )

        return path
    }
}
