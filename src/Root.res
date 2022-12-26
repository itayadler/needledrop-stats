module ReactApp = {
  @react.component
  let make = () => {
		<App />
  }
}

switch ReactDOM.querySelector("#root") {
| Some(element) =>
  let root = ReactDOM.Client.createRoot(element)
  ReactDOM.Client.Root.render(root, <ReactApp />)
| None => ()
}
