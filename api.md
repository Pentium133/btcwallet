# Список API эндпоинтов обменника

## Создание заказа

```
POST /api/orders
```

#### запрос JSON

```
email - string - Email пользователя
from_currency - string - Код исходной валюты
to_currency - string - Код целевой валюты
from_amount - number - Сумма для обмена
destination_address - string - Адрес пользователя
```

#### ответ JSON

```
order_id - string - ID заказа
payment_address - string - Сгенерированный адрес для перевода средств
status - string - Текущий статус (waiting_payment)
from_amount - deciaml - Сумма исходной валюты
to_amount - decimal - Сумма целевой валюты по курсу
net-fee - decimal - Комиссия сети
exch-fee - decimal - Комиссия обменника
```

## Получение информации о заказе

```
GET /api/orders/:id
```

#### ответ JSON

```
order_id - string - ID заказа
payment_address - string - Адрес для перевода средств
status - string - Текущий статус
from_amount - deciaml - Сумма исходной валюты
to_amount - decimal - Сумма целевой валюты по курсу
net-fee - decimal - Комиссия сети
exch-fee - decimal - Комиссия обменника
tx_hash_in - string - Хеш входящей транзакции
tx_hash_out -string - Хеш исходящей транзакции
```

## Получения списка валют

```
GET /api/currencies
```

#### ответ массив JSON

```
code - string
name - string
network - string
```

## Получить текущий курс обмена

```
GET /api/rate
```

#### параметры

```
from - Исходная валюта
to - Целевая валюта
```

#### ответ JSON

```
rate - Курс обмена (1 from в to)
timestamp - Дата обновления курса
```

## ADMIN - Список всех заказов (требует авторизации)

```
GET /admin/orders
```

#### параметры

```
page  Номер страницы (опционально)
limit Кол-во записей на странице (опционально)
sort_by - Поле сортировки (опционально)
order - Напрвление сортировка DESC | ASC (опционально)

```

#### ответ JSON

```
total - Общее кол-во аказов
current_page - Текущая страница показа
orders - Массив объектов Ордер

Объект Ордер:
order_id - ID заказа
payment_address - Адрес для перевода средств
status - Текущий статус
from_amount - Сумма исходной валюты
to_amount - Сумма целевой валюты по курсу
net-fee - Комиссия сети
exch-fee - Комиссия обменника
tx_hash_in - Хеш входящей транзакции
tx_hash_out - Хеш исходящей транзакции
```

## ADMIN Балансы всех кошельков (требует авторизации)

```
GET /admin/wallets
```

#### ответ массив JSON

```
address
currency
balance
```
