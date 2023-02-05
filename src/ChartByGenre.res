let mapDataToRecharts: array<{..}> => array<{..}> = %raw(`
	function(data) {
		return data.flatMap((row)=> row["values"]).reduce((memo, row)=> {
			const existingRow = memo.find((r)=> r["name"] == "genre")
			if (existingRow) {
				existingRow["pitchfork_genre" + row[0]] = row[1]
				return memo
			} else {
				memo.push({ name: row[0], value: row[1]})
				return memo
			}
		}, [])
	}
`)

@react.component
let make = () => {
  open Recharts
  let data =
    TNDStatsDB.Context.useQueryDB(
      "select pitchfork_genre, count(pitchfork_genre) as genre_count from reviews group by pitchfork_genre;",
    )->mapDataToRecharts

  <>
	<h2>{"All-time Genre distribution"->React.string}</h2>
  <PieChart width={1000} height={600} >
    <Tooltip />
		<Pie data dataKey="value" fill="#929985" />
  </PieChart>
	</>
}
