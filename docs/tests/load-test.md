# Нагрузочные тесты - Backend

## Базовое тестирование fastapi-mqtt и redis/keydb

Производительность:
1. 30000 запросов без обработки через fastapi - mqtt
2. 500 запросов стабильно на поток с обработкой на редисе - каждое 100е сообщение уникальное т.е. на 1000 get запросов 10 set записей в редис. Между 100ми сообщениями +- 200мс
3. 1000 запросов стабильно с keydb
4. 5000 запроов стабильно с локальным global кэшем в dict python

## Cхема нагружения 100 рандомных топиков

keydb:
1. aiokeydb 8.86 сек в среднем на 10к get set
2. aioredis 3.94 cек в среднем на 10к get set

redis:
1. aiokeydb 9.07 сек в среднем на 10к get set
2. aioredis 4.015 cек в среднем на 10к get set

## Идеи

- Нужно придумать как рассплитить топики на отдельные процессы gunicirn uvicorn, нужен агоритм, который бы хэшировал имена на N чисел
- Добавить время, чтобы сплит шëл даже для одинаковых топиков - аналог липких сессий
