


MATCH () RETURN count(*);



MATCH (b:Book) RETURN b.title;


MATCH (c:Customer {email:"john.doe@example.com"})
RETURN c.name;


MATCH (n:Order) RETURN n;


MATCH ()-[]->() RETURN count(*);


MATCH (a)-[:WRITTEN_BY]->(b:Book) RETURN a.name, b.title;


MATCH (o:Order)-[:CONTAINS]->(bc:BookCopy)
RETURN o.id, bc.isbn;


MATCH (b:BookCopy)<-[:CONTAINS]-(o:Order)
RETURN b.isbn, o.id;


// Find all customers who bought a Science Fiction book
MATCH (c:Customer)-[:PLACED]->(o:Order)-[:CONTAINS]->(bc:BookCopy)-[:OF]->(b:Book)
WHERE "Science Fiction" IN b.categories
RETURN DISTINCT c.name;  :contentReference[oaicite:0]{index=0}


// All sub-categories of Fiction at any depth
MATCH (root:Category {name:"Fiction"})-[:SUBCATEGORY_OF*0..]->(sub)
RETURN sub.name;  :contentReference[oaicite:1]{index=1}




// Relationships of either PLACED or REVIEWED
MATCH (c)-[r:PLACED|REVIEWED]->(o)
RETURN c.name, type(r), o.id;

// Node with multiple labels
MATCH (p:Person:PremiumMember)
RETURN p.name;



MATCH p = (c:Customer)-[:PLACED]->(o)-[:CONTAINS]->(bc)
WHERE c.email = $email
RETURN p, length(p) AS hops;


// Include customers even if they placed no orders
MATCH (c:Customer)
OPTIONAL MATCH (c)-[:PLACED]->(o:Order)
RETURN c.name, collect(o.id) AS orders;







MATCH (c:Customer {email:$email}), (bc:BookCopy {id:$copyId})
CREATE (o:Order {id:randomUUID(), order_date:date(), total_price:$price})
CREATE (c)-[:PLACED]->(o)
CREATE (o)-[:CONTAINS { quantity:1, subtotal_price:$price }]->(bc);


MERGE (a:Author {name:$name})
ON CREATE SET a.created = timestamp()
ON MATCH  SET a.lastSeen = timestamp();


// Discount all Frank Herbert books by 10%
MATCH (a:Author {name:"Frank Herbert"})-[:WRITTEN_BY]->(b:Book)
SET b.price = b.price * 0.90;



// Remove a book and its relationships
MATCH (b:Book {isbn:$isbn})
DETACH DELETE b;





MATCH (c:Customer {email:$customerEmail}), (bc:BookCopy {id:$bookCopyId})
CREATE (o:Order {
  id:          randomUUID(),
  order_date:  date(),
  total_price: $price
})
CREATE (c)-[:PLACED]->(o)
CREATE (o)-[:CONTAINS {quantity:1, subtotal_price:$price}]->(bc)
RETURN o




MATCH (b:Book {id:$bookId})
SET b.price = b.price * (1 - $percentage/100)
RETURN b


MATCH (c:Customer)
RETURN
  c.name,
  [ 
    (c)-[:PLACED]->(:Order)-[:CONTAINS]->(bc:BookCopy)-[:OF]->(b:Book) 
      | b.title 
  ] AS titles;


MATCH (c:Customer)
WHERE EXISTS(
  (c)-[:PLACED]->()-[:CONTAINS]->(:BookCopy {isbn:"0441013597"})
)
RETURN c.name;



query($id: ID!) {
  author(where: { id: $id }) {
    books {
      title
      isbn
    }
  }
}
