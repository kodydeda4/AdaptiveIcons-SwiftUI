//
//  FireStore + Extensions.swift
//  Sapphire
//
//  Created by Kody Deda on 6/2/21.
//

import Firebase
import Combine

extension Firestore {
    enum DBError: Error, Equatable {
        case fetch
        case add
        case set
    }

    func fetchData<A>(ofType: A.Type, from collection: String) -> AnyPublisher<Result<[A], DBError>, Never> where A: Codable {
        let rv = PassthroughSubject<Result<[A], DBError>, Never>()
        
        self.collection(collection).addSnapshotListener { querySnapshot, error in
            if let values = querySnapshot?
                .documents
                .compactMap({ try? $0.data(as: A.self) }) {
                
                rv.send(.success(values))
                
            } else {
                rv.send(.failure(.fetch))
            }
        }
        
        return rv.eraseToAnyPublisher()
    }
    
    func add<A>(_ value: A, to collection: String) where A: Codable {
        do {
            let _ = try self.collection(collection).addDocument(from: value)
        }
        catch {
            print(error)
        }
    }
    
    func remove(_ documentID: String, from collection: String) {
        self.collection(collection).document(documentID).delete { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func set<A>(_ documentID: String, to value: A, in collection: String) where A: Codable {
        do {
            try self
                .collection(collection)
                .document(documentID)
                .setData(from: value)
        }
        catch {
            print(error)
        }
    }
}