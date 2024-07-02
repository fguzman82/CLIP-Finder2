//
//  CoreDataManager.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 24/06/24.
//

import CoreData
import CoreML

//class CoreDataManager {
//    static let shared = CoreDataManager()
//    
//    private init() {}
//    
//    lazy var persistentContainer: NSPersistentContainer = {
//        let container = NSPersistentContainer(name: "PhotosDB")
//        container.loadPersistentStores { description, error in
//            if let error = error {
//                fatalError("Failed to load Core Data stack: \(error)")
//            }
//            print("Core Data store location: \(description.url?.absoluteString ?? "No URL")")
//        }
//        return container
//    }()
//    
//    var context: NSManagedObjectContext {
//        return persistentContainer.viewContext
//    }
//    
//    func saveVector(_ vector: MLMultiArray, for identifier: String) {
//        let newVector = ProcessedPhoto(context: context)
//        newVector.id = identifier
//        newVector.vectorData = vector
//        
//        saveContext()
//    }
//
//    func fetchVector(for identifier: String) -> MLMultiArray? {
//        let fetchRequest: NSFetchRequest<ProcessedPhoto> = ProcessedPhoto.fetchRequest()
//        fetchRequest.predicate = NSPredicate(format: "id == %@", identifier)
//        
//        do {
//            let results = try context.fetch(fetchRequest)
//            return results.first?.vectorData as? MLMultiArray
//        } catch {
//            print("Failed to fetch vector: \(error)")
//            return nil
//        }
//    }
//    
//    func deleteAllData() {
//        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ProcessedPhoto.fetchRequest()
//        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//
//        do {
//            try context.execute(deleteRequest)
//            try context.save()
//            print("All data deleted successfully")
//        } catch {
//            print("Failed to delete data: \(error)")
//        }
//    }
//
//    func saveContext() {
//        if context.hasChanges {
//            do {
//                try context.save()
//            } catch {
//                let nserror = error as NSError
//                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//            }
//        }
//    }
//    
//    func fetchAllPhotoVectors() -> [(id: String, vector: MLMultiArray)] {
//        let fetchRequest: NSFetchRequest<ProcessedPhoto> = ProcessedPhoto.fetchRequest()
//        do {
//            let results = try context.fetch(fetchRequest)
//            return results.compactMap {
//                if let vectorData = $0.vectorData as? MLMultiArray {
//                    return (id: $0.id ?? "", vector: vectorData)
//                }
//                return nil
//            }
//        } catch {
//            print("Failed to fetch photo vectors: \(error)")
//            return []
//        }
//    }
//
//    
//}

//extension CoreDataManager {
//    func deleteAllData() async throws {
//        return try await withCheckedThrowingContinuation { continuation in
//            context.perform {
//                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ProcessedPhoto.fetchRequest()
//                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//
//                do {
//                    try self.context.execute(deleteRequest)
//                    try self.context.save()
//                    print("All data deleted successfully")
//                    continuation.resume()
//                } catch {
//                    print("Failed to delete data: \(error)")
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//}

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PhotosDB")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func backgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    func saveVector(_ vector: MLMultiArray, for identifier: String, in context: NSManagedObjectContext) {
        context.perform {
            // Primero, verificamos si ya existe un ProcessedPhoto con este identificador
            let fetchRequest: NSFetchRequest<ProcessedPhoto> = ProcessedPhoto.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", identifier)
            
            do {
                let existingPhotos = try context.fetch(fetchRequest)
                let processedPhoto: ProcessedPhoto
                
                if let existingPhoto = existingPhotos.first {
                    // Si existe, actualizamos el vector
                    processedPhoto = existingPhoto
                } else {
                    // Si no existe, creamos uno nuevo
                    processedPhoto = ProcessedPhoto(context: context)
                    processedPhoto.id = identifier
                }
                
                processedPhoto.vectorData = vector
                
                try context.save()
            } catch {
                print("Failed to save vector: \(error)")
            }
        }
    }

    func fetchVector(for identifier: String, in context: NSManagedObjectContext) -> MLMultiArray? {
        var result: MLMultiArray?
        context.performAndWait {
            let fetchRequest: NSFetchRequest<ProcessedPhoto> = ProcessedPhoto.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", identifier)
            
            do {
                let results = try context.fetch(fetchRequest)
                result = results.first?.vectorData as? MLMultiArray
            } catch {
                print("Failed to fetch vector: \(error)")
            }
        }
        return result
    }
    

    func deleteAllData() {
        let context = backgroundContext()
        context.performAndWait {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ProcessedPhoto.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                let objectIDArray = result?.result as? [NSManagedObjectID] ?? []
                
                let changes = [NSDeletedObjectsKey: objectIDArray]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.viewContext])
                
                try context.save()
                print("All data deleted successfully")
            } catch {
                print("Failed to delete data: \(error)")
            }
        }
    }

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func fetchAllPhotoVectors() -> [(id: String, vector: MLMultiArray)] {
        let context = backgroundContext()
        var results: [(id: String, vector: MLMultiArray)] = []
        
        context.performAndWait {
            let fetchRequest: NSFetchRequest<ProcessedPhoto> = ProcessedPhoto.fetchRequest()
            do {
                let fetchedResults = try context.fetch(fetchRequest)
                results = fetchedResults.compactMap { photo -> (id: String, vector: MLMultiArray)? in
                    guard let id = photo.id, let vector = photo.vectorData as? MLMultiArray else { return nil }
                    return (id: id, vector: vector)
                }
            } catch {
                print("Failed to fetch photo vectors: \(error)")
            }
        }
        
        return results
    }
}



