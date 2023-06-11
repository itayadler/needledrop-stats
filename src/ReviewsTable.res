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
						return { "field": col, sortable: true, filter: true }
				}
			});
	}
`)

let rowSelection = #single
type state = {
	year: int,
	genre: option<string>,
}
let empty = {year: 2023, genre: None}
let genres = ["N/A", "Country", "Electronic", "Experimental", "Folk", "Global", "Jazz", "Metal", "Pop", "Rap", "Rock"]
let years = ["2012", "2013", "2014", "2015", "2016","2017","2018","2019","2020","2021","2022","2023"]

module GenreSelect = {
  @react.component
	let make = (~genre, ~setGenre)=> {
		let className = genre->Belt.Option.isNone ? "selected" : ""
		<ul className="genre-select">
		<div className=`genre-select-all ${className}` onClick={(_)=> setGenre(None)}>{"All"->React.string}</div>
		{Js.Array2.map(genres, g => {
			let className = genre->Belt.Option.map((genre)=> g == genre ? "selected" : "")->Belt.Option.getWithDefault("")
			<li key={g} className onClick={(_e)=> setGenre(Some(g))}>{g->React.string}</li>
		})->React.array}
		</ul>
	}
}

module YearSelect = {
  @react.component
	let make = (~year, ~setYear)=> {
		<select className="year-select">
		{Js.Array2.map(years, y => {
			let className = y == year ? "selected" : ""
			<option key={y} className onClick={(_e)=> setYear(y)}>{y->React.string}</option>
		})->React.array}
		</select>
	}
}

@react.component
let make = () => {
	let (state, setState) = React.useState(() => empty)
	let setGenre = React.useCallback1(genre => setState((prev)=> {...prev, genre: genre}), [setState])
	let setYear = React.useCallback1(year => setState((prev)=> {...prev, year: year->int_of_string}), [setState])
	let gridRef = React.useRef(Js.Nullable.null)
	let (selectedRow, setSelectedRow) = React.useState(()=> None)
	let (quickFilterText, setQuickFilterText) = React.useState(()=> "")
	React.useEffect1(() => {
		gridRef.current->Js.Nullable.toOption->Belt.Option.map(gridRef => {
			gridRef->AgGrid.Grid.api->Belt.Option.map((api)=> api->AgGrid.API.setFilterModel({
				"pitchfork genre": {
				"type": "equals",
				"filter": state.genre
			}}))
		})->ignore
		None
	}, [state])
  let data = TNDStatsDB.Context.useQueryDB(
    "select youtube_id, artist_name as artist, album_name as album, rank, pitchfork_rank as 'pitchfork rank', pitchfork_genre as 'pitchfork genre', spotify_followers as 'spotify followers', strftime('%Y', DATETIME(cast (created_at as INTEGER)/1000, 'unixepoch')) as year from reviews;",
  )
	let data = React.useMemo1(()=> data, [Js.Array2.length(data)])
	let onRowSelected = Hooks.useEvent((e: AgGrid.event)=> (
		switch e.event->Js.Nullable.toOption {
			| Some(_e)=> setSelectedRow(_ => 
				e.api->AgGrid.API.getSelectedRows->Belt.Array.get(0)
			)
			| None => ()
		}
	))
	let onGridReady = Hooks.useEvent((e: AgGrid.event)=> {
		Js.log2(e.api, "grid ready")
		e.api->AgGrid.API.setFilterModel({
			"pitchfork genre": {
			"type": "equals",
			"filter": state.genre
		}})
})
  let rowData = React.useMemo1(()=> data->getRowData, [data])
  let columnDefs = React.useMemo1(() => data->getColumnDefs, [data])
	let agGrid = React.useMemo2(() => <AgGrid onGridReady ref={gridRef} rowSelection rowData columnDefs onRowSelected />, (rowData, columnDefs))
	let onQuickFilterChanged = React.useCallback1((formEvent)=> {
		let value = ReactEvent.Form.target(formEvent)["value"]
		setQuickFilterText(_ => value)
		gridRef.current->Js.Nullable.toOption->Belt.Option.map(gridRef => {
			gridRef->AgGrid.Grid.api->Belt.Option.map((api)=> api->AgGrid.API.setQuickFilter(value)
		)})->ignore
	}, [gridRef.current])
  <>
    <h2> {"Reviews table"->React.string} </h2>
	<GenreSelect genre={state.genre} setGenre />
	<YearSelect year={state.year->string_of_int} setYear />
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
