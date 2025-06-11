const { ObjectId, Decimal128, ReturnDocument } = require('mongodb');

module.exports = {
  Query: {
    searchBooks: async (_, { term }, { db }) =>
      db.collection('books')
        .find({ title: { $regex: term, $options: 'i' } })
        .toArray(),

    ordersByCustomer: async (_, { email }, { db }) => {
      const cust = await db.collection('customers').findOne({ email });
      if (!cust) return [];
      return db.collection('orders')
        .find({ customer_id: cust._id })
        .toArray();
    }
  },

  /*
  query SearchBooks($term: String!) {
    searchBooks(term: $term) {
      id
      title
      price
    }
  } 
    
  {
	"term": "Dune"
  }
  
  */

  /*
  query OrdersByCustomer($email: String!) {
    ordersByCustomer(email: $email) {
      id
      numberOfBooks
      totalPrice
      items {
        book { title }
        quantity
        lineTotal
      }
    }
  } 
    
  {
  "email": "john.doe@example.com"
  }
  
  */
 

  Mutation: {
    createOrder: async (_, { customerId, bookCopyId }, { db }) => {
      // replicate your sellBookToCustomer logic, but only 1 book, quantity=1
      const custObj = new ObjectId(customerId);
      const copyObj = new ObjectId(bookCopyId);
      const [cust, copy] = await Promise.all([
        db.collection('customers').findOne({ _id: custObj }),
        db.collection('book_copies').findOne({ _id: copyObj })
      ]);
      if (!cust || !copy) throw new Error('Not found');

      const priceNum = parseFloat(copy.price.toString());
      const subtotal = Decimal128.fromString(priceNum.toFixed(2));
      const order = {
        customer_id: custObj,
        order_date: new Date(),
        total_price: subtotal,
        order_details: [{
          book_copy_id: copyObj,
          quantity: 1,
          subtotal_price: subtotal
        }]
      };
      const { insertedId } = await db.collection('orders')
        .insertOne(order);
      order._id = insertedId;
      return order;
    },

    applyBookDiscount: async (_, { bookId, percentage }, { db }) => {
      const filter = { _id: new ObjectId(bookId) };
      const multiplier = 1 - percentage / 100;

      // 1) Perform the update
      const { matchedCount } = await db.collection('books')
        .updateOne(filter, { $mul: { price: multiplier } });
      if (matchedCount === 0) {
        throw new Error('Book not found');
      }

      // 2) Fetch the freshly updated document
      const book = await db.collection('books').findOne(filter);
      if (!book) {
        // should never happen if matchedCount was 1
        throw new Error('Book not found after update');
      }

      return book;
    }
  },

  /* 
  mutation CreateOneClickOrder($customerId: ID!, $bookCopyId: ID!) {
    createOrder(customerId: $customerId, bookCopyId: $bookCopyId) {
      id
      numberOfBooks
      totalPrice
      items {
        book { title }
        quantity
        lineTotal
      }
    }
  }

  {
    "customerId": "684956ff6ae20ea9d43925fa",
    "bookCopyId":     "684956ff6ae20ea9d43925f6"
  }
    
  */

  /* 
  mutation DiscountBook($bookId: ID!, $percentage: Float!) {
    applyBookDiscount(bookId: $bookId, percentage: $percentage) {
      id
      isbn
      title
      price
    }
  }

  {
    "bookId":     "684956ff6ae20ea9d43925f5",
    "percentage": 20.0
  }

  */

   Book: {
    id:    book => book._id.toString(),
    price: book => parseFloat(book.price.toString()),

    authors: async (book, _, { db }) =>
      db
        .collection('authors')
        .find({ _id: { $in: book.authors.map(id => new ObjectId(id)) } })
        .toArray()
  },

  Order: {
    id: o => o._id.toString(),
    customer: (o, _, { db }) => db.collection('customers').findOne({ _id: o.customer_id }),
    // map the embedded order_details array to your GraphQL items
    items: o => o.order_details,
    numberOfBooks: o => o.order_details.reduce((sum, d) => sum + d.quantity, 0),
    totalPrice: o => parseFloat(o.total_price.toString())
  },

  OrderItem: {
  // NEW: resolve the `book` field by looking up the book_copy, then the book
  book: async ({ book_copy_id }, _, { db }) => {
    // 1) find the copy
    const copy = await db
      .collection('book_copies')
      .findOne({ _id: new ObjectId(book_copy_id) });
    if (!copy) throw new Error(`BookCopy ${book_copy_id} not found`);

    // 2) find the canonical Book by ISBN
    const book = await db
      .collection('books')
      .findOne({ isbn: copy.isbn });
    if (!book) throw new Error(`Book with ISBN ${copy.isbn} not found`);

    return book;
  },

  // you already have:
  quantity:   d => d.quantity,
  lineTotal:  d => parseFloat(d.subtotal_price.toString())
}
};
