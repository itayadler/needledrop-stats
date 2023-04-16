@react.component
let make = () => {
  <TNDStatsDB.Provider>
		<ReviewsTable />
		<ChartByGenre />
    <ChartRankByYear />
  </TNDStatsDB.Provider>
}
