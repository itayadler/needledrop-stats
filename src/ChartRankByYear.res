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
let make = () => {
  open Recharts
  let data =
    TNDStatsDB.Context.useQueryDB(
      "select rank, count(rank) as rank_count, strftime('%Y', DATETIME(cast (created_at as INTEGER)/1000, 'unixepoch')) as year from reviews group by year,rank;",
    )->mapDataToRecharts

  <>
	<h2>{"Ranking distribution"->React.string}</h2>
  <AreaChart width={1000} height={600} data={data} >
    <CartesianGrid strokeDasharray="3 3" />
    <XAxis dataKey="name" />
    <YAxis />
    <Tooltip />
    <Area _type=#monotone dataKey="rank1" stackId="a" fill="#2F2504" />
    <Area _type=#monotone dataKey="rank2" stackId="a" fill="#443A1D" />
    <Area _type=#monotone dataKey="rank3" stackId="a" fill="#4F442A" />
    <Area _type=#monotone dataKey="rank4" stackId="a" fill="#594E36" />
    <Area _type=#monotone dataKey="rank5" stackId="a" fill="#6C6951" />
    <Area _type=#monotone dataKey="rank6" stackId="a" fill="#7E846B" />
    <Area _type=#monotone dataKey="rank7" stackId="a" fill="#929985" />
    <Area _type=#monotone dataKey="rank8" stackId="a" fill="#A5AE9E" />
    <Area _type=#monotone dataKey="rank9" stackId="a" fill="#BBC6BB" />
    <Area _type=#monotone dataKey="rank10" stackId="a" fill="#D0DDD7" />
  </AreaChart>
	</>
}
