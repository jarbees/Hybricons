import SwiftUI

struct DemoView: View {
    @State private var selectedIcon = UIApplication.shared.alternateIconName
    private let appIcons: [(label: String, name: String?)] = [
        ("Legacy", "Legacy"),
        ("Modern", "Modern"),
        ("Default Icon", nil)
    ]
    
    var body: some View {
        List {
            Section {
                ForEach(appIcons, id: \.label) { icon in
                    Button {
                        changeAppIcon(to: icon.name)
                    } label: {
                        HStack {
                            Text(icon.label)
                                .foregroundStyle(Color(.label))
                            Spacer()
                            
                            if icon.name == selectedIcon {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            } header: {
                Text("App Icons")
            } footer: {
                Text("""
                     "Legacy" is an Asset Catalog .appiconset.
                     "Modern" is an Icon Composer .icon.
                     "Default Icon" is provided as both.
                     """)
            }
            
            Section {
                Image("DemoImage")
                    .resizable()
                    .scaledToFit()
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            } header: {
                Text("Demo Image")
            } footer: {
                Text("This image demonstrates that images added through asset catalogs continue working with Hybricons.")
            }
        }
        .navigationTitle("Demo App")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func changeAppIcon(to iconName: String?) {
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error {
                print("Error setting icon: \(error.localizedDescription)")
            } else {
                selectedIcon = iconName
            }
        }
    }
}

#Preview {
    NavigationView {
        DemoView()
    }
}
