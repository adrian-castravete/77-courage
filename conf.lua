function love.conf(t)
  t.identity = 'fkge-77-courage'
  t.version = '11.1'
  t.accelerometerjoystick = false
  t.externalstorage = true
  t.gammacorrect = true

  local w = t.window
  w.title = "Courage - MiniJam 77"
  w.icon = nil
  w.width = 512
  w.height = 384
  w.minwidth = 256
  w.minheight = 192
  w.resizable = true
  w.fullscreentype = 'desktop'
  w.fullscreen = false
  w.usedpiscale = false
  w.hidpi = true
end
