@module("ag-grid-react") @react.component
external make: (
  ~rowData: array<{..}>,
  ~columnDefs: array<{..}>,
) => React.element = "AgGridReact"
