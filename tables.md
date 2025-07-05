# Таблицы приложения

## users - Пользователи сервиса

```
id - integer
email - string
created_at - timestamp
updated_at - timestamp
```

## currencies - Справочник поддерживаемых криптовалют

```
id - integer
code - string - символьный код валюты
name - string - название валюты
is_enabled - booelan - активность валюты для обмена
network - string - сеть блокчейна (ERC20, TRC20)
created_at - timestamp
updated_at - timestamp
```

## exchange_orders - Заказы на обмен

```
id - uuid - что бы усложнить подбор id и просмотр чужих ордеров через api
user_id - integer - внешний ключ на users.id
from_currency_id - integer - исходная валюта (внешний ключ на currencies.id)
to_currency_id - integer - целевая валюта
from_amount - deciaml - сумма исходной валюты
to_amount - decimal - сумма целевой валюты
net-fee - decimal - комиссия сети
exch-fee - decimal - комиссия обменника
destination_address - string - адрес пользователя для перевода целевой валюты
status - enum - статус заказа (pending, waiting_payment, completed, failed)
completed_at - timestamp - дата и время выполнения заказа
created_at - timestamp
updated_at - timestamp
```

## payment_addresses - Сгенерированные адреса для приёма исходной валюты от пользователя

```
id - integer
exchange_order_id - uuid - внешний ключ на exchange_orders.id
address - string - адрес для оплаты в исходной валюте
currency_id - integer - валюта (внешний ключ на currencies.id)
created_at - timestamp
updated_at - timestamp
```

## transactions - Транзакций в блокчейне (входящие и исходящие)

```
id - integer
exchange_order_id - uuid - внешний ключ на exchange_orders.id
tx_hash  - string - хеш транзакции
direction - enum - 'in' или 'out'
amount - decimal - сумма
currency_id - integer - валюта (внешний ключ на currencies.id)
confirmed - boolean - статус подтверждения транзакции
created_at - timestamp
updated_at - timestamp
```

## exchange_rates  - Курсы валют (обновлются автоматически)

```
id - integer
from_currency_id - integer - валюта (внешний ключ на currencies.id)
to_currency_id - integer - валюта (внешний ключ на currencies.id)
rate - deciaml - курс обмена
timestamp - timestamp - время актуальности курса
created_at - timestamp
updated_at - timestamp
```

## audit - Лог событий

```
id - integer
exchange_order_id - uuid - внешний ключ на exchange_orders.id
event - enum - (order_created, payment_received, exchange_completed, error)
message - text - дополнительная информация
created_at - timestamp
updated_at - timestamp
```
