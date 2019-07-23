%%
% make tests из корня проекта - запуск тестов
%
% Cache-сервер с автоматической очисткой устаревших полей.
%
% Так, как очистка и сервер запросов - разные процессы, запускаем
% сервер запросов паралельно с ?Cleaner, передав ему аргументами имя таблицы
% и интервал автоочистки в секундах. Таблицу создаем с параметром public,
% чтобы ?Cleaner имел доступ на удаление полей.
%
% Запросы, не требующие ответа, такие как insert/4, выполняем в cast-варажении,
% а те, что возвращают поля - lookup/2 и lookup_by_date/3 - в call-выражении.
%
% Функции terminate/2, code_change/3, handle_info/2 по сути не выполняют никаких
% действий, но присутствуют в коде для совместимости.
%
%%

-module(cache_server).
-author("sergeyb").

-behavior(gen_server).
-include("../include/settings.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%% API
-export([start_link/2, init/1]).
-export([insert/4, lookup/2, lookup_by_date/3]).
-export([handle_cast/2, handle_call/3, terminate/2, code_change/3, handle_info/2]).

start_link(TName, [{drop_interval, Drop}]) ->
  gen_server:start({local, ?MODULE}, ?MODULE, TName, []),
  gen_server:start({local, ?Cleaner}, ?Cleaner, {TName, Drop}, []).

init(TName) ->
  ets:new(TName, [public, named_table, duplicate_bag, {keypos, #cache.key}]),
  {ok, none}.

insert(TName, Key, Val, Time) ->
  gen_server:cast(?MODULE, {insert, TName, Key, Val, Time}).

lookup(TName, Key) ->
  gen_server:call(?MODULE, {lookup, TName, Key}).

lookup_by_date(TName, DateFrom, DateTo) ->
  gen_server:call(?MODULE, {lookup_by_date, TName, DateFrom, DateTo}).

handle_call({lookup, TName, Key}, _From, State) ->
  List = ets:lookup(TName, Key),
  Now = calendar:datetime_to_gregorian_seconds(calendar:universal_time()),
  {reply, [{ok, El#cache.value} || El <- List, El#cache.life > Now], State};
handle_call({lookup_by_date, TName, DateFrom, DateTo}, _From, State) ->
  FromTime = calendar:datetime_to_gregorian_seconds(DateFrom),
  ToTime = calendar:datetime_to_gregorian_seconds(DateTo),
  MS = ets:fun2ms(fun(#cache{value = Val, added = Added}) when Added >= FromTime, Added =< ToTime -> {ok, Val} end),
  Reply = ets:select(TName, MS),
  {reply, Reply, State}.

handle_cast({insert, TName, Key, Val, Time}, State) ->
  Now = calendar:datetime_to_gregorian_seconds(calendar:universal_time()),
  Life = Now+Time,
  ets:insert(TName, #cache{key=Key, value = Val, life = Life, added = Now}),
  {noreply, State}.

terminate(normal, _State) -> ok.

handle_info(_Info, State) -> {noreply, State}.

code_change(_Old, State, _Extra) -> {ok, State}.