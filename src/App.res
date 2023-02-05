@react.component
let make = () => {
  <TNDStatsDB.Provider>
		<ChartByGenre />
		<ReviewsTable />
    <ChartRankByYear />
  </TNDStatsDB.Provider>
}
