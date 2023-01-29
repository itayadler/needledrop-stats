@react.component
let make = () => {
  <TNDStatsDB.Provider>
		<ReviewsTable />
    <ChartRankByYear />
  </TNDStatsDB.Provider>
}
