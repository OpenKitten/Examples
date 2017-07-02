import PackageDescription

let package = Package(
    name: "MK4Example",
    dependencies: [
        .Package(url: "https://github.com/OpenKitten/MongoKitten.git", majorVersion: 4)
    ]
)
