// Create Authors
CREATE (a1:Author {name: "Author 1"})
CREATE (a2:Author {name: "Author 2"})

// Create Characters
CREATE (ch1:Character {name: "Character 1"})
CREATE (ch2:Character {name: "Character 2"})

// Create Categories
CREATE (cat1:Category {name: "Fiction"})
CREATE (cat2:Category {name: "Science"})

// Create Books
CREATE (b1:Book {isbn: "978-1234567890", title: "Book One", page_count: 300, rating: 4.5, genres: ["Fiction", "Adventure"], categories: ["Action", "Thriller"], characters: ["Character 1", "Character 2"]})
CREATE (b2:Book {isbn: "978-0987654321", title: "Book Two", page_count: 400, rating: 4.0, genres: ["Non-Fiction", "Science"], categories: ["Technology"], characters: []})

// Create Book Copies
CREATE (bc1:BookCopy {isbn: "978-1234567890", price: 20.0, type: "Paperback"})
CREATE (bc2:BookCopy {isbn: "978-0987654321", price: 30.0, type: "Hardcover"})

// Create Customers
CREATE (c1:Customer {name: "Customer 1", address: "123 Main St, City, 12345"})
CREATE (c2:Customer {name: "Customer 2", address: "456 Elm St, City, 67890"})

// Create Orders
CREATE (o1:Order {order_date: date("2025-04-10"), total_price: 50.0})
CREATE (o2:Order {order_date: date("2025-04-11"), total_price: 100.0})

// Create Relationships
CREATE (b1)-[:WRITTEN_BY]->(a1)
CREATE (b2)-[:WRITTEN_BY]->(a2)
CREATE (b1)-[:WRITTEN_BY]->(a2)

CREATE (b1)-[:HAS_CHARACTER]->(ch1)
CREATE (b1)-[:HAS_CHARACTER]->(ch2)

CREATE (b1)-[:BELONGS_TO]->(cat1)
CREATE (b2)-[:BELONGS_TO]->(cat2)

CREATE (bc1)-[:OF]->(b1)
CREATE (bc2)-[:OF]->(b2)

CREATE (o1)-[:CONTAINS]->(bc1)
CREATE (o2)-[:CONTAINS]->(bc2)

CREATE (c1)-[:PLACED]->(o1)
CREATE (c2)-[:PLACED]->(o2)
