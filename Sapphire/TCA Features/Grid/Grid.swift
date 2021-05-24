//
//  UserData.swift
//  Sapphire
//
//  Created by Kody Deda on 12/24/20.
//

import SwiftUI
import Combine
import ComposableArchitecture

struct Grid {
    struct State: Equatable, Codable {
        var macOSApplications : [MacOSApplication.State] = .allCases
        var inFlight = false
    }
    
    enum Action: Equatable {
        case macOSApplication(index: Int, action: MacOSApplication.Action)
        case modifyLocalIcons
        case deselectAll
        case modifyLocalIconsResult(Result<Bool, AppleScriptError>)
        case selectAllButtonTapped
        case selectModifiedButtonTapped
        case updateGridSelections(Int)
    }
    
    struct Environment {
        let iconsur = "/usr/local/bin/iconsur"
        let output = "~/Desktop/"
        
        /// Modify System Application Icons.
        func modifySystemApplicationIcons(_ applications: [MacOSApplication.State]) -> Effect<Action, Never> {
            let updateIcons = applications
                .filter(\.selected)
                .map { application in
                    let reset  = "\(iconsur) unset \\\"\(application.url.path)\\\"; "
                    let create = "\(iconsur) set \\\"\(application.url.path)\\\" -l -s 0.8 -o \(output)\(application.name).png -c \(application.color); "
                    let set    = "\(iconsur) set \\\"\(application.url.path)\\\" -l \(output)\(application.name).png; "
                    
                    return application.customized
                        ? reset
                        : [create, set].joined()
                }
                .joined()
                .appending("/usr/local/bin/iconsur cache")
            
                    
            return NSUserAppleScriptTask()
                .execute(command: "do shell script \"\(updateIcons)\" with administrator privileges")
                .map(Action.modifyLocalIconsResult)
                .receive(on: DispatchQueue.main)
                .eraseToEffect()
        }
    }
}

extension Grid {
    static let reducer = Reducer<State, Action, Environment>.combine(
        MacOSApplication.reducer.forEach(
            state: \.macOSApplications,
            action: /Action.macOSApplication(index:action:),
            environment: { _ in () }
        ),
        Reducer { state, action, environment in
            switch action {

            case let .macOSApplication(index, action):
                switch action {
                
                case .toggleSelected:
                    return Effect(value: .updateGridSelections(index))
                
                case .modifyIconButtonTapped:
                    return Effect(value: .modifyLocalIcons)
                
                default:
                    break
                }
                return .none
                
            case let .updateGridSelections(index):
                state.macOSApplications[index].selected.toggle()
                return .none

            case .modifyLocalIcons:
                state.inFlight = true
                return environment.modifySystemApplicationIcons(state.macOSApplications)
                     
            case .modifyLocalIconsResult(.success(_)):
                state.inFlight = false
                zip(state.macOSApplications.indices, state.macOSApplications)
                    .forEach { index, application in
                        if application.selected {
                            state.macOSApplications[index].icon
                                = application.customized
                                ? Bundle.icon(from: application.url)
                                : URL(fileURLWithPath: NSHomeDirectory().appending("Dark.png"))
                            
                            state.macOSApplications[index].customized.toggle()

                        }
                    }
                return Effect(value: .deselectAll)
                
            case let .modifyLocalIconsResult(.failure(error)):
                state.inFlight = false
                return Effect(value: .deselectAll)
                                                
            case .selectAllButtonTapped:
                let bool = state.macOSApplications.filter(\.selected).isEmpty
                
                state.macOSApplications.indices
                    .forEach {
                        state.macOSApplications[$0].selected = bool
                    }
                return .none
                
            case .selectModifiedButtonTapped:
                Array(zip(state.macOSApplications.indices, state.macOSApplications))
                    .forEach { index, application in
                        if application.customized {
                            state.macOSApplications[index].selected = true
                        } else {
                            state.macOSApplications[index].selected = false

                        }
                    }
                return .none
                
            case .deselectAll:
                state.macOSApplications.indices
                    .forEach { index in
                        state.macOSApplications[index].selected = false
                    }
                return .none
            }
        }
    )
}

extension Grid {
    static let defaultStore = Store(
        initialState: .init(),
        reducer: reducer,
        environment: .init()
    )
}
