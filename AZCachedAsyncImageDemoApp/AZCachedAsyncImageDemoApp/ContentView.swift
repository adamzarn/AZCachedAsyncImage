//
//  ContentView.swift
//  AZCachedAsyncImageDemoApp
//
//  Created by Adam Zarn on 8/2/22.
//

import SwiftUI
import AZCachedAsyncImage

struct ContentView: View {
    let ids: [String] = ["1", "10", "100", "1000", "1001", "1002", "1003", "1004", "1005", "1006",
        "1008", "1009", "1010", "1011", "1012", "1013", "1014", "1015", "1016", "1018"]
    
    var body: some View {
        VStack {
            List(ids, id: \.self) { id in
                HStack {
                    Spacer()
                    AZCachedAsyncImage(url: URL(string: "https://picsum.photos/id/\(id)/4000")!,
                                       size: CGSize(width: 300, height: 300),
                                       content: { image in
                        image
                            .resizable()
                            .frame(width: UIScreen.main.bounds.width,
                                   height: UIScreen.main.bounds.width)
                    }, placeholder: {
                        Rectangle()
                            .fill(.gray)
                            .frame(width: UIScreen.main.bounds.width,
                                   height: UIScreen.main.bounds.width)
                    })
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
            }
            .listStyle(.plain)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
