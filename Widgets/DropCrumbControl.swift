import AppIntents
import SwiftUI
import WidgetKit

/// A Control Center / Lock Screen button (and Action Button option) that opens Breadcrumb listening.
struct DropCrumbControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.mirasruslan.breadcrumb.drop") {
            ControlWidgetButton(action: OpenCaptureIntent()) {
                Label("Breadcrumb", systemImage: "mic.fill")
            }
        }
        .displayName("Drop a Breadcrumb")
        .description("Say what you're about to do, before you forget it.")
    }
}
