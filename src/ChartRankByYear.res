let mapDataToRecharts: array<{..}> => array<{..}> = %raw(`
	function(data) {
		return data.flatMap((row)=> row["values"]).reduce((memo, row)=> {
			const existingRow = memo.find((r)=> r["name"] == row[2])
			if (existingRow) {
				existingRow["rank" + row[0]] = row[1]
				return memo
			} else {
				memo.push({ name: row[2], ["rank" + row[0]]: row[1]})
				return memo
			}
		}, [])
	}
`)

@react.component
let make = ()=> {
	open Recharts
	let data = TNDStatsDB.Context
.useQueryDB("select rank, count(rank) as rank_count, strftime('%Y', DATETIME(cast (created_at as INTEGER)/1000, 'unixepoch')) as year from reviews group by year,rank;")
	->mapDataToRecharts

        <BarChart
          width={1000}
          height={600}
          data={data}
        >
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="name" />
          <YAxis />
          <Tooltip />
          <Legend />
          <Bar dataKey="rank1" stackId="a" fill="#757761" />
          <Bar dataKey="rank2" stackId="a" fill="#959365" />
          <Bar dataKey="rank3" stackId="a" fill="#B5AF68" />
          <Bar dataKey="rank4" stackId="a" fill="#D5CB6B" />
          <Bar dataKey="rank5" stackId="a" fill="#F4E76E" />
          <Bar dataKey="rank6" stackId="a" fill="#DCF17E" />
          <Bar dataKey="rank7" stackId="a" fill="#C3FB8D" />
          <Bar dataKey="rank8" stackId="a" fill="#8FF7A7" />
          <Bar dataKey="rank9" stackId="a" fill="#70D9D3" />
          <Bar dataKey="rank10" stackId="a" fill="#51BBFE" />
        </BarChart>
}