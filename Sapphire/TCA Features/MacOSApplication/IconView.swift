//
//  MacOSApplicationIconView.swift
//  Sapphire
//
//  Created by Kody Deda on 5/20/21.
//

import SwiftUI
import ComposableArchitecture

struct IconView: View {
    let store: Store<MacOSApplication.State, MacOSApplication.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            ImageView(url: viewStore.icon)
                .padding(.bottom, 3)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color.red.opacity(viewStore.customized ? 1 : 0))
                )
            
//            ZStack {
//                RoundedRectangle(cornerRadius: 10)
//                    .foregroundColor(Color.white)
//                    .opacity(viewStore.customized ? 1 : 0)
//                    .padding(viewStore.customized ? 4 : 0)
//                                                                                       
//                ImageView(url: viewStore.icon)
//                    .padding(viewStore.customized ? 8 : 0)
//            }
//            .padding(.bottom, 3)
        }
    }
}

struct MacOSApplicationIconView_Previews: PreviewProvider {
    static var previews: some View {
        IconView(store: MacOSApplication.defaultStore)
    }
}

// MARK:- ImageView
// Loads images really fast.

import FetchImage

fileprivate struct ImageView: View {
    let url: URL
    @StateObject private var image = FetchImage()

    var body: some View {
        ZStack {
            image.view?
                .resizable()
                .scaledToFill()
                .clipped()
        }
        .onAppear { image.load(url) }
    }
}
