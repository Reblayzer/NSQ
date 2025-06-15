const { ApolloServer } = require('apollo-server');
const fs = require('fs');
const path = require('path');
const { MongoClient } = require('mongodb');
// your existing URI and client:
const uri = 'mongodb+srv://bolfaalexandro:zWmeMCRdThpCSvt6@nsq.9wtyj.mongodb.net/';
const client = new MongoClient(uri, { useUnifiedTopology: true });

async function start() {
  await client.connect();
  const db = client.db('assignment2');    // ← match your code’s db name

  const server = new ApolloServer({
    typeDefs: fs.readFileSync(path.join(__dirname, 'question6.graphql'), 'utf8'),
    resolvers: require('./resolvers'),
    context: () => ({ db })               // ← so every resolver gets { db }
  });

  server.listen().then(({ url }) =>
    console.log(`🚀 Server ready at ${url}/graphql`)
  );
}

start().catch(err => {
  console.error(err);
  process.exit(1);
});







const session = client.startSession();
try {
  session.startTransaction();

  // …multiple inserts/updates here…
  await session.commitTransaction();
} catch (err) {
  await session.abortTransaction();
} finally {
  session.endSession();
}




