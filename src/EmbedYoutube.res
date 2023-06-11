@react.component
let make = (~id)=> {
	<iframe className="tnd-youtube" width="560" height="315" src=`https://www.youtube.com/embed/${id}` title="YouTube video player"></iframe>
}