
module API = {
	type t
	@send external getSelectedRows: t => array<{..}> = "getSelectedRows"
	@send external setQuickFilter: (t, string) => unit = "setQuickFilter"
	@send external setFilterModel: (t, {..}) => unit = "setFilterModel"
}

type event = {
	event: Js.Nullable.t<Dom.event>,
	api: API.t,
}

module Grid = {
	type t
	@get external api: t => option<API.t> = "api"
}

@module("ag-grid-react") @react.component
external make: (
	~\"ref": React.ref<Js.Nullable.t<'a>>,
	~rowSelection: @string [ |#single | #multiple],
  ~rowData: array<{..}>,
  ~columnDefs: array<{..}>,
	~onRowSelected: event => unit,
	~onGridReady: (event => unit)=?,
) => React.element = "AgGridReact"
