-- Синхронизация sequence таблицы product с текущим максимальным ID
SELECT setval(
    pg_get_serial_sequence('product', 'id'),
    COALESCE((SELECT MAX(id) FROM product), 1),
    true
);
-- Синхронизация sequence таблицы orders с текущим максимальным ID
SELECT setval(
    pg_get_serial_sequence('orders', 'id'),
    COALESCE((SELECT MAX(id) FROM orders), 1),
    true
);