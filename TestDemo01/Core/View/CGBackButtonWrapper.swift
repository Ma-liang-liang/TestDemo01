import SwiftUI

struct CGBackButtonWrapper<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Button {
                CGNavigationManager.shared.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 44, height: 44)
            }
            .padding(.leading, 8)
            .padding(.top, 4)
        }
    }
}
