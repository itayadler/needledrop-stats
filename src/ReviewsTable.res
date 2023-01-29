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

@react.component
let make = ()=> {
  let data =
    TNDStatsDB.Context.useQueryDB(
      "select youtube_id, artist_name as artist, album_name as album, rank, pitchfork_rank as 'pitchfork rank', pitchfork_genre as 'pitchfork genre', spotify_followers as 'spotify followers', strftime('%Y', DATETIME(cast (created_at as INTEGER)/1000, 'unixepoch')) as year from reviews;",
    )
		let rowData = data->getRowData
		let columnDefs = data->getColumnDefs
		<>
		<h2>{"Reviews table"->React.string}</h2>
		<div className="ag-theme-alpine-dark" style={ReactDOM.Style.make(~height="50vh", ~width="80vw", ())}>
			<AgGrid rowData columnDefs />
		</div>
		</>
}