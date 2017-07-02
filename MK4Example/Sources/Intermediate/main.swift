import Foundation
import MongoKitten

let db = try Database("mongodb://localhost/example-database-name")

let usersCollection = db["users"]

// So in the Basics, we were able to do a full set of CRUD operations on a user
// Sometimes, however, you don't know if a user already exists. So the process is tedious
//
// - Check if the user exists (using count)
// - Insert the user if the count == 0
// - Update the user if the count > 0
//
// No more!

// First, let's generate an ObjectId of our own
let userId = ObjectId()

// And create the user Document
var user: Document = [
    "_id": userId,
    "username": "root",
    "profile": [
        "First Name": "Joannis",
        "lastName": "Orlandos",
        "details": [
            "age": Int32(21),
            "admin": true
        ],
        "registerDate": Date(),
        "favouriteNumbers": [1, 2, 3, 4, 5]
    ]
]

// By upserting, MongoDB will check based on the query if there is an entity matching this query
// If there is, an update will happen. Insert will be used otherwise.
try usersCollection.update("_id" == userId, to: user, upserting: true)

// I noticed one thing above
// The user has a registerDate, that's pretty useless..
// We can do that much simpler!
let registerDate = userId.epoch

// Alternatively, we could store the username in the _id field.
// The only requirement for `_id` is that the value is unique

let user2: Document = [
    "_id": "superuser",
    "profile": [
        "First Name": "Super",
        "lastName": "User",
        "details": [
            "age": Int32(42),
            "admin": true
        ],
        "favouriteNumbers": [3, 1, 4]
    ]
]

// Oh, by the way. This shorthand is here, too.
try usersCollection.append(user2)

// Hmm.. I don't think that was a good idea. I like keeping track of the registration date
// Let's remove the user. I do remember his username

// MongoDB can find and remove a Document in a single user.
// That will allow you to receive the removed entity after it's deleted
//
// But wait, a projection..?
let user2Doc = try usersCollection.findAndRemove("_id" == "superuser", projection: ["profile"])

// Well, yeah. MongoDB can be asked to return only a set of results for find operations
// That way you use MongoDB and the socket less intensively, increasing performance!
//
// The syntax is simple.. you provide it an array of keys that you want to return
// If you need nested keys you can use dot notation such as "profile.details"
let newUser2: Document = [
    "username": "superuser",
    "profile": user2Doc["profile"]
]

// And adding it again!
try usersCollection.append(newUser2)

// Oh, wait, I forgot to read the ObjectId. Well, we won't need it, since we'll be listing all users next!

// We don't provide a query since we'll want all entities
let slice: CollectionSlice<Document> = try usersCollection.find()

// What do we do next, you ask?
// Let's loop over them
for user in slice {
    // If we find our superuser, let's ask the _id
    guard String(user["username"]) == "superuser", let id = ObjectId(user["_id"]) else {
        continue
    }
    
    // got it!
    print("superuser's id: ", id)
}

// Well, let's clean up!
try usersCollection.remove()

// None left..
print("Users: ", try usersCollection.count())
