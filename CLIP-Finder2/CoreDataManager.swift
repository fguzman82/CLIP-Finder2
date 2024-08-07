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
            let fetchRequest: NSFetchRequest<ProcessedPhoto> = ProcessedPhoto.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", identifier)
            
            do {
                let existingPhotos = try context.fetch(fetchRequest)
                let processedPhoto: ProcessedPhoto
                
                if let existingPhoto = existingPhotos.first {
                    processedPhoto = existingPhoto
                } else {
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
                
                if !objectIDArray.isEmpty {
                    let changes = [NSDeletedObjectsKey: objectIDArray]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.viewContext])
                }
                
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

    func fetchAllPhotoVectors() async -> [String: MLMultiArray] {
        await withCheckedContinuation { continuation in
            let context = backgroundContext()
            context.performAndWait {
                let fetchRequest: NSFetchRequest<ProcessedPhoto> = ProcessedPhoto.fetchRequest()
                do {
                    let results = try context.fetch(fetchRequest)
                    let vectors = Dictionary(uniqueKeysWithValues: results.compactMap { photo -> (String, MLMultiArray)? in
                        guard let id = photo.id, let vector = photo.vectorData as? MLMultiArray else { return nil }
                        return (id, vector)
                    })
                    continuation.resume(returning: vectors)
                } catch {
                    print("Failed to fetch photo vectors: \(error)")
                    continuation.resume(returning: [:])
                }
            }
        }
    }
    
    func deleteVectors(for identifiers: [String]) async {
        await withCheckedContinuation { continuation in
            let context = backgroundContext()
            context.performAndWait {
                let fetchRequest: NSFetchRequest<ProcessedPhoto> = ProcessedPhoto.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id IN %@", identifiers)
                
                do {
                    let results = try context.fetch(fetchRequest)
                    for photo in results {
                        context.delete(photo)
                    }
                    try context.save()
                    print("Deleted vectors for \(results.count) photos")
                } catch {
                    print("Failed to delete vectors: \(error)")
                }
                continuation.resume()
            }
        }
    }
}
