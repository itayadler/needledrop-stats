module ReactApp = {
  @react.component
  let make = () => {
		<App />
  }
}

switch ReactDOM.querySelector("#root") {
| Some(element) =>
  let root = ReactDOM.Experimental.createRoot(element)
  ReactDOM.Experimental.render(root, <ReactApp />)
| None => ()
}
