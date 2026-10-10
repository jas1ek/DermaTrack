
import SwiftUI

struct BodySilhouette: Shape {
    func path(in rect: CGRect) -> Path {
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

        var path = Path()

        // Głowa
        path.addEllipse(
            in: area(0.41, 0.025, 0.18, 0.15)
        )

        // Szyja
        path.addRoundedRect(
            in: area(0.465, 0.16, 0.07, 0.075),
            cornerSize: CGSize(width: 5, height: 5)
        )

        // Tułów
        path.addRoundedRect(
            in: area(0.32, 0.22, 0.36, 0.31),
            cornerSize: CGSize(width: 22, height: 22)
        )

        // Ramiona
        path.addRoundedRect(
            in: area(0.205, 0.235, 0.105, 0.33),
            cornerSize: CGSize(width: 16, height: 16)
        )

        path.addRoundedRect(
            in: area(0.69, 0.235, 0.105, 0.33),
            cornerSize: CGSize(width: 16, height: 16)
        )

        // Biodra
        path.addRoundedRect(
            in: area(0.345, 0.49, 0.31, 0.11),
            cornerSize: CGSize(width: 13, height: 13)
        )

        // Nogi
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
