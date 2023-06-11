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
  year: option<string>,
  genre: option<string>,
}
let empty = {year: None, genre: None}
let genres = [
  "N/A",
  "Country",
  "Electronic",
  "Experimental",
  "Folk",
  "Global",
  "Jazz",
  "Metal",
  "Pop",
  "Rap",
  "Rock",
]
let years = [
  "2012",
  "2013",
  "2014",
  "2015",
  "2016",
  "2017",
  "2018",
  "2019",
  "2020",
  "2021",
  "2022",
  "2023",
]

module GenreSelect = {
  @react.component
  let make = (~genre, ~setGenre) => {
    let className = genre->Belt.Option.isNone ? "selected" : ""
    <div>
      <h3> {"Select a genre"->React.string} </h3>
      <ul className="genre-select">
        <div className={`genre-select-all ${className}`} onClick={_ => setGenre(None)}>
          {"All"->React.string}
        </div>
        {Js.Array2.map(genres, g => {
          let className =
            genre
            ->Belt.Option.map(genre => g == genre ? "selected" : "")
            ->Belt.Option.getWithDefault("")
          <li key={g} className onClick={_e => setGenre(Some(g))}> {g->React.string} </li>
        })->React.array}
      </ul>
    </div>
  }
}

module YearSelect = {
  @react.component
  let make = (~year, ~setYear) => {
    <>
      <h3> {"Select a year"->React.string} </h3>
      <select
        className="year-select"
        onChange={e => {
          let target = e->ReactEvent.Form.target
          let value = target["selectedIndex"]
          let year = years->Belt.Array.get(value - 1)
          setYear(year)
        }}>
        <option key={"all"} onClick={_e => setYear(None)}> {"All"->React.string} </option>
        {Js.Array2.map(years, y => {
          let className =
            year
            ->Belt.Option.map(year => y == year ? "selected" : "")
            ->Belt.Option.getWithDefault("")
          <option key={y} className> {y->React.string} </option>
        })->React.array}
      </select>
    </>
  }
}

@react.component
let make = () => {
  let (state, setState) = React.useState(() => empty)
  let setGenre = React.useCallback1(genre => setState(prev => {...prev, genre}), [setState])
  let setYear = React.useCallback1(year => setState(prev => {...prev, year}), [setState])
  let gridRef = React.useRef(Js.Nullable.null)
  let (selectedRow, setSelectedRow) = React.useState(() => None)
  let (quickFilterText, setQuickFilterText) = React.useState(() => "")
  React.useEffect1(() => {
    gridRef.current
    ->Js.Nullable.toOption
    ->Belt.Option.map(gridRef => {
      gridRef
      ->AgGrid.Grid.api
      ->Belt.Option.map(
        api =>
          api->AgGrid.API.setFilterModel({
            "pitchfork genre": {
              "type": "equals",
              "filter": state.genre,
            },
            "year": {
              "type": "equals",
              "filter": state.year,
            },
          }),
      )
    })
    ->ignore
    None
  }, [state])
  let data = TNDStatsDB.Context.useQueryDB(
    "select youtube_id, artist_name as artist, album_name as album, rank, pitchfork_rank as 'pitchfork rank', pitchfork_genre as 'pitchfork genre', spotify_followers as 'spotify followers', strftime('%Y', DATETIME(cast (created_at as INTEGER)/1000, 'unixepoch')) as year from reviews order by rank desc;",
  )
  let data = React.useMemo1(() => data, [Js.Array2.length(data)])
  let onRowSelected = Hooks.useEvent((e: AgGrid.event) =>
    switch e.event->Js.Nullable.toOption {
    | Some(_e) => setSelectedRow(_ => e.api->AgGrid.API.getSelectedRows->Belt.Array.get(0))
    | None => ()
    }
  )
  let onGridReady = Hooks.useEvent((e: AgGrid.event) => {
    e.api->AgGrid.API.setFilterModel({
      "pitchfork genre": {
        "type": "equals",
        "filter": state.genre,
      },
      "year": {
        "type": "equals",
        "filter": state.year,
      },
    })
  })
  let rowData = React.useMemo1(() => data->getRowData, [data])
  let columnDefs = React.useMemo1(() => data->getColumnDefs, [data])
  let agGrid = React.useMemo2(
    () => <AgGrid onGridReady ref={gridRef} rowSelection rowData columnDefs onRowSelected />,
    (rowData, columnDefs),
  )
  let onQuickFilterChanged = React.useCallback1(formEvent => {
    let value = ReactEvent.Form.target(formEvent)["value"]
    setQuickFilterText(_ => value)
    gridRef.current
    ->Js.Nullable.toOption
    ->Belt.Option.map(gridRef => {
      gridRef->AgGrid.Grid.api->Belt.Option.map(api => api->AgGrid.API.setQuickFilter(value))
    })
    ->ignore
  }, [gridRef.current])
  <>
    <GenreSelect genre={state.genre} setGenre />
    <YearSelect year={state.year} setYear />
		{switch selectedRow {
			| Some(selectedRow)=> 
				<EmbedYoutube id={selectedRow["youtube_id"]} />
			| None => React.null
		}}
    // <p> {`Selected row rank ${selectedRow->Belt.Option.map(row => row["rank"])->Belt.Option.getWithDefault("n/a")}`->React.string} </p>
    <div
      className="ag-theme-alpine-dark table"
      style={ReactDOM.Style.make(~height="50vh", ~width="80vw", ())}>
      <div className="quick-filter">
        <input
          type_="input"
          onInput={onQuickFilterChanged}
          id="quickFilter"
          value={quickFilterText}
          placeholder="Search...           by artist, album..."
        />
      </div>
      agGrid
    </div>
  </>
}
