const { ApolloServer } = require("apollo-server");
const { Neo4jGraphQL } = require("@neo4j/graphql");
const neo4j = require("neo4j-driver");
const fs = require("node:fs");

const typeDefs = fs.readFileSync("./schemaDefinition.graphql", "utf8");
const driver = neo4j.driver(
	"bolt://localhost:7687",
	neo4j.auth.basic("neo4j", "qwertyui"),
);

async function start() {
	try {
		// This is where the array of GraphQLErrors will be thrown if your SDL is invalid
		const neoSchema = new Neo4jGraphQL({ typeDefs, driver });
		const schema = await neoSchema.getSchema();

		const server = new ApolloServer({
			schema,
			context: { driver },
		});

		const { url } = await server.listen(4000);
		console.log(`🚀 GraphQL ready at ${url}`);
	} catch (err) {
		// If Neo4jGraphQL or ApolloServer throws, we’ll now see the real messages:
		if (Array.isArray(err)) {
			// Neo4jGraphQL validation errors come back as an array of GraphQLError
			for (const e of err) {
				console.error(e.message);
			}
		} else {
			console.error(err);
		}
		process.exit(1);
	}
}

start();
