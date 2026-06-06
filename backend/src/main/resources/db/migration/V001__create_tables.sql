// Таблицы были выявлены на основе сущностей в коде
CREATE TABLE product (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    picture_url VARCHAR(255) NOT NULL
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    date_created DATE,
    status VARCHAR(255)
);

CREATE TABLE order_product (
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES product(id)
);