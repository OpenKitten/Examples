import MongoKitten

let db = try Database("mongodb://localhost/example-database-name")

// Anyone who has programmed a lot knows that separating code is a good thing
// Unmaintainable spaghetti code is horrible, but database drivers don't help
// You need a model, but the conversion process is tedious, right?
class User {
    var _id = ObjectId()
    var username: String
    
    static var collection = db["users"]
    
    // Deserialization is tedious..
    init?(from document: Document) {
        guard
            let _id = ObjectId(document["_id"]),
            let username = String(document["username"]) else {
            return nil
        }
        
        self._id = _id
        self.username = username
    }
    
    // As is serialization...
    func serialize() -> Document {
        return [
            "_id": _id,
            "username": username
        ]
    }
}

// and now we need to write all these complex find queries and map them!!
// Well, yes, but no.
// Although it's tedious, Swift 4 with Codables will remove serialization boilerplate
// And we've got an ORM for you called Meow ( https://github.com/OpenKitten/Meow )
// But if you want to do it yourself.. let's dive in, it's not tough!

// Every advanced Swift user loves `map` and `flatMap`, so we added it efficiently and lazily to MongoKitten
let users: CollectionSlice<User> = try User.collection.find().flatMap(transform: User.init)

// This will keep only 300 entities in the memory at a time and fetch more when needed
for user in users {
    // And you get type-safety!
    print(user.username)
}

extension User {
    func save() throws {
        // Upsert helps a tonne, too!
        try User.collection.update("_id" == _id, to: self.serialize(), upserting: true)
    }
    
    func remove() throws {
        // And removing isn't complex, either
        try User.collection.remove("_id" == _id)
    }
}

// And that's it!
