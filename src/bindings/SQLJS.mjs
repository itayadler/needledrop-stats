// Generated by ReScript, PLEASE EDIT WITH CARE

import SqlJs from "sql.js";

var Database = {};

var makeDatabase = (function(sql, buf){ return new sql.Database(buf) });

var SQL = {
  makeDatabase: makeDatabase
};

function init(locateFile) {
  return SqlJs({
              locateFile: locateFile
            });
}

async function loadDatabase(sql, url) {
  var response = await fetch(url, {});
  var arrayBuffer = await response.arrayBuffer();
  return makeDatabase(sql, new Uint8Array(arrayBuffer));
}

export {
  Database ,
  SQL ,
  init ,
  loadDatabase ,
}
/* sql.js Not a pure module */
