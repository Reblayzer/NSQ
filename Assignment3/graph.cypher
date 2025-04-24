CREATE CONSTRAINT book_isbn_unique IF NOT EXISTS
  FOR (b:Book) REQUIRE b.isbn IS UNIQUE;

CREATE CONSTRAINT customer_email_unique IF NOT EXISTS
  FOR (c:Customer) REQUIRE c.email IS UNIQUE;

// Authors
CREATE
  (a1:Author { id: randomUUID(), name: "Author 1" }),
  (a2:Author { id: randomUUID(), name: "Author 2" }),
  (a3:Author { id: randomUUID(), name: "Author 3" });

// Characters
CREATE
  (ch1:Character { id: randomUUID(), name: "Alice" }),
  (ch2:Character { id: randomUUID(), name: "Bob" }),
  (ch3:Character { id: randomUUID(), name: "Zorg" }),
  (ch4:Character { id: randomUUID(), name: "Xena" }),
  (ch5:Character { id: randomUUID(), name: "Neo" });

// Categories & Subcategories
CREATE
  (catF :Category { id: randomUUID(), name: "Fiction" }),
  (catSF:Category { id: randomUUID(), name: "Science Fiction" }),
  (catFan:Category { id: randomUUID(), name: "Fantasy" }),
  (catSci:Category { id: randomUUID(), name: "Science" }),
  (catCP:Category { id: randomUUID(), name: "Cyberpunk" });

  CREATE
  (catSF)-[:SUBCATEGORY_OF]->(catF),
  (catFan)-[:SUBCATEGORY_OF]->(catF),
  (catCP)-[:SUBCATEGORY_OF]->(catSF);

// Books
CREATE
  (b1:Book {
    id: randomUUID(),
    isbn: "978-1234567890",
    title: "Adventure in Fiction",
    page_count: 300,
    rating: 4.5,
    genres: ["Fiction","Adventure"]
  }),
  (b2:Book {
    id: randomUUID(),
    isbn: "978-0987654321",
    title: "Deep Science",
    page_count: 400,
    rating: 4.0,
    genres: ["Non-Fiction","Science"]
  }),
  (b3:Book {
    id: randomUUID(),
    isbn: "978-1111111111",
    title: "Galactic Wars",
    page_count: 500,
    rating: 4.8,
    genres: ["Science Fiction","Action"]
  }),
  (b4:Book {
    id: randomUUID(),
    isbn: "978-2222222222",
    title: "Dragon Kingdom",
    page_count: 350,
    rating: 4.2,
    genres: ["Fantasy","Adventure"]
  }),
  (b5:Book {
    id: randomUUID(),
    isbn: "978-3333333333",
    title: "Cyber Dreams",
    page_count: 280,
    rating: 4.7,
    genres: ["Science Fiction","Cyberpunk"]
  });

// BookCopies
MATCH
  (b1:Book { isbn: "978-1234567890" }),
  (b2:Book { isbn: "978-0987654321" }),
  (b3:Book { isbn: "978-1111111111" }),
  (b4:Book { isbn: "978-2222222222" }),
  (b5:Book { isbn: "978-3333333333" })
CREATE
  (bc1a:BookCopy {
    id:    randomUUID(),
    isbn:  b1.isbn,
    price: 20.0,
    type:  "Paperback"
  })-[:OF]->(b1),
  (bc1b:BookCopy {
    id:    randomUUID(),
    isbn:  b1.isbn,
    price:  5.0,
    type:  "E-book"
  })-[:OF]->(b1),
  (bc1c:BookCopy {
    id:    randomUUID(),
    isbn:  b1.isbn,
    price: 25.0,
    type:  "Hardcover"
  })-[:OF]->(b1),
  (bc2a:BookCopy {
    id:    randomUUID(),
    isbn:  b2.isbn,
    price: 30.0,
    type:  "Hardcover"
  })-[:OF]->(b2),
  (bc2b:BookCopy {
    id:    randomUUID(),
    isbn:  b2.isbn,
    price: 10.0,
    type:  "E-book"
  })-[:OF]->(b2),
  (bc3a:BookCopy {
    id:    randomUUID(),
    isbn:  b3.isbn,
    price: 22.0,
    type:  "Paperback"
  })-[:OF]->(b3),
  (bc3b:BookCopy {
    id:    randomUUID(),
    isbn:  b3.isbn,
    price:  8.0,
    type:  "E-book"
  })-[:OF]->(b3),
  (bc4a:BookCopy {
    id:    randomUUID(),
    isbn:  b4.isbn,
    price: 18.0,
    type:  "Paperback"
  })-[:OF]->(b4),
  (bc5a:BookCopy {
    id:    randomUUID(),
    isbn:  b5.isbn,
    price: 15.0,
    type:  "E-book"
  })-[:OF]->(b5),
  (bc5b:BookCopy {
    id:    randomUUID(),
    isbn:  b5.isbn,
    price: 28.0,
    type:  "Hardcover"
  })-[:OF]->(b5);

// Customers
CREATE
  (c1:Customer {
    id:      randomUUID(),
    name:    "Alice Smith",
    email:   "alice@example.com",
    address: "123 Main St"
  }),
  (c2:Customer {
    id:      randomUUID(),
    name:    "Bob Jones",
    email:   "bob@example.com",
    address: "456 Elm St"
  }),
  (c3:Customer {
    id:      randomUUID(),
    name:    "Carol White",
    email:   "carol@example.com",
    address: "789 Oak St"
  });

// Orders
CREATE
  (o1:Order {
    id:          randomUUID(),
    order_date:  date("2025-05-01"),
    total_price: 40.0
  }),
  (o2:Order {
    id:          randomUUID(),
    order_date:  date("2025-05-02"),
    total_price: 60.0
  }),
  (o3:Order {
    id:          randomUUID(),
    order_date:  date("2025-05-03"),
    total_price: 78.0
  }),
  (o4:Order {
    id:          randomUUID(),
    order_date:  date("2025-05-04"),
    total_price: 55.0
  });

// Relationships

// Book → Author
CREATE
  (b1)-[:WRITTEN_BY]->(a1),
  (b2)-[:WRITTEN_BY]->(a1),
  (b2)-[:WRITTEN_BY]->(a2),    // co-author on Deep Science
  (b3)-[:WRITTEN_BY]->(a2),
  (b4)-[:WRITTEN_BY]->(a3),
  (b5)-[:WRITTEN_BY]->(a1);

// Book → Character
CREATE
  (b1)-[:HAS_CHARACTER]->(ch1),
  (b1)-[:HAS_CHARACTER]->(ch2),
  (b3)-[:HAS_CHARACTER]->(ch3),
  (b3)-[:HAS_CHARACTER]->(ch4),
  (b5)-[:HAS_CHARACTER]->(ch5);

// Book → Category
CREATE
  (b1)-[:BELONGS_TO]->(catF),
  (b2)-[:BELONGS_TO]->(catSci),
  (b3)-[:BELONGS_TO]->(catSF),
  (b4)-[:BELONGS_TO]->(catFan),
  (b5)-[:BELONGS_TO]->(catCP);

// Order → BookCopy
CREATE
  (o1)-[:CONTAINS { quantity:2, subtotal_price:40.0 }]->(bc1a),
  (o2)-[:CONTAINS { quantity:1, subtotal_price:25.0 }]->(bc1c),
  (o2)-[:CONTAINS { quantity:1, subtotal_price:35.0 }]->(bc3a),
  (o3)-[:CONTAINS { quantity:2, subtotal_price:20.0 }]->(bc4a),
  (o3)-[:CONTAINS { quantity:1, subtotal_price:38.0 }]->(bc5b),
  (o4)-[:CONTAINS { quantity:3, subtotal_price:9.0 }]->(bc3b);

// Customer → Order
CREATE
  (c1)-[:PLACED]->(o1),
  (c1)-[:PLACED]->(o2),
  (c2)-[:PLACED]->(o3),
  (c3)-[:PLACED]->(o4);
