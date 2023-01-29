let getRowData: array<{..}> => array<{..}> = %raw(`
	function(data) {
		return data
			.map((resultSet) => { 
				return resultSet["values"].map((row) => { 
					return row.reduce((memo, cell, j)=> { 
						return Object.assign(memo, { [resultSet["columns"][j]]: cell })
					}, {})
				})
			})
			.flat()
	}
`)

let getColumnDefs: array<{..}> => array<{..}> = %raw(`
	function(data) {
		return data
			.flatMap(col => col["columns"])
			.map(col => { 
				return { "field": col, sortable: true }
			});
	}
`)

@react.component
let make = ()=> {
  let data =
    TNDStatsDB.Context.useQueryDB(
      "select *, strftime('%Y', DATETIME(cast (created_at as INTEGER)/1000, 'unixepoch')) as year from reviews order by created_at desc;",
    )
		let rowData = data->getRowData
		let columnDefs = data->getColumnDefs
		<div className="ag-theme-alpine-dark" style={ReactDOM.Style.make(~height="50vh", ~width="80vw", ())}>
			<AgGrid rowData columnDefs />
		</div>
}