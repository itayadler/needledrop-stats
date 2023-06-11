let useEvent = callback => {
  let callbackRef = React.useRef(callback)
  React.useLayoutEffect(() => {
    callbackRef.current = callback
    None
  })

  React.useCallback0(arg => {
    callbackRef.current(arg)
  })
}