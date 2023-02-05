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
				switch (col) {
					case 'youtube_id':
						return { "field": col, hide: true }
						break;
					default:
						return { "field": col, sortable: true }
				}
			});
	}
`)

let rowSelection = #single

@react.component
let make = () => {
	let gridRef = React.useRef(Js.Nullable.null)
	let (selectedRow, setSelectedRow) = React.useState(()=> None)
	let (quickFilterText, setQuickFilterText) = React.useState(()=> "")
  let data = TNDStatsDB.Context.useQueryDB(
    "select youtube_id, artist_name as artist, album_name as album, rank, pitchfork_rank as 'pitchfork rank', pitchfork_genre as 'pitchfork genre', spotify_followers as 'spotify followers', strftime('%Y', DATETIME(cast (created_at as INTEGER)/1000, 'unixepoch')) as year from reviews;",
  )
	let data = React.useMemo1(()=> data, [Js.Array2.length(data)])
	let onRowSelected = (e: AgGrid.event)=> (
		switch e.event->Js.Nullable.toOption {
			| Some(_e)=> setSelectedRow(_ => 
				e.api->AgGrid.API.getSelectedRows->Belt.Array.get(0)
			)
			| None => ()
		}
	)
  let rowData = React.useMemo1(()=> data->getRowData, [data])
  let columnDefs = React.useMemo1(() => data->getColumnDefs, [data])
	let agGrid = React.useMemo2(() => <AgGrid ref={gridRef} rowSelection rowData columnDefs onRowSelected />, (rowData, columnDefs))
	let onQuickFilterChanged = React.useCallback1((formEvent)=> {
		let value = ReactEvent.Form.target(formEvent)["value"]
		setQuickFilterText(_ => value)
		gridRef.current->Js.Nullable.toOption->Belt.Option.map(gridRef => {
			gridRef->AgGrid.Grid.api->AgGrid.API.setQuickFilter(value)
		})->ignore
	}, [gridRef.current])
  <>
    <h2> {"Reviews table"->React.string} </h2>
		<p> {`Selected row rank ${selectedRow->Belt.Option.map(row => row["rank"])->Belt.Option.getWithDefault("n/a")}`->React.string} </p>
				<div>
          <input
						type_="input"
            onInput={onQuickFilterChanged}
            id="quickFilter"
						value={quickFilterText}
            placeholder="quick filter..."
          />
        </div>
    <div
      className="ag-theme-alpine-dark"
      style={ReactDOM.Style.make(~height="50vh", ~width="80vw", ())}>
			agGrid
    </div>
  </>
}
