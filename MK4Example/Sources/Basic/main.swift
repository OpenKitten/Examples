// Used for `Date`
import Foundation

// Import MongoKitten, so this project can access the library's features
import MongoKitten

// Connect to the database
let db = try Database("mongodb://localhost/example-database-name")

// Subscript the database to access a collection
// Collections are the MongoDB equivalent of an SQL "table"
let usersCollection = db["users"]

// Collections don't *need* to have a schema set up. Not in advance, not ever.
// So you can just create data from the get-go

// First, create a Document for a new user
// All data in MongoDB is stored as a Document
var user = Document()

// Documents are like a Dictionary, but with more restricted types
// You can put most common Swift types in there
user["username"] = "root"

// You can nest Documents
user["profile"] = [
    // And keys can contain spaces
    // They are, however, case sensitive
    "First Name": "Joannis",
    
    // This is how keys are usually written, but there is no "official" standard
    "lastName": "Orlandos",
    
    // Documents can be nested recursively to no end
    "details": [
        // `Int32` and `Int64` are both supported
        // The standard `Int` Swift uses, is an Int64 on almost all platforms
        "age": Int32(21),
        
        "admin": true
    ],
    
    "registerDate": Date(),
    
    // MongoDB also supports arrays!
    "favouriteNumbers": [1, 2, 3, 4, 5]
]

// When you've constructed your Document, let's insert it!
// But hey, what's this?
// MongoKitten generated an identifier for your object since you didn't create one yourself
// The identifiers are stored in the "_id" field.
let id = try usersCollection.insert(user)

// We now have 1 user in the database!
print("users: ", try usersCollection.count())

// ObjectId is a unique identifier. It's almost impossible to generate colliding ObjectIds.
// However, they're not really random. So don't use them for session tokens as they'll be guessed.
// That way people can steal each other's sessions and accounts
guard var userId = ObjectId(id) else {
    print("MongoKitten always generates an ObjectId for you")
    exit(1)
}

// If you ever need to publically expose this id, you can represent it as a hexString
print("userid: ", userId.hexString)

// And convert it back
userId = try ObjectId(userId.hexString)



#if os(macOS)
    // Used for sleep()
    import Darwin
#else
    // Used for sleep()
    import Glibc
#endif

// Let's wait a second, for MongoDB to write the user to the database, just to be sure!
sleep(1)



// Let's find our user in the database
// We'll need to construct a simple query for this
guard var userDocument = try usersCollection.findOne("_id" == userId) else {
    print("We just creates this entity, so it will exist for sure")
    exit(1)
}

// To extract data from a Document is easy.
// But as you might've noticed, this is a `Primitive`.
// Documents can contain any Primitive type, so you'll need to check what value there is, first
guard let primitive: Primitive = userDocument["_id"] else {
    print("All entities contain an '_id' field. This one *must* have one, too")
    exit(1)
}

// To extract a concrete Primitive type you can initialize the type from the extracted Primitive
// From here on we can do it much simpler
guard let objectId = ObjectId(primitive) else {
    print("This user had it's '_id' generated, so it's definitely an ObjectID")
    exit(1)
}

// Well, we've got our user back from the database, but I want to read the username, first name and age
// Also, I need to check if it's an admin

// Let's do that simpler, shall we?
guard let username = String(userDocument["username"]) else {
    print("The user does contain a username, we're sure of that")
    exit(1)
}

// Documents are often nested inside each other for structure
// Extracting nested documents costs little performance, so can be done plenty
// We've also make the syntax nicer compared to Dictionary.
// No iffy `["chained"]?["optional"]?["extraction"]`
guard let firstName = String(userDocument["profile"]["First Name"]) else {
    print("Again, we know that the user contains this key for sure, but in production you can't assume that!")
    exit(1)
}

// If you want a little more performance for recursive subscripts, you can do a single subscript with comma separation
guard let age = Int(userDocument["profile", "details", "age"]) else {
    print("..")
    exit(1)
}

// But hey, wasn't "age" an Int32?!
//
// BSON's Primitive initializers loosely convert the value to your requested type
// So Int32 can be converted to Int64, and the other way around can work, too
// Many other BSON types loosely convert to one another
//
// As a demonstration, this is how you make sure the type is strict
guard let admin = userDocument["profile"]["details"]["admin"] as? Bool else {
    print("..")
    exit(1)
}

// So suppose, you need to change this user's `admin` status? Let's bring him down!
// This works similar to a query + insert

// Sorry man :(
userDocument["profile"]["details"]["admin"] = false

// As you see, we're providing the whole update Document here, not just the changed values
try usersCollection.update("_id" == objectId, to: userDocument)

// If you want to change just a few of the values you'll need to use a `$set` operator
try usersCollection.update("_id" == objectId, to: [
    "$set": [
        // This'll only overwrite the "username" key
        "username": "notsorootnow"
    ]
])

// So let's remove any peasants that aren't an admin now!
try usersCollection.remove("username" == "notsorootnow")

// And that's the basics!

