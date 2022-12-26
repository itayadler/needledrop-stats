type t = option<SQLJS.Database.t>

module Context = {
  include React.Context
  let context = React.createContext(None)
  let makeProps = (~value, ~children, ()) => {value, children}
  let make = React.Context.provider(context)
  let useDB = () => {
    let context = React.useContext(context)
    context
  }
  let useQueryDB = (query) => {
    let db = useDB()
    switch db {
    | Some(db) => SQLJS.Database.exec(db, query)
    | None => []
    }
  }
  let useIsLoading = () => {
    let context = React.useContext(context)
    switch context {
    | None => true
    | Some(_) => false
    }
  }
}

module Provider = {
  @react.component
  let make = (~children) => {
    let (db: t, setDB: (t => t) => unit) = React.useState(_ => None)
    React.useEffect1(() => {
      let loadSQLJS = async () => {
        Js.Console.timeStart("init db")
        let sql = await SQLJS.init(~locateFile=file => `/${file}`)
        Js.Console.timeEnd("init db")
        Js.Console.timeStart("load db")
        let db = await SQLJS.loadDatabase(sql, ~url="/tndstats.db")
        setDB(_ => Some(db))
        Js.Console.timeEnd("load db")
      }
      loadSQLJS()->ignore
      None
    }, [setDB])

    <Context value=db> children </Context>
  }
}
