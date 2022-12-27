@send
external arrayBuffer: Fetch.Response.t => promise<Js_typed_array2.array_buffer> = "arrayBuffer"

module Database = {
  type t
  @send external exec: (t, string) => array<{..}> = "exec"
}
module SQL = {
  type t
  //note(itay): How do I achieve this with rescript bindings?
  let makeDatabase: (
    t,
    Js.TypedArray2.Uint8Array.t,
  ) => Database.t = %raw(`function(sql, buf){ return new sql.Database(buf) }`)
}
type config = {locateFile: string => string}
@module("sql.js") external initSqlJs: config => promise<SQL.t> = "default"

let init = (~locateFile) => {
  initSqlJs({locateFile: locateFile})
}

let loadDatabase = async (sql, ~url) => {
  open Fetch

  let response = await fetch(url, {})
  let arrayBuffer = await arrayBuffer(response)
  SQL.makeDatabase(sql, Js.TypedArray2.Uint8Array.fromBuffer(arrayBuffer))
}
