-module(cache_server_SUITE).
-author("sergeyb").

-include_lib("common_test/include/ct.hrl").
-include("../include/settings.hrl").
-compile(export_all).

%% API

all() ->
  [{group, all}].

groups() -> [
  {all, [sequence], [
    initialize,
    write,
    filter,
    filter_date
  ]}
].

initialize(_Config) ->
  {ok, _Pid} = cache_server:start_link(table, [{drop_interval, 15}]).

write(_Config) ->
  ok = cache_server:insert(table, cookie, first, 5),
  ok = cache_server:insert(table, cookie, second, 30),
  ok = cache_server:insert(table, cookie, third, 300).

filter(_Config) ->
  List = cache_server:lookup(table, cookie),
  is_list(List).

filter_date(_Config) ->
  List = cache_server:lookup_by_date(table, {{2019, 7, 15}, {00, 00, 00}}, {{2019, 7, 29}, {00, 00, 00}}),
  is_list(List).
