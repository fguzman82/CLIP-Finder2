//
//  CoreDataManager.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 24/06/24.
//

import CoreData
import CoreML

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PhotosDB")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
            print("Core Data store location: \(description.url?.absoluteString ?? "No URL")")
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveVector(_ vector: MLMultiArray, for identifier: String) {
        let newVector = ProcessedPhoto(context: context)
        newVector.id = identifier
        newVector.vectorData = vector
        
        saveContext()
    }

    func fetchVector(for identifier: String) -> MLMultiArray? {
        let fetchRequest: NSFetchRequest<ProcessedPhoto> = ProcessedPhoto.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", identifier)
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first?.vectorData as? MLMultiArray
        } catch {
            print("Failed to fetch vector: \(error)")
            return nil
        }
    }
    
    func deleteAllData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ProcessedPhoto.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()
            print("All data deleted successfully")
        } catch {
            print("Failed to delete data: \(error)")
        }
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
//    func fetchAllVectors() -> ([String], [MLMultiArray])? {
//        let fetchRequest: NSFetchRequest<ProcessedPhoto> = ProcessedPhoto.fetchRequest()
//        
//        do {
//            let results = try context.fetch(fetchRequest)
//            let ids = results.compactMap { $0.id }
//            let vectors = results.compactMap { $0.vectorData as? MLMultiArray }
//            return (ids, vectors)
//        } catch {
//            print("Failed to fetch vectors: \(error)")
//            return nil
//        }
//    }
    
    func fetchAllPhotoVectors() -> [(id: String, vector: MLMultiArray)] {
        let fetchRequest: NSFetchRequest<ProcessedPhoto> = ProcessedPhoto.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            return results.compactMap {
                if let vectorData = $0.vectorData as? MLMultiArray {
                    return (id: $0.id ?? "", vector: vectorData)
                }
                return nil
            }
        } catch {
            print("Failed to fetch photo vectors: \(error)")
            return []
        }
    }

    
}

