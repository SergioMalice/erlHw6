% заголовочный файл настроек сервера

-author("sergeyb").
-record(cache, {key, value, life, added}).
-define(Cleaner, cleaner). % псевдоним названия модуля процесса очистки