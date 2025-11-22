// Import MongoClient
const { MongoClient } = require("mongodb");

// Replace with your connection string
const uri =
  "mongodb+srv://fatimarashid312_db_user:b3uuBaZyml7B3u0f@cluster0.pvmvetz.mongodb.net/?appName=Cluster0";

// Create a new client
const client = new MongoClient(uri);

async function run() {
  try {
    // Connect to the cluster
    await client.connect();

    console.log("Connected to MongoDB Atlas!");

    // List databases
    const databasesList = await client.db().admin().listDatabases();
    console.log("Databases:");
    databasesList.databases.forEach((db) => console.log(` - ${db.name}`));
  } catch (err) {
    console.error(err);
  } finally {
    // Close connection
    await client.close();
  }
}

run();
