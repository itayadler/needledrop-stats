@react.component
let make = () => {
	React.useEffect0(()=> {
		let loadSQLJS = async () => {
			Js.log("load sql.js")
			let sql = await SQLJS.init(~locateFile=(file) => `https://sql.js.org/dist/${file}`)
			%debugger
			let db = await SQLJS.loadDatabase(sql)
			let res = SQLJS.Database.exec(db, "SELECT * FROM reviews;")
			Js.log(res)
		}
		loadSQLJS()->ignore
		None
	})
	<div>{React.string("testing")}</div>
}
