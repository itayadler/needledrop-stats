module API = {
	type t
	@send external getSelectedRows: t => array<{..}> = "getSelectedRows"
}

module Grid = {
	type t
	@get external api: t => API.t = "api"
}

@module("ag-grid-react") @react.component
external make: (
	~\"ref": React.ref<Js.Nullable.t<'a>>,
	~rowSelection: @string [ |#single | #multiple],
  ~rowData: array<{..}>,
  ~columnDefs: array<{..}>,
	~onRowSelected: 'a => unit,
) => React.element = "AgGridReact"
