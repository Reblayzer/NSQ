/// 4A

const { MongoClient, ObjectId, Decimal128 } = require('mongodb');
const uri = 'mongodb+srv://bolfaalexandro:vzqyaeLYLFg5oN8k@nsq.9wtyj.mongodb.net/';
const client = new MongoClient(uri);

// 1.   Sell a book to a customer.
 async function sellBookToCustomer() {

   try {
      await client.connect();
      const session = client.startSession();

      try {
         session.startTransaction();

         const customerId = new ObjectId("67dbe4c8fd6edf6ca3f07404"); // Replace with actual customer ID
         const bookCopyIds = [
            new ObjectId("67dbe4c8fd6edf6ca3f07400"), // Replace with actual book copy IDs
            new ObjectId("67dbe4c8fd6edf6ca3f07401")
         ];

         let totalPrice = Decimal128.fromString("0.00"); // Initialize as Decimal128
         const orderDetails = [];

         for (const bookCopyId of bookCopyIds) {
            const bookCopy = await client.db('assignment2').collection('book_copies').findOne(
               { _id: bookCopyId },
               { session }
            );
            if (!bookCopy) {
               throw new Error(`Book copy with ID ${bookCopyId} not found`);
            }

            const quantity = 1; // Assuming selling one copy of each book
            const subtotalPrice = Decimal128.fromString((bookCopy.price * quantity).toFixed(2)); // Convert to Decimal128
            totalPrice = Decimal128.fromString((parseFloat(totalPrice.toString()) + parseFloat(subtotalPrice.toString())).toFixed(2)); // Add as Decimal128

            orderDetails.push({
               book_copy_id: bookCopyId,
               quantity: quantity,
               subtotal_price: subtotalPrice
            });
         }

         // Ensure the document matches the schema
         const orderDocument = {
            customer_id: customerId,
            order_date: new Date(),
            total_price: totalPrice,
            order_details: orderDetails
         };

         // Validate the document against the schema (optional)
         const validationResult = await client.db('assignment2').command({
            validate: 'orders',
            document: orderDocument
         });
         if (!validationResult.valid) {
            throw new Error("Document validation failed: " + JSON.stringify(validationResult.details));
         }

         // Insert the document
         await client.db('assignment2').collection('orders').insertOne(
            orderDocument,
            { session }
         );

         await session.commitTransaction();
         console.log("Transaction committed successfully.");
      } catch (error) {
         await session.abortTransaction();
         console.error("Transaction aborted due to error:", error);
      } finally {
         session.endSession();
      }
   } finally {
      await client.close();
   }
}

sellBookToCustomer().catch(console.error); 

// 2.	Change the address of a customer.
 async function changeCustomerAddress(customerId, newAddress) {

   try {
      await client.connect();
      const result = await client.db('assignment2').collection('customers').updateOne(
         { _id: new ObjectId(customerId) },
         { $set: { address: newAddress } }
      );
      console.log(`Updated ${result.modifiedCount} customer(s).`);
   } finally {
      await client.close();
   }
}

changeCustomerAddress("67dbe4c8fd6edf6ca3f07404", {
   street: "789 Oak St",
   city: "Chicago",
   zip: "60601"
}).catch(console.error); 

// 3.	Add an author to a book.

 async function addAuthorToBook(bookId, authorId) {

   try {
      await client.connect();
      const result = await client.db('assignment2').collection('books').updateOne(
         { _id: new ObjectId(bookId) },
         { $push: { authors: new ObjectId(authorId) } }
      );
      console.log(`Updated ${result.modifiedCount} book(s).`);
   } finally {
      await client.close();
   }
}

addAuthorToBook("67dbe4c8fd6edf6ca3f07400", "67dbe4c8fd6edf6ca3f07405").catch(console.error); 

// 4.	Retire the "Space Opera" category and assign all books from that category to the parent category. 

async function retireCategory(categoryName) {
   try {
      await client.connect();
      const session = client.startSession();

      try {
         session.startTransaction();

         // Find the parent category
         const parentCategory = await client.db('assignment2').collection('categories').findOne(
            { subcategories: categoryName },
            { session }
         );
         if (!parentCategory) {
            throw new Error(`Parent category for "${categoryName}" not found`);
         }

         // Step 1: Remove the retired category from all books
         const removeResult = await client.db('assignment2').collection('books').updateMany(
            { categories: categoryName },
            { $pull: { categories: categoryName } },
            { session }
         );
         console.log(`Removed "${categoryName}" from ${removeResult.modifiedCount} book(s).`);

         // Step 2: Add the parent category to all books that had the retired category
         const addResult = await client.db('assignment2').collection('books').updateMany(
            { categories: { $exists: true } }, // Ensure the document has a `categories` array
            { $addToSet: { categories: parentCategory.name } },
            { session }
         );
         console.log(`Added "${parentCategory.name}" to ${addResult.modifiedCount} book(s).`);

         // Delete the retired category
         await client.db('assignment2').collection('categories').deleteOne(
            { name: categoryName },
            { session }
         );
         console.log(`Deleted category "${categoryName}".`);

         await session.commitTransaction();
         console.log("Transaction committed successfully.");
      } catch (error) {
         await session.abortTransaction();
         console.error("Transaction aborted due to error:", error);
      } finally {
         session.endSession();
      }
   } finally {
      await client.close();
   }
}

retireCategory("Space Opera").catch(console.error);

// 5.	Sell 3 copies of one book and 2 of another in a single order

 async function sellMultipleBooks(customerId, bookCopyQuantities) {

   try {
      await client.connect();
      const session = client.startSession();

      try {
         session.startTransaction();

         const bookCopies = await Promise.all(bookCopyQuantities.map(async ({ bookCopyId, quantity }) => {
            const bookCopy = await client.db('assignment2').collection('book_copies').findOne(
               { _id: new ObjectId(bookCopyId) },
               { session }
            );
            if (!bookCopy) {
               throw new Error(`Book copy with ID ${bookCopyId} not found`);
            }
            return { bookCopy, quantity };
         }));

         const orderDetails = bookCopies.map(({ bookCopy, quantity }) => ({
            book_copy_id: bookCopy._id,
            quantity: quantity,
            subtotal_price: Decimal128.fromString((bookCopy.price * quantity).toFixed(2))
         }));

         const totalPrice = Decimal128.fromString(orderDetails
            .reduce((sum, detail) => sum + parseFloat(detail.subtotal_price.toString()), 0)
            .toFixed(2)
         );

         await client.db('assignment2').collection('orders').insertOne({
            customer_id: new ObjectId(customerId),
            order_date: new Date(),
            total_price: totalPrice,
            order_details: orderDetails
         }, { session });

         await session.commitTransaction();
         console.log("Transaction committed successfully.");
      } catch (error) {
         await session.abortTransaction();
         console.error("Transaction aborted due to error:", error);
      } finally {
         session.endSession();
      }
   } finally {
      await client.close();
   }
}

sellMultipleBooks("67dbe4c8fd6edf6ca3f07404", [
   { bookCopyId: "67dbe4c8fd6edf6ca3f07400", quantity: 3 },
   { bookCopyId: "67dbe4c8fd6edf6ca3f07401", quantity: 2 }
]).catch(console.error); 

/// 4B

 // 1. All books by an author
db.books.find({ authors: ObjectId("67dbe636ada9c6ad52a93618") });

// 2. Total price of an order
db.orders.find(
    { _id: ObjectId("67dbe636ada9c6ad52a93625") },
    { _id: 0, total_price: 1 }
);

// 3. Total sales (in £) to a customer
db.orders.aggregate([
    { $match: { customer_id: ObjectId("67dbe636ada9c6ad52a93623") } },
    { $group: { _id: "$customer_id", total_sales: { $sum: "$total_price" } } }
]);

// 4. Books that are categorized as neither science fiction nor fantasy
db.books.find({
    categories: { $nin: ["Science Fiction", "Fantasy"] }
});

// 5. Average page count by genre
db.books.aggregate([
    { $unwind: "$genres" },
    { $group: { _id: "$genres", avg_page_count: { $avg: "$page_count" } } }
]);

// 6. Categories that have no sub-categorie
db.categories.find({
    $or: [
        { subcategories: { $exists: false } },
        { subcategories: { $size: 0 } }
    ]
});

// 7. ISBN numbers of books with more than one author 
db.books.find(
    { "authors.1": { $exists: true } }, 
    { _id: 0, isbn: 1 }
);

// 8. ISBN numbers of books that sold at least X copies (you decide the value for X) 
const X = 2;
db.orders.aggregate([
    { $unwind: "$order_details" },
    { $group: { _id: "$order_details.book_copy_id", total_sold: { $sum: "$order_details.quantity" } } },
    { $match: { total_sold: { $gte: X } } },
    { $lookup: { from: "book_copies", localField: "_id", foreignField: "_id", as: "book_copy" } },
    { $unwind: "$book_copy" },
    { $project: { _id: 0, isbn: "$book_copy.isbn" } }
]);

// 9. Number of copies of each book sold – unsold books should show as 0 sold copies.
db.book_copies.aggregate([
    {
        $lookup: {
            from: "orders",
            localField: "_id",
            foreignField: "order_details.book_copy_id",
            as: "order_info"
        }
    },
    {
        $unwind: {
            path: "$order_info",
            preserveNullAndEmptyArrays: true // Ensures unsold books are included
        }
    },
    {
        $unwind: {
            path: "$order_info.order_details",
            preserveNullAndEmptyArrays: true
        }
    },
    {
        $group: {
            _id: "$isbn",
            total_sold: { $sum: { $ifNull: ["$order_info.order_details.quantity", 0] } }
        }
    },
    {
        $project: {
            _id: 0,
            isbn: "$_id",
            copies_sold: "$total_sold"
        }
    }
]);

// 10. Best-selling books: The top 10 selling books ordered in descending order by number of sales.
db.orders.aggregate([
    { $unwind: "$order_details" },
    { $group: { _id: "$order_details.book_copy_id", total_sold: { $sum: "$order_details.quantity" } } },
    { $lookup: { from: "book_copies", localField: "_id", foreignField: "_id", as: "book_copy" } },
    { $unwind: "$book_copy" },
    { $lookup: { from: "books", localField: "book_copy.isbn", foreignField: "isbn", as: "book" } },
    { $unwind: "$book" },
    { $project: { _id: 0, title: "$book.title", copies_sold: "$total_sold" } },
    { $sort: { copies_sold: -1 } },
    { $limit: 10 }
]);

// 11. Best-selling genres: The top 3 selling genres ordered in descending order by number of sales. 
db.orders.aggregate([
    { $unwind: "$order_details" },
    { $lookup: { from: "book_copies", localField: "order_details.book_copy_id", foreignField: "_id", as: "book_copy" } },
    { $unwind: "$book_copy" },
    { $lookup: { from: "books", localField: "book_copy.isbn", foreignField: "isbn", as: "book" } },
    { $unwind: "$book" },
    { $unwind: "$book.genres" },
    { $group: { _id: "$book.genres", total_sold: { $sum: "$order_details.quantity" } } },
    { $sort: { total_sold: -1 } },
    { $limit: 3 }
]);

// 12. All science fiction books. Note: Books in science fiction subcategories like cyberpunk also count as science fiction.
db.categories.aggregate([
    
    {
        $match: { name: "Science Fiction" } // Start from the "Science Fiction" category
    },
    {
        $graphLookup: {
            from: "categories",
            startWith: "$name",
            connectFromField: "subcategories",
            connectToField: "name",
            as: "allSciFiCategories"
        }
    },
    {
        $project: {
            categoryNames: { $concatArrays: [["$name"], "$allSciFiCategories.name"] } // Collect all category names
        }
    },
    { $unwind: "$categoryNames" },

    {
        $lookup: {
            from: "books",
            localField: "categoryNames",
            foreignField: "categories",
            as: "books"
        }
    },
    { $unwind: "$books" },

    {
        $replaceRoot: { newRoot: "$books" }
    }
]);

// 13. Characters used in science fiction books. 
db.categories.aggregate([
    {
        $match: { name: "Science Fiction" }
    },
    {
        $graphLookup: {
            from: "categories",
            startWith: "$name",
            connectFromField: "subcategories",
            connectToField: "name",
            as: "allSciFiCategories"
        }
    },
    {
        $project: {
            categoryNames: { $concatArrays: [["$name"], "$allSciFiCategories.name"] }
        }
    },
    { $unwind: "$categoryNames" },

    {
        $lookup: {
            from: "books",
            localField: "categoryNames",
            foreignField: "categories",
            as: "books"
        }
    },
    { $unwind: "$books" },

    
    {
        $project: {
            _id: 0,
            title: "$books.title",
            characters: "$books.characters"
        }
    },
    { $unwind: "$characters" }, 
    { $group: { _id: "$characters" } }, 
    { $project: { _id: 0, character: "$_id" } } 
]);

// 14. For each category: Number of books in the category including books in its subcategories. 
db.categories.aggregate([
    {
        $graphLookup: {
            from: "categories",
            startWith: "$name",
            connectFromField: "subcategories",
            connectToField: "name",
            as: "allSubcategories"
        }
    },
    {
        $project: {
            categoryNames: { $concatArrays: [["$name"], "$allSubcategories.name"] }
        }
    },
    { $unwind: "$categoryNames" },

    {
        $lookup: {
            from: "books",
            localField: "categoryNames",
            foreignField: "categories",
            as: "books"
        }
    },
    {
        $project: {
            _id: 0,
            category: "$categoryNames",
            bookCount: { $size: "$books" } 
        }
    },
    { $group: { _id: "$category", totalBooks: { $sum: "$bookCount" } } }, 
    { $sort: { totalBooks: -1 } } 
]); 