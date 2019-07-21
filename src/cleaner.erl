%%
% Процесс автоочистки таблицы от устаревших значений ?Cleaner
%
% Инициализируем, отправив cast-запрос на старт автоочистки с указанным интервалом.
%
% Функции terminate/2, code_change/3, handle_info/2 и handle_call/3 по сути
% не выполняют никаких действий, но присутствуют в коде для совместимости.
%%

-module(cleaner).
-author("sergeyb").

-behavior(gen_server).
-include("../include/settings.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%% API
-export([init/1, handle_cast/2, terminate/2, code_change/3, handle_info/2, handle_call/3]).

init({TName, Drop}) ->
  gen_server:cast(?MODULE, {start_clearing, TName, Drop}),
  {ok, none}.

clearing(TName, Drop) ->
  timer:sleep(timer:seconds(Drop)),
  Now = calendar:datetime_to_gregorian_seconds(calendar:universal_time()),
  MS = ets:fun2ms(fun(#cache{life = Life}) when Life =< Now -> true end),
  ets:select_delete(TName, MS),
  clearing(TName, Drop).

handle_cast({start_clearing, TName, Drop}, State) ->
  clearing(TName, Drop),
  {noreply, State}.

handle_call(_Msg, _From, State) -> {reply, ok, State}.

terminate(normal, _State) -> ok.

handle_info(_Info, State) -> {noreply, State}.

code_change(_Old, State, _Extra) -> {ok, State}.