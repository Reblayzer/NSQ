// Modifying Data
// 1. Sell a book to a customer
// Book “Cyber Dreams” (ISBN 978-3333333333), E-book copy
// Customer “Carol White” (email carol@example.com)
MATCH (b:Book { isbn: "978-3333333333" })
MATCH (bc:BookCopy { isbn: b.isbn, type: "E-book" })
MATCH (c:Customer { email: "carol@example.com" })
CREATE (o:Order {
  id:          randomUUID(),
  order_date:  date("2025-05-10"),
  total_price: bc.price
})
CREATE (c)-[:PLACED]->(o)
CREATE (o)-[:CONTAINS {
  quantity:       1,
  subtotal_price: bc.price
}]->(bc)
RETURN o;

// 2. Change the address of a customer
// Update Bob’s address
MATCH (c:Customer { email: "bob@example.com" })
SET c.address = "999 Pine St, New City, 55555"
RETURN c;

// 3. Add an existing author to a book
// Make “Author 3” a co-author of “Galactic Wars”
MATCH (b:Book { title: "Galactic Wars" })
MATCH (a:Author { name: "Author 3" })
MERGE (b)-[:WRITTEN_BY]->(a)
RETURN b.title AS book, collect(a.name) AS authors;

// 4. Retire the “Cyberpunk” subcategory and reassign its books
MATCH (old:Category { name: "Cyberpunk" })
MATCH (parent:Category { name: "Science Fiction" })
WITH old,parent
MATCH (b:Book)-[r:BELONGS_TO]->(old)
MERGE (b)-[:BELONGS_TO]->(parent)
DETACH DELETE old
RETURN parent.name AS newCategory, collect(b.isbn) AS reassignedBooks;

// 5. Sell 2 paperbacks of “Adventure in Fiction” and 1 hardcover of “Dragon Kingdom”
MATCH (bc1:BookCopy { isbn: "978-1234567890", type: "Paperback" })
MATCH (bc2:BookCopy { isbn: "978-2222222222", type: "Paperback" })
MATCH (c:Customer { email: "alice@example.com" })
CREATE (o:Order {
  id:          randomUUID(),
  order_date:  date("2025-05-05"),
  total_price: bc1.price*2 + bc2.price*1
})
CREATE (c)-[:PLACED]->(o)
CREATE (o)-[:CONTAINS { quantity:2, subtotal_price:bc1.price*2 }]->(bc1)
CREATE (o)-[:CONTAINS { quantity:1, subtotal_price:bc2.price }]->(bc2)
RETURN o;



// Querying Data
// 1. All books by “Author 1”
MATCH (a:Author { name: "Author 1" })-[:WRITTEN_BY]->(b:Book)
RETURN b.title AS book, b.isbn;

// 2. Total price of a specific order
//    – use one of the order IDs returned earlier, e.g. from o1
MATCH (o:Order { id: "<PASTE-ORDER-ID-HERE>" })
RETURN o.total_price;

// 3. Total sales to Alice (by email)
MATCH (c:Customer { email: "alice@example.com" })-[:PLACED]->(o:Order)
RETURN SUM(o.total_price) AS aliceTotalSales;

// 4. Books neither Sci-Fi nor Fantasy
MATCH (b:Book)-[:BELONGS_TO]->(cat:Category)
WHERE NOT cat.name IN ["Science Fiction","Fantasy"]
RETURN DISTINCT b.title, b.isbn;

// 5. Average page count by each genre
MATCH (b:Book)
UNWIND b.genres AS genre
WITH genre, AVG(b.page_count) AS avgPages
RETURN genre, avgPages
ORDER BY genre;

// 6. Categories with no sub-categories
MATCH (cat:Category)
WHERE NOT (cat)<-[:SUBCATEGORY_OF]-(:Category)
RETURN cat.name AS leafCategory;

// 7. ISBNs of books with >1 author
MATCH (b:Book)-[:WRITTEN_BY]->(a:Author)
WITH b, COUNT(a) AS authorCount
WHERE authorCount > 1
RETURN b.isbn, authorCount;

// 8. ISBNs of books that sold ≥5 copies total
MATCH (b:Book)<-[:OF]-(bc:BookCopy)-[r:CONTAINS]->()
WITH b, SUM(r.quantity) AS totalSold
WHERE totalSold >= 5
RETURN b.isbn, totalSold;

// 9. Number of copies sold per book (unsold = 0)
MATCH (b:Book)
OPTIONAL MATCH (b)<-[:OF]-(bc:BookCopy)-[r:CONTAINS]->()
RETURN 
  b.title AS book, 
  COALESCE(SUM(r.quantity), 0) AS copiesSold
ORDER BY copiesSold DESC;

// 10. Top 10 best-selling books
MATCH (b:Book)<-[:OF]-(bc:BookCopy)-[r:CONTAINS]->()
WITH b, SUM(r.quantity) AS sales
ORDER BY sales DESC
LIMIT 10
RETURN b.title AS book, sales;

// 11. Top 3 best-selling genres
MATCH (b:Book)-[:BELONGS_TO]->(cat:Category)
MATCH (b)<-[:OF]-(bc:BookCopy)-[r:CONTAINS]->()
WITH cat.name AS genre, SUM(r.quantity) AS sales
ORDER BY sales DESC
LIMIT 3
RETURN genre, sales;

// 12. All Sci-Fi books (including books in “Cyberpunk”)
MATCH (b:Book)-[:BELONGS_TO]->(cat:Category)
WHERE (cat)-[:SUBCATEGORY_OF*0..]->(:Category { name: "Science Fiction" })
RETURN DISTINCT b.title;

// 13. Characters used in all Sci-Fi books
MATCH (b:Book)-[:BELONGS_TO]->(cat:Category)
WHERE (cat)-[:SUBCATEGORY_OF*0..]->(:Category { name: "Science Fiction" })
MATCH (b)-[:HAS_CHARACTER]->(ch:Character)
RETURN DISTINCT ch.name;

// 14. Number of books per category including sub-categories
MATCH (cat:Category)
OPTIONAL MATCH (cat)<-[:SUBCATEGORY_OF*0..]-(sub:Category)
OPTIONAL MATCH (sub)<-[:BELONGS_TO]-(b:Book)
RETURN 
  cat.name         AS category,
  COUNT(DISTINCT b) AS bookCount
ORDER BY category;
