create table genre
(
    genre_id   int primary key not null,
    genre_name varchar(50)     not null
);

create table category
(
    category_id        int primary key not null,
    category_name      varchar(50)     not null,
    parent_category_id int             null
);

create table genre_category_pair
(
    genre_id    int not null,
    category_id int not null,
    foreign key (genre_id) references genre (genre_id) on delete cascade,
    foreign key (category_id) references category (category_id) on delete cascade
);



create table category (
    category_id        int primary key not null,
    category_name      varchar(50)     not null,
    parent_category_id int             null
);

WITH RECURSIVE category_hierarchy AS (
    -- Anchor: the root category
    SELECT 
        category_id,
        category_name,
        parent_category_id
    FROM category
    WHERE category_name = 'fiction'

    UNION ALL

    -- Recursive step: find children of the previous level
    SELECT 
        c.category_id,
        c.category_name,
        c.parent_category_id
    FROM category c
    INNER JOIN category_hierarchy ch ON c.parent_category_id = ch.category_id
)

SELECT * FROM category_hierarchy;

CREATE TABLE Customer (
  id   SERIAL PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE "Order" (
  id          SERIAL PRIMARY KEY,
  order_date  DATE NOT NULL,
  customer_id INT NOT NULL REFERENCES Customer(id)
);


