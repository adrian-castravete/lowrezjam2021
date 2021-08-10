function love.conf(t)
  t.identity = 'fkbm-lowrezjam2021'
  t.version = '11.1'
  t.accelerometerjoystick = false
  t.externalstorage = true
  t.gammacorrect = true

  local w = t.window
  w.title = "LowRezJam 2021 Entry"
  w.icon = nil
  w.width = 512
  w.height = 512
  w.minwidth = 64
  w.minheight = 64
  w.resizable = true
  w.fullscreentype = 'desktop'
  w.fullscreen = false
  w.usedpiscale = false
  w.hidpi = true
end
